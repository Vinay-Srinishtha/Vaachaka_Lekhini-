import type { RequestHandler } from './$types';
import { z } from 'zod';
import { error, json } from '@sveltejs/kit';
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

/// Only `spend` events may come from the Flutter client.
/// `earn` and `milestone` are server-side only (computed from /api/v1/sessions).
/// `gift` and `refund` are admin-only actions that must come from the admin panel,
/// not from a client that could tamper with amounts.
const CLIENT_ALLOWED_KINDS = new Set(['spend']);

/// Per-kind amount ceiling for client-submitted events (anti-tamper guard).
const CLIENT_AMOUNT_CAPS: Record<string, number> = {
	spend: 10_000,
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
	try {
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

		// Only spend events reach here (CLIENT_ALLOWED_KINDS = { 'spend' }).
		// Each runs in its own serialisable transaction so a failed spend does not
		// roll back unrelated ones in the batch.
		const spendEvents = body.events;
		let insertedCount = 0;

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

		// Recompute balance for each touched member in parallel.
		const memberIds = Array.from(new Set(body.events.map((e) => e.member_id)));
		const balanceEntries = await Promise.all(
			memberIds.map(async (id) => [id, await recomputeMemberBalance(id)] as const)
		);
		const balances = Object.fromEntries(balanceEntries);

		if (insertedCount > 0) emitChange('reward_event');
		return snakeJson({ created: insertedCount, requested: body.events.length, balances });
	} catch (e) {
		console.error(e);
		return json({ error: 'Internal error' }, { status: 500 });
	}
};
