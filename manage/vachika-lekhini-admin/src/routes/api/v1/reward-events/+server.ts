import type { RequestHandler } from './$types';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { readJsonBody } from '$lib/server/json-input';
import { requireAccount } from '$lib/server/user-auth';
import {
	assertOwnsMembers,
	recomputeMemberBalance,
	rewardEventCreateSchema
} from '$lib/server/sync';

const bodySchema = z.object({
	events: z.array(rewardEventCreateSchema).min(1).max(100)
});

/// POST /api/v1/reward-events  (Bearer) — batch create ledger entries.
/// After insert, recomputes affected members' balances (denorm cache).
/// Idempotent on client-supplied UUID.
export const POST: RequestHandler = async (event) => {
	const account = await requireAccount(event);
	const body = await readJsonBody(event, bodySchema);

	await assertOwnsMembers(account.id, body.events.map((e) => e.member_id));

	const inserted = await prisma.rewardEvent.createMany({
		data: body.events.map((e) => ({
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

	// Recompute balance for each touched member.
	const memberIds = Array.from(new Set(body.events.map((e) => e.member_id)));
	const balances: Record<string, number> = {};
	for (const id of memberIds) {
		balances[id] = await recomputeMemberBalance(id);
	}

	return snakeJson({ created: inserted.count, requested: body.events.length, balances });
};
