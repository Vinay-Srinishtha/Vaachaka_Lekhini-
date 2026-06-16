import type { RequestHandler } from './$types';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { readJsonBody } from '$lib/server/json-input';
import { requireAccount } from '$lib/server/user-auth';
import { assertOwnsMembers, assertOwnsPrograms, sessionCreateSchema, recomputeProgramStreaks } from '$lib/server/sync';
import { emitChange } from '$lib/server/live';
import { applySessionRewards, applyStreakRewards } from '$lib/server/reward-rules';

const bodySchema = z.object({
	sessions: z.array(sessionCreateSchema).min(1).max(100)
});

/// POST /api/v1/sessions  (Bearer) — batch create. Sessions are append-only;
/// re-posting the same id is a no-op (idempotent thanks to client-supplied UUID).
export const POST: RequestHandler = async (event) => {
	const account = await requireAccount(event);
	const body = await readJsonBody(event, bodySchema);

	await assertOwnsMembers(account.id, body.sessions.map((s) => s.member_id));
	await assertOwnsPrograms(account.id, body.sessions.map((s) => s.program_id));

	const inserted = await prisma.session.createMany({
		data: body.sessions.map((s) => ({
			id: s.id,
			memberId: s.member_id,
			programId: s.program_id,
			startedAt: new Date(s.started_at),
			endedAt: s.ended_at ? new Date(s.ended_at) : null,
			durationSec: s.duration_sec,
			countAdded: s.count_added,
			modality: s.modality,
			voiceMatchScore: s.voice_match_score ?? null
		})),
		skipDuplicates: true
	});

	if (inserted.count > 0) emitChange('session');

	// ── Streak recomputation + streak rewards ──────────────────────────────
	if (inserted.count > 0) {
		const uniqueProgramIds = Array.from(new Set(body.sessions.map((s) => s.program_id)));
		await Promise.all(uniqueProgramIds.map((id) => recomputeProgramStreaks(id)));
		emitChange('program');

		// Award streak_week bonus for any program that hit a new week milestone.
		const streakPrograms = await prisma.program.findMany({
			where: { id: { in: uniqueProgramIds } },
			select: { memberId: true, currentStreak: true }
		});
		await Promise.all(
			streakPrograms.map((p) => applyStreakRewards(p.memberId, p.currentStreak))
		);
	}

	// ── Total chants/writings recomputation ─────────────────────────────────
	if (inserted.count > 0) {
		const programIds = Array.from(new Set(body.sessions.map((s) => s.program_id)));
		await Promise.all(
			programIds.map(async (programId) => {
				const [writingAgg, chantAgg, program] = await Promise.all([
					prisma.session.aggregate({
						where: { programId, modality: 'handwriting' },
						_sum: { countAdded: true }
					}),
					prisma.session.aggregate({
						where: { programId, modality: { not: 'handwriting' } },
						_sum: { countAdded: true }
					}),
					prisma.program.findUnique({
						where: { id: programId },
						select: { targetWritings: true, completedAt: true }
					})
				]);
				const totalWritings = writingAgg._sum.countAdded ?? 0;
				const totalChants = chantAgg._sum.countAdded ?? 0;
				const totalProgress = totalWritings + totalChants;
				const target = program?.targetWritings ?? 0;
				const completedAt =
					program?.completedAt ??
					(totalProgress >= target && target > 0 ? new Date() : null);
				return prisma.program.update({
					where: { id: programId },
					data: { totalWritings, totalChants, completedAt }
				});
			})
		);
	}

	// ── Chant milestone rewards ─────────────────────────────────────────────
	if (inserted.count > 0) {
		await applySessionRewards(
			body.sessions.map((s) => ({
				id: s.id,
				memberId: s.member_id,
				countAdded: s.count_added
			}))
		);
	}

	return snakeJson({ created: inserted.count, requested: body.sessions.length });
};
