import type { RequestHandler } from './$types';
import { z } from 'zod';
import { error } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { readJsonBody } from '$lib/server/json-input';
import { requireAccount } from '$lib/server/user-auth';
import {
	assertOwnsMembers,
	recomputeMemberBalance,
	rewardEventCreateSchema
} from '$lib/server/sync';
import { emitChange } from '$lib/server/live';

/// Kinds that a client is permitted to submit.
/// `earn` and `milestone` are computed exclusively server-side (triggered by
/// /api/v1/sessions ingestion) — accepting them from a client would allow a
/// tampered app to credit arbitrary point amounts.
const CLIENT_ALLOWED_KINDS = new Set(['spend', 'gift', 'refund']);

/// Per-kind amount ceiling for client-submitted events (anti-tamper guard).
const CLIENT_AMOUNT_CAPS: Record<string, number> = {
	spend: 10_000,
	gift: 500,
	refund: 10_000
};

const bodySchema = z.object({
	events: z.array(rewardEventCreateSchema).min(1).max(100)
});

/// POST /api/v1/reward-events  (Bearer) — batch create ledger entries.
/// Only `spend`, `gift`, and `refund` events are accepted from clients.
/// `earn` and `milestone` are generated exclusively by /api/v1/sessions.
/// For spend events the handler verifies server-side balance is sufficient
/// before writing. The check and insert run inside a serialisable transaction
/// to prevent concurrent spends from racing past a single shared balance.
export const POST: RequestHandler = async (event) => {
	const account = await requireAccount(event);
	const body = await readJsonBody(event, bodySchema);

	// Reject any event whose kind must only be emitted server-side.
	for (const e of body.events) {
		if (!CLIENT_ALLOWED_KINDS.has(e.kind)) {
			throw error(403, `Event kind '${e.kind}' cannot be submitted by a client`);
		}
		const cap = CLIENT_AMOUNT_CAPS[e.kind];
		if (cap !== undefined && e.amount > cap) {
			throw error(400, `Event amount ${e.amount} exceeds cap of ${cap} for kind '${e.kind}'`);
		}
	}

	await assertOwnsMembers(account.id, body.events.map((e) => e.member_id));

	// Separate spend events from non-spend events so we can apply the balance
	// guard only where it is needed.
	const spendEvents = body.events.filter((e) => e.kind === 'spend');
	const otherEvents = body.events.filter((e) => e.kind !== 'spend');

	// Insert non-spend events without any balance check (they never reduce balance).
	let insertedCount = 0;

	if (otherEvents.length > 0) {
		const result = await prisma.rewardEvent.createMany({
			data: otherEvents.map((e) => ({
				id: e.id,
				memberId: e.member_id,
				kind: e.kind,
				amount: e.amount,
				source: e.source,
				storeItemId: e.store_item_id ?? null,
				occurredAt: e.occurred_at ? new Date(e.occurred_at) : undefined
			})),
			skipDuplicates: true
		});
		insertedCount += result.count;
	}

	// For spend events: verify balance per member inside a serialisable
	// transaction so concurrent requests cannot both pass the same check.
	// We process one spend event at a time (each in its own transaction) so
	// that a failed event does not roll back unrelated ones in the batch.
	for (const e of spendEvents) {
		await prisma.$transaction(
			async (tx) => {
				// Re-aggregate the live ledger inside the transaction so Postgres
				// takes a row-level lock that blocks concurrent writers for this member.
				const agg = await tx.rewardEvent.groupBy({
					by: ['kind'],
					where: { memberId: e.member_id },
					_sum: { amount: true }
				});
				let currentBalance = 0;
				for (const row of agg) {
					const sum = row._sum.amount ?? 0;
					currentBalance += row.kind === 'spend' ? -sum : sum;
				}

				if (currentBalance < e.amount) {
					throw error(
						422,
						`Insufficient balance for member ${e.member_id}: has ${currentBalance}, needs ${e.amount}`
					);
				}

				await tx.rewardEvent.upsert({
					where: { id: e.id },
					create: {
						id: e.id,
						memberId: e.member_id,
						kind: e.kind,
						amount: e.amount,
						source: e.source,
						storeItemId: e.store_item_id ?? null,
						occurredAt: e.occurred_at ? new Date(e.occurred_at) : undefined
					},
					update: {} // idempotent — duplicate id is a no-op
				});

				insertedCount += 1;
			},
			{ isolationLevel: 'Serializable' }
		);
	}

	// Recompute balance for each touched member.
	const memberIds = Array.from(new Set(body.events.map((e) => e.member_id)));
	const balances: Record<string, number> = {};
	for (const id of memberIds) {
		balances[id] = await recomputeMemberBalance(id);
	}

	if (insertedCount > 0) emitChange('reward_event');
	return snakeJson({ created: insertedCount, requested: body.events.length, balances });
};
