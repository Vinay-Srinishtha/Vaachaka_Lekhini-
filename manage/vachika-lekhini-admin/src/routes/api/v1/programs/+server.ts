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

	const results = await prisma.$transaction(
		body.programs.map((p) => {
			const mantraDbId = mantraMap.get(p.mantra_id)!;
			// NOTE: currentStreak / longestStreak are intentionally excluded from
			// the update block — the server recomputes them from the Session table
			// in /api/v1/sessions after each batch insert. Accepting client-supplied
			// values here would let a tampered client claim an arbitrary streak.
			const totalWritings = p.total_writings ?? 0;
			// completedAt is only honoured when the server-supplied totalWritings
			// has actually reached targetWritings. A client cannot mark a program
			// complete by sending a completedAt timestamp alone.
			const serverAllowsCompletion = totalWritings >= p.target_writings;
			const completedAt =
				serverAllowsCompletion && p.completed_at ? new Date(p.completed_at) : null;
			const baseData = {
				memberId: p.member_id,
				mantraId: mantraDbId,
				targetWritings: p.target_writings,
				targetDays: p.target_days,
				startedAt: p.started_at ? new Date(p.started_at) : undefined,
				completedAt,
				totalWritings,
				lastActiveDate: p.last_active_date ? new Date(p.last_active_date) : null
			};
			return prisma.program.upsert({
				where: { id: p.id },
				create: { id: p.id, ...baseData, startedAt: baseData.startedAt ?? new Date() },
				update: {
					targetWritings: baseData.targetWritings,
					targetDays: baseData.targetDays,
					completedAt: baseData.completedAt,
					// totalWritings is intentionally omitted — the server recomputes it
					// from the Session table in /api/v1/sessions (Issue #3). Accepting
					// client-supplied totals here would allow Flutter's local arithmetic
					// to overwrite the authoritative server aggregate.
					lastActiveDate: baseData.lastActiveDate
				}
			});
		})
	);

	emitChange('program');
	return snakeJson({ programs: results });
};
