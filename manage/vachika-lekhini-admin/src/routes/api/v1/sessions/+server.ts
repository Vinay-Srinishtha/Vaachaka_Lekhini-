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
		for (const programId of uniqueProgramIdsForStreak) {
			await recomputeProgramStreaks(programId);
		}
		emitChange('program');
	}

	// Recompute Program.totalWritings from the Session table for every affected
	// program. This is the server-authoritative aggregate — Flutter's local
	// arithmetic (totalChants + totalWritings pushed via programs.upsert) must
	// not overwrite this field. Fix for Issue #3.
	if (inserted.count > 0) {
		const programIdsForTotal = Array.from(new Set(body.sessions.map((s) => s.program_id)));
		for (const programId of programIdsForTotal) {
			const agg = await prisma.session.aggregate({
				where: { programId },
				_sum: { countAdded: true }
			});
			await prisma.program.update({
				where: { id: programId },
				data: { totalWritings: agg._sum.countAdded ?? 0 }
			});
		}
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
			chantsByMember.set(s.member_id, (chantsByMember.get(s.member_id) ?? 0) + s.count_added);
		}
		for (const [memberId, chants] of chantsByMember) {
			const pts = Math.floor(chants / rate);
			if (pts <= 0) continue;
			const eventId = `chant_${body.sessions.map((s) => s.id).join('_').slice(0, 60)}`;
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
			for (const memberId of Object.keys(pointsEarned)) {
				await recomputeMemberBalance(memberId);
			}
			emitChange('reward_event');
		}

		// ── Milestone check ─────────────────────────────────────────────────
		// For each program touched by this batch, fetch the current server-side
		// totalWritings (which Flutter sends as totalChants + totalWritings combined
		// in the programs.upsert payload — see _programPayload in
		// program_repository_drift.dart). Derive pre-session total from the
		// count_added values, then test for a crossed threshold.
		//
		// Idempotency key: milestone:<memberId>:<threshold> — safe to retry.
		const countAddedByProgram = new Map<string, number>();
		for (const s of body.sessions) {
			countAddedByProgram.set(s.program_id, (countAddedByProgram.get(s.program_id) ?? 0) + s.count_added);
		}
		const milestoneMembers = new Set<string>();
		for (const [programId, countAdded] of countAddedByProgram) {
			const program = await prisma.program.findUnique({
				where: { id: programId },
				select: { memberId: true, totalWritings: true }
			});
			if (!program) continue;
			const after = program.totalWritings;
			const before = after - countAdded;
			const threshold = milestoneCrossed(before, after);
			if (threshold === null) continue;
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
				update: {} // idempotent — one grant per threshold per member ever
			});
			milestoneMembers.add(program.memberId);
		}
		if (milestoneMembers.size > 0) {
			for (const memberId of milestoneMembers) {
				await recomputeMemberBalance(memberId);
			}
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
		for (const program of programs) {
			const dailyTarget = program.targetDays > 0
				? Math.ceil(program.targetWritings / program.targetDays)
				: 0;
			if (dailyTarget <= 0) continue;

			const agg = await prisma.session.aggregate({
				where: { programId: program.id, startedAt: { gte: dayStart, lt: dayEnd } },
				_sum: { countAdded: true }
			});
			const todayTotal = agg._sum.countAdded ?? 0;
			if (todayTotal < dailyTarget) continue;

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
				update: {} // idempotent — never re-award for the same program+day
			});
			dailyBonusMembers.add(program.memberId);
		}
		if (dailyBonusMembers.size > 0) {
			for (const memberId of dailyBonusMembers) {
				await recomputeMemberBalance(memberId);
			}
			emitChange('reward_event');
		}
	}

	return snakeJson({ created: inserted.count, requested: body.sessions.length, points_earned: pointsEarned });
};
