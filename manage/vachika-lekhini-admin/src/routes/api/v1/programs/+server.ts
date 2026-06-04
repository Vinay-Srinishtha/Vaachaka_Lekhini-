import type { RequestHandler } from './$types';
import { error } from '@sveltejs/kit';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { readJsonBody } from '$lib/server/json-input';
import { requireAccount } from '$lib/server/user-auth';
import { assertOwnsMembers, programUpsertSchema } from '$lib/server/sync';

const bodySchema = z.object({
	programs: z.array(programUpsertSchema).min(1).max(50)
});

/// Resolve a mantra reference that may be either an `id` (cuid) or `slug`.
async function resolveMantraId(idOrSlug: string): Promise<string> {
	const byId = await prisma.mantra.findUnique({ where: { id: idOrSlug }, select: { id: true } });
	if (byId) return byId.id;
	const bySlug = await prisma.mantra.findUnique({ where: { slug: idOrSlug }, select: { id: true } });
	if (bySlug) return bySlug.id;
	throw error(400, `Unknown mantra: ${idOrSlug}`);
}

/// POST /api/v1/programs  (Bearer) — batch upsert practice programs.
/// `mantra_id` may be a slug ("sri_rama") or the DB cuid — either resolves.
export const POST: RequestHandler = async (event) => {
	const account = await requireAccount(event);
	const body = await readJsonBody(event, bodySchema);

	await assertOwnsMembers(account.id, body.programs.map((p) => p.member_id));

	// Resolve mantra ids upfront so transaction stays simple.
	const mantraMap = new Map<string, string>();
	for (const p of body.programs) {
		if (!mantraMap.has(p.mantra_id)) {
			mantraMap.set(p.mantra_id, await resolveMantraId(p.mantra_id));
		}
	}

	const results = await prisma.$transaction(
		body.programs.map((p) => {
			const mantraDbId = mantraMap.get(p.mantra_id)!;
			const baseData = {
				memberId: p.member_id,
				mantraId: mantraDbId,
				targetWritings: p.target_writings,
				targetDays: p.target_days,
				startedAt: p.started_at ? new Date(p.started_at) : undefined,
				completedAt: p.completed_at ? new Date(p.completed_at) : null,
				totalWritings: p.total_writings ?? 0,
				currentStreak: p.current_streak ?? 0,
				longestStreak: p.longest_streak ?? 0,
				lastActiveDate: p.last_active_date ? new Date(p.last_active_date) : null
			};
			return prisma.program.upsert({
				where: { id: p.id },
				create: { id: p.id, ...baseData, startedAt: baseData.startedAt ?? new Date() },
				update: {
					targetWritings: baseData.targetWritings,
					targetDays: baseData.targetDays,
					completedAt: baseData.completedAt,
					totalWritings: baseData.totalWritings,
					currentStreak: baseData.currentStreak,
					longestStreak: baseData.longestStreak,
					lastActiveDate: baseData.lastActiveDate
				}
			});
		})
	);

	return snakeJson({ programs: results });
};
