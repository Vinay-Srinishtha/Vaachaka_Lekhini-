import type { RequestHandler } from './$types';
import { error } from '@sveltejs/kit';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { readJsonBody } from '$lib/server/json-input';
import { requireAccount } from '$lib/server/user-auth';
import { assertOwnsMembers, programUpsertSchema } from '$lib/server/sync';
import { emitChange } from '$lib/server/live';

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

	// Fetch current DB state for all programs — totals and existing completedAt.
	// Totals are server-authoritative (recomputed by /api/v1/sessions).
	// We also preserve the existing completedAt so once set it is never cleared or
	// backdated by a client re-submitting an old timestamp.
	const existingPrograms = await prisma.program.findMany({
		where: { id: { in: body.programs.map((p) => p.id) } },
		select: { id: true, totalWritings: true, totalChants: true, completedAt: true }
	});
	const existingMap = new Map(existingPrograms.map((p) => [p.id, p]));

	const results = await prisma.$transaction(
		body.programs.map((p) => {
			const mantraDbId = mantraMap.get(p.mantra_id)!;
			// Use server-authoritative totals (recomputed by /api/v1/sessions).
			// Fall back to client values only for brand-new programs not yet in DB.
			const existing = existingMap.get(p.id);
			const totalWritings = existing?.totalWritings ?? (p.total_writings ?? 0);
			const totalChants = existing?.totalChants ?? (p.total_chants ?? 0);
			const totalProgress = totalWritings + totalChants;
			// completedAt: the server is the sole authority on when a program was
			// completed. Rules:
			//   1. Already completed in DB → preserve the original timestamp (never overwrite).
			//   2. Not yet complete but totalProgress now meets target → stamp now().
			//   3. Target not reached → null (in-progress).
			// The client-supplied completed_at timestamp is intentionally ignored.
			const serverAllowsCompletion = totalProgress >= p.target_writings;
			const completedAt = existing?.completedAt
				? existing.completedAt                          // (1) already set — keep original
				: serverAllowsCompletion
					? new Date()                                // (2) newly completed — server stamps
					: null;                                     // (3) still in progress
			const baseData = {
				memberId: p.member_id,
				mantraId: mantraDbId,
				targetWritings: p.target_writings,
				targetDays: p.target_days,
				startedAt: p.started_at ? new Date(p.started_at) : undefined,
				completedAt,
				totalWritings,
				totalChants,
				lastActiveDate: p.last_active_date ? new Date(p.last_active_date) : null
			};
			return prisma.program.upsert({
				where: { id: p.id },
				create: { id: p.id, ...baseData, startedAt: baseData.startedAt ?? new Date() },
				update: {
					targetWritings: baseData.targetWritings,
					targetDays: baseData.targetDays,
					// totalWritings / totalChants intentionally omitted — server recomputes
					// these from the Session table in /api/v1/sessions (authoritative).
					completedAt: baseData.completedAt,
					lastActiveDate: baseData.lastActiveDate
				}
			});
		})
	);

	emitChange('program');
	return snakeJson({ programs: results });
};
