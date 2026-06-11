import type { RequestHandler } from './$types';
import { error } from '@sveltejs/kit';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { readJsonBody } from '$lib/server/json-input';
import { requireAccount } from '$lib/server/user-auth';
import { memberUpsertSchema } from '$lib/server/sync';
import { emitChange } from '$lib/server/live';

const bodySchema = z.object({
	members: z.array(memberUpsertSchema).min(1).max(8)
});

const DEFAULT_MAX_PROFILES = 4;

/// POST /api/v1/members  (Bearer) — batch upsert.
/// Caller supplies UUIDs. New members are created; existing ones are
/// updated. Ownership is enforced — you can never write to a member that
/// doesn't belong to your account.
/// Server enforces max_profiles_per_user from FeatureFlag (default 4).
export const POST: RequestHandler = async (event) => {
	const account = await requireAccount(event);
	const body = await readJsonBody(event, bodySchema);

	// Reject any update that targets a member belonging to a different account.
	const ids = body.members.map((m) => m.id);
	const existing = await prisma.member.findMany({
		where: { id: { in: ids } },
		select: { id: true, accountId: true }
	});
	for (const e of existing) {
		if (e.accountId !== account.id) {
			throw error(403, `Member ${e.id} belongs to a different account`);
		}
	}

	// Enforce max_profiles_per_user. New members = ids not already in DB.
	const existingIds = new Set(existing.map((e) => e.id));
	const newMemberCount = ids.filter((id) => !existingIds.has(id)).length;
	if (newMemberCount > 0) {
		const [currentCount, flag] = await Promise.all([
			prisma.member.count({ where: { accountId: account.id } }),
			prisma.featureFlag.findUnique({ where: { key: 'max_profiles_per_user' } })
		]);
		const limit =
			flag && typeof (flag.value as unknown) === 'number'
				? (flag.value as number)
				: DEFAULT_MAX_PROFILES;
		if (currentCount + newMemberCount > limit) {
			throw error(422, `Member limit reached (max ${limit} per account)`);
		}
	}

	const results = await prisma.$transaction(
		body.members.map((m) =>
			prisma.member.upsert({
				where: { id: m.id },
				create: {
					id: m.id,
					accountId: account.id,
					displayName: m.display_name,
					relation: m.relation,
					avatarKey: m.avatar_key ?? null,
					language: m.language,
					birthYear: m.birth_year ?? null,
					preferences: (m.preferences ?? {}) as any,
					isPrimary: m.is_primary ?? false
				},
				update: {
					displayName: m.display_name,
					relation: m.relation,
					avatarKey: m.avatar_key ?? null,
					language: m.language,
					birthYear: m.birth_year ?? null,
					preferences: (m.preferences ?? {}) as any,
					...(m.is_primary !== undefined ? { isPrimary: m.is_primary } : {})
				},
				select: {
					id: true,
					displayName: true,
					relation: true,
					avatarKey: true,
					language: true,
					birthYear: true,
					preferences: true,
					isPrimary: true,
					rewardPointsBalance: true,
					createdAt: true,
					updatedAt: true
				}
			})
		)
	);

	emitChange('member');
	return snakeJson({ members: results });
};

/// DELETE /api/v1/members/:id is handled by [id]/+server.ts.
