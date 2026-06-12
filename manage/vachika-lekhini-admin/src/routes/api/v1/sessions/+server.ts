import type { RequestHandler } from './$types';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { readJsonBody } from '$lib/server/json-input';
import { requireAccount } from '$lib/server/user-auth';
import { assertOwnsMembers, assertOwnsPrograms, sessionCreateSchema, recomputeMemberBalance, recomputeProgramStreaks } from '$lib/server/sync';
import { emitChange } from '$lib/server/live';
import { getRewardRate } from '$lib/server/reward-config';

/// Mirrors RewardRules.milestoneThresholds in reward_rules.dart.
/// Source of truth for server-side milestone verification.
const MILESTONE_THRESHOLDS = [100_000, 500_000, 1_000_000, 2_500_000, 5_000_000, 10_000_000] as const;
const MILESTONE_AMOUNT = 500;

function milestoneLabel(threshold: number): string {
	if (threshold >= 10_000_000) return `${threshold / 10_000_000} Cr Chants`;
	if (threshold >= 100_000) return `${threshold / 100_000} Lakh Chants`;
	return `${threshold} Chants`;
}

/// Returns the first milestone threshold crossed when totals move from [before] to [after],
/// or null if none was crossed.
function milestoneCrossed(before: number, after: number): number | null {
	for (const t of MILESTONE_THRESHOLDS) {
		if (before < t && after >= t) return t;
	}
	return null;
}

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

	// ── Streak recomputation ────────────────────────────────────────────────
	// Recompute currentStreak / longestStreak server-side from the Session table
	// for every program touched by this batch. This is the authoritative write;
	// the programs endpoint deliberately ignores client-supplied streak values.
	if (inserted.count > 0) {
		const uniqueProgramIdsForStreak = Array.from(new Set(body.sessions.map((s) => s.program_id)));
		await Promise.all(uniqueProgramIdsForStreak.map((id) => recomputeProgramStreaks(id)));
		emitChange('program');
	}

	// Recompute Program.totalWritings and Program.totalChants from the Session
	// table for every affected program, split by modality. Server-authoritative.
	if (inserted.count > 0) {
		const programIdsForTotal = Array.from(new Set(body.sessions.map((s) => s.program_id)));
		await Promise.all(
			programIdsForTotal.map(async (programId) => {
				const [writingAgg, chantAgg] = await Promise.all([
					prisma.session.aggregate({
						where: { programId, modality: 'handwriting' },
						_sum: { countAdded: true }
					}),
					prisma.session.aggregate({
						where: { programId, modality: { not: 'handwriting' } },
						_sum: { countAdded: true }
					})
				]);
				return prisma.program.update({
					where: { id: programId },
					data: {
						totalWritings: writingAgg._sum.countAdded ?? 0,
						totalChants: chantAgg._sum.countAdded ?? 0
					}
				});
			})
		);
	}

	// Auto-award per-chant reward points for newly inserted sessions only.
	// Only sessions that were actually inserted (not duplicates) contribute.
	const pointsEarned: Record<string, number> = {};
	if (inserted.count > 0) {
		const rate = await getRewardRate();
		// Tally chants per member across the inserted sessions.
		// We trust skipDuplicates above: duplicates don't get double-awarded because
		// we gate on the idempotency key (session.id) — re-posting the same session
		// returns inserted.count=0 and this block is skipped.
		const chantsByMember = new Map<string, number>();
		for (const s of body.sessions) {
			// Handwriting sessions earn writing-rate rewards, not chant-rate points.
			if (s.modality === 'handwriting') continue;
			chantsByMember.set(s.member_id, (chantsByMember.get(s.member_id) ?? 0) + s.count_added);
		}
		for (const [memberId, chants] of chantsByMember) {
			const pts = Math.floor(chants / rate);
			if (pts <= 0) continue;
			// Key MUST include memberId — all-sessions key is shared across members,
			// causing the second member's upsert to silently no-op.
			const memberSessionIds = body.sessions
				.filter((s) => s.member_id === memberId && s.modality !== 'handwriting')
				.map((s) => s.id)
				.sort()
				.join('_');
			const eventId = `chant_${memberId}_${memberSessionIds}`.slice(0, 80);
			await prisma.rewardEvent.upsert({
				where: { id: eventId },
				create: {
					id: eventId,
					memberId,
					kind: 'earn',
					amount: pts,
					source: `chant_session (${chants} chants @ 1pt/${rate})`
				},
				update: {} // idempotent — don't re-award on retry
			});
			pointsEarned[memberId] = pts;
		}
		if (Object.keys(pointsEarned).length > 0) {
			await Promise.all(Object.keys(pointsEarned).map((id) => recomputeMemberBalance(id)));
			emitChange('reward_event');
		}

		// ── Milestone check ─────────────────────────────────────────────────
		const countAddedByProgram = new Map<string, number>();
		for (const s of body.sessions) {
			countAddedByProgram.set(s.program_id, (countAddedByProgram.get(s.program_id) ?? 0) + s.count_added);
		}
		// Batch-fetch all affected programs in one query instead of N findUnique calls.
		const programIdsForMilestone = Array.from(countAddedByProgram.keys());
		const milestonePrograms = await prisma.program.findMany({
			where: { id: { in: programIdsForMilestone } },
			select: { id: true, memberId: true, totalWritings: true, totalChants: true }
		});
		const milestoneMembers = new Set<string>();
		await Promise.all(
			milestonePrograms.map(async (program) => {
				const countAdded = countAddedByProgram.get(program.id) ?? 0;
				const after = program.totalChants + program.totalWritings;
				const before = after - countAdded;
				const threshold = milestoneCrossed(before, after);
				if (threshold === null) return;
				const milestoneEventId = `milestone:${program.memberId}:${threshold}`;
				await prisma.rewardEvent.upsert({
					where: { id: milestoneEventId },
					create: {
						id: milestoneEventId,
						memberId: program.memberId,
						kind: 'milestone',
						amount: MILESTONE_AMOUNT,
						source: `Milestone: ${milestoneLabel(threshold)}`
					},
					update: {}
				});
				milestoneMembers.add(program.memberId);
			})
		);
		if (milestoneMembers.size > 0) {
			await Promise.all([...milestoneMembers].map((id) => recomputeMemberBalance(id)));
			emitChange('reward_event');
		}
	}

	// ── Daily-target bonus ──────────────────────────────────────────────────
	// For each program touched by this batch, sum countAdded for today and check
	// whether it just crossed the program's dailyTarget for the first time.
	// dailyTarget = ceil(targetWritings / targetDays) — mirrors Flutter's
	// ProgramRepository.computeDailyTarget.
	// Idempotency key: daily_target_bonus:<programId>:<YYYY-MM-DD> (UTC).
	if (inserted.count > 0) {
		const uniqueProgramIds = Array.from(new Set(body.sessions.map((s) => s.program_id)));
		const now = new Date();
		const dayStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
		const dayEnd = new Date(dayStart.getTime() + 86_400_000);
		const calendarDate = dayStart.toISOString().slice(0, 10); // "YYYY-MM-DD"

		const programs = await prisma.program.findMany({
			where: { id: { in: uniqueProgramIds } },
			select: { id: true, memberId: true, targetWritings: true, targetDays: true }
		});

		const dailyBonusMembers = new Set<string>();
		await Promise.all(
			programs.map(async (program) => {
				const dailyTarget = program.targetDays > 0
					? Math.ceil(program.targetWritings / program.targetDays)
					: 0;
				if (dailyTarget <= 0) return;

				const agg = await prisma.session.aggregate({
					where: { programId: program.id, startedAt: { gte: dayStart, lt: dayEnd } },
					_sum: { countAdded: true }
				});
				if ((agg._sum.countAdded ?? 0) < dailyTarget) return;

				const bonusId = `daily_target_bonus:${program.id}:${calendarDate}`;
				await prisma.rewardEvent.upsert({
					where: { id: bonusId },
					create: {
						id: bonusId,
						memberId: program.memberId,
						kind: 'milestone',
						amount: 50,
						source: 'daily_target_bonus'
					},
					update: {}
				});
				dailyBonusMembers.add(program.memberId);
			})
		);
		if (dailyBonusMembers.size > 0) {
			await Promise.all([...dailyBonusMembers].map((id) => recomputeMemberBalance(id)));
			emitChange('reward_event');
		}
	}

	return snakeJson({ created: inserted.count, requested: body.sessions.length, points_earned: pointsEarned });
};
