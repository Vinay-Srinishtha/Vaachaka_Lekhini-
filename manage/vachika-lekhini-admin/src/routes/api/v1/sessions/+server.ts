import type { RequestHandler } from './$types';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { readJsonBody } from '$lib/server/json-input';
import { requireAccount } from '$lib/server/user-auth';
import { assertOwnsMembers, assertOwnsPrograms, sessionCreateSchema, recomputeMemberBalance, recomputeProgramStreaks } from '$lib/server/sync';
import { emitChange } from '$lib/server/live';
import { getRewardRate, getRewardEarnConfig } from '$lib/server/reward-config';

function milestoneLabel(threshold: number): string {
	if (threshold >= 10_000_000) return `${threshold / 10_000_000} Cr Chants`;
	if (threshold >= 100_000) return `${threshold / 100_000} Lakh Chants`;
	return `${threshold} Chants`;
}

function milestoneCrossed(thresholds: number[], before: number, after: number): number | null {
	for (const t of thresholds) {
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
				// Auto-set completedAt when threshold is first crossed; never clear it once set.
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

	// Auto-award per-chant reward points for newly inserted sessions.
	// Earn events are keyed per-session so re-posting a session batch never
	// double-awards — each session has its own idempotency key.
	const pointsEarned: Record<string, number> = {};
	if (inserted.count > 0) {
		const [rate, earnConfig] = await Promise.all([getRewardRate(), getRewardEarnConfig()]);

		// One earn event per chant session — stable per-session idempotency key.
		const touchedMembers = new Set<string>();
		for (const s of body.sessions) {
			if (s.modality === 'handwriting') continue; // handwriting uses its own rate
			const pts = Math.floor(s.count_added / rate);
			if (pts <= 0) continue;
			const eventId = `earn:session:${s.id}`;
			await prisma.rewardEvent.upsert({
				where: { id: eventId },
				create: {
					id: eventId,
					memberId: s.member_id,
					kind: 'earn',
					amount: pts,
					source: `chant_session (${s.count_added} chants @ 1pt/${rate})`
				},
				update: {}
			});
			pointsEarned[s.member_id] = (pointsEarned[s.member_id] ?? 0) + pts;
			touchedMembers.add(s.member_id);
		}
		if (touchedMembers.size > 0) {
			await Promise.all([...touchedMembers].map((id) => recomputeMemberBalance(id)));
			emitChange('reward_event');
		}

		// ── Milestone check ─────────────────────────────────────────────────
		const countAddedByProgram = new Map<string, number>();
		for (const s of body.sessions) {
			countAddedByProgram.set(s.program_id, (countAddedByProgram.get(s.program_id) ?? 0) + s.count_added);
		}
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
				const threshold = milestoneCrossed(earnConfig.milestoneThresholds, before, after);
				if (threshold === null) return;
				const milestoneEventId = `milestone:${program.memberId}:${threshold}`;
				await prisma.rewardEvent.upsert({
					where: { id: milestoneEventId },
					create: {
						id: milestoneEventId,
						memberId: program.memberId,
						kind: 'milestone',
						amount: earnConfig.milestoneCross,
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
	// Idempotency key: daily_target_bonus:<programId>:<YYYY-MM-DD> (UTC).
	if (inserted.count > 0) {
		const earnConfig = await getRewardEarnConfig();
		const uniqueProgramIds = Array.from(new Set(body.sessions.map((s) => s.program_id)));
		const now = new Date();
		const dayStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
		const dayEnd = new Date(dayStart.getTime() + 86_400_000);
		const calendarDate = dayStart.toISOString().slice(0, 10);

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
						amount: earnConfig.dailyTarget,
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
