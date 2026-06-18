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

	// ── Determine which session IDs already exist to identify truly new ones ──
	// createMany with skipDuplicates does not return inserted IDs, so we check
	// before insertion to avoid re-awarding chant milestone points on retries.
	const requestedIds = body.sessions.map((s) => s.id);
	const existingRows = await prisma.session.findMany({
		where: { id: { in: requestedIds } },
		select: { id: true }
	});
	const existingIdSet = new Set(existingRows.map((r) => r.id));
	const newSessions = body.sessions.filter((s) => !existingIdSet.has(s.id));

	// ── Insert + recompute totals inside a single transaction ─────────────────
	// Keeping createMany and program.update (totals) in the same transaction
	// ensures the DB is never left with sessions inserted but stale totals if the
	// update throws. Streak recompute runs after commit because
	// recomputeProgramStreaks uses the module-level prisma client; streak writes
	// are idempotent so a failure there doesn't corrupt session/total data.
	const uniqueProgramIds = Array.from(new Set(body.sessions.map((s) => s.program_id)));

	const inserted = await prisma.$transaction(async (tx) => {
		const result = await tx.session.createMany({
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

		if (result.count > 0) {
			// ── Total chants/writings recomputation ─────────────────────────────
			await Promise.all(
				uniqueProgramIds.map(async (programId) => {
					const [writingAgg, chantAgg, program] = await Promise.all([
						tx.session.aggregate({
							where: { programId, modality: 'handwriting' },
							_sum: { countAdded: true }
						}),
						tx.session.aggregate({
							where: { programId, modality: { not: 'handwriting' } },
							_sum: { countAdded: true }
						}),
						tx.program.findUnique({
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
					// Derive lastActiveDate from the most recent session for this program.
					const latestSession = await tx.session.findFirst({
						where: { programId },
						orderBy: { startedAt: 'desc' },
						select: { startedAt: true }
					});
					const lastActiveDate = latestSession?.startedAt ?? null;
					return tx.program.update({
						where: { id: programId },
						data: { totalWritings, totalChants, completedAt, lastActiveDate }
					});
				})
			);
		}

		return result;
	});

	if (inserted.count > 0) emitChange('session');

	// ── Streak recomputation + streak rewards ──────────────────────────────
	if (inserted.count > 0) {
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

	// ── Chant milestone rewards — only for truly new sessions ───────────────
	// Pass only sessions that were not in the DB before this request, so
	// re-submitted (duplicate) sessions don't trigger milestone points again.
	if (newSessions.length > 0) {
		await applySessionRewards(
			newSessions.map((s) => ({
				id: s.id,
				memberId: s.member_id,
				countAdded: s.count_added
			}))
		);
	}

	return snakeJson({ created: inserted.count, requested: body.sessions.length });
};
