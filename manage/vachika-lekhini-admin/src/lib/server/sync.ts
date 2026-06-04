import { z } from 'zod';
import { error } from '@sveltejs/kit';
import { prisma } from './prisma';

/// Verify a list of [memberIds] all belong to [accountId]. Throws 403 otherwise.
/// One round-trip — cheaper than per-item checks.
export async function assertOwnsMembers(accountId: string, memberIds: string[]): Promise<void> {
	if (memberIds.length === 0) return;
	const unique = Array.from(new Set(memberIds));
	const owned = await prisma.member.findMany({
		where: { id: { in: unique }, accountId },
		select: { id: true }
	});
	if (owned.length !== unique.length) {
		throw error(403, 'Member not owned by this account');
	}
}

export async function assertOwnsPrograms(accountId: string, programIds: string[]): Promise<void> {
	if (programIds.length === 0) return;
	const unique = Array.from(new Set(programIds));
	const owned = await prisma.program.findMany({
		where: { id: { in: unique }, member: { accountId } },
		select: { id: true }
	});
	if (owned.length !== unique.length) {
		throw error(403, 'Program not owned by this account');
	}
}

/// Recompute a Member's `rewardPointsBalance` from its full ledger.
/// `earn`/`milestone`/`gift`/`refund` contribute positively; `spend` deducts.
export async function recomputeMemberBalance(memberId: string): Promise<number> {
	const agg = await prisma.rewardEvent.groupBy({
		by: ['kind'],
		where: { memberId },
		_sum: { amount: true }
	});
	let total = 0;
	for (const row of agg) {
		const sum = row._sum.amount ?? 0;
		total += row.kind === 'spend' ? -sum : sum;
	}
	await prisma.member.update({ where: { id: memberId }, data: { rewardPointsBalance: total } });
	return total;
}

export const FAMILY_RELATIONS = ['self', 'spouse', 'parent', 'child', 'sibling', 'friend', 'other'] as const;
export const SESSION_MODALITIES = ['voice', 'handwriting', 'manual'] as const;
export const REWARD_KINDS = ['earn', 'spend', 'milestone', 'gift', 'refund'] as const;
export const DEVICE_PLATFORMS = ['android', 'ios', 'web'] as const;

export const memberUpsertSchema = z.object({
	id: z.string().min(1),
	display_name: z.string().min(1).max(80),
	relation: z.enum(FAMILY_RELATIONS).default('other'),
	avatar_key: z.string().max(40).nullable().optional(),
	language: z.string().max(8).default('en'),
	birth_year: z.number().int().nullable().optional(),
	preferences: z.record(z.string(), z.unknown()).optional(),
	is_primary: z.boolean().optional()
});

export const programUpsertSchema = z.object({
	id: z.string().min(1),
	member_id: z.string().min(1),
	mantra_id: z.string().min(1), // server resolves either id or slug
	target_writings: z.number().int().positive(),
	target_days: z.number().int().positive(),
	started_at: z.string().datetime().optional(),
	completed_at: z.string().datetime().nullable().optional(),
	total_writings: z.number().int().min(0).optional(),
	current_streak: z.number().int().min(0).optional(),
	longest_streak: z.number().int().min(0).optional(),
	last_active_date: z.string().datetime().nullable().optional()
});

export const sessionCreateSchema = z.object({
	id: z.string().min(1),
	member_id: z.string().min(1),
	program_id: z.string().min(1),
	started_at: z.string().datetime(),
	ended_at: z.string().datetime().nullable().optional(),
	duration_sec: z.number().int().min(0),
	count_added: z.number().int().min(0),
	modality: z.enum(SESSION_MODALITIES),
	voice_match_score: z.number().nullable().optional()
});

export const rewardEventCreateSchema = z.object({
	id: z.string().min(1),
	member_id: z.string().min(1),
	kind: z.enum(REWARD_KINDS),
	amount: z.number().int().min(0),
	source: z.string().min(1).max(200),
	store_item_id: z.string().nullable().optional(),
	occurred_at: z.string().datetime().optional()
});

export const deviceUpsertSchema = z.object({
	id: z.string().min(1),
	platform: z.enum(DEVICE_PLATFORMS),
	app_version: z.string().max(40).nullable().optional(),
	push_token: z.string().max(500).nullable().optional(),
	last_member_id: z.string().nullable().optional()
});
