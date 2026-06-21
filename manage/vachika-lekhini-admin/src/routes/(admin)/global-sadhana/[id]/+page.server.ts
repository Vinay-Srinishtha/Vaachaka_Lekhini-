import type { PageServerLoad } from './$types';
import { error } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';

/**
 * Detailed stats dashboard for a single Global Sadhana (community program).
 *
 * Aggregates enrollment, contribution and progress metrics so admins can see
 * — at a glance — how a program is performing: who is contributing, by which
 * modality, the day-by-day momentum, and a naive projection to the target.
 */
export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const id = event.params.id;

	const sadhana = await prisma.globalSadhana.findUnique({
		where: { id },
		select: {
			id: true,
			title: true,
			description: true,
			status: true,
			participationMode: true,
			targetCount: true,
			currentCount: true,
			startAt: true,
			endAt: true,
			imageUrl: true,
			isSponsored: true,
			instructions: true,
			completedAt: true,
			createdAt: true,
			mantra: { select: { nameRoman: true, nameTelugu: true, slug: true } }
		}
	});
	if (!sadhana) throw error(404, 'Global Sadhana not found');

	const since30 = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

	const [
		enrollTotal,
		voiceTrained,
		hwTrained,
		contribAgg,
		byModality,
		distinctContributors,
		topRaw,
		recent,
		dailyRaw
	] = await Promise.all([
		prisma.globalSadhanaEnrollment.count({ where: { globalSadhanaId: id } }),
		prisma.globalSadhanaEnrollment.count({
			where: { globalSadhanaId: id, voiceTrainingComplete: true }
		}),
		prisma.globalSadhanaEnrollment.count({
			where: { globalSadhanaId: id, handwritingTrainingComplete: true }
		}),
		prisma.globalSadhanaContribution.aggregate({
			where: { globalSadhanaId: id },
			_sum: { countAdded: true },
			_count: { _all: true }
		}),
		prisma.globalSadhanaContribution.groupBy({
			by: ['modality'],
			where: { globalSadhanaId: id },
			_sum: { countAdded: true },
			_count: { _all: true }
		}),
		prisma.globalSadhanaContribution.findMany({
			where: { globalSadhanaId: id },
			distinct: ['memberId'],
			select: { memberId: true }
		}),
		prisma.globalSadhanaContribution.groupBy({
			by: ['memberId'],
			where: { globalSadhanaId: id },
			_sum: { countAdded: true },
			_count: { _all: true },
			orderBy: { _sum: { countAdded: 'desc' } },
			take: 12
		}),
		prisma.globalSadhanaContribution.findMany({
			where: { globalSadhanaId: id },
			orderBy: { createdAt: 'desc' },
			take: 15,
			select: {
				id: true,
				countAdded: true,
				modality: true,
				createdAt: true,
				member: { select: { id: true, displayName: true } }
			}
		}),
		prisma.$queryRaw<{ day: Date; count: number; sessions: number }[]>`
			SELECT date_trunc('day', "createdAt")::date AS day,
			       SUM("countAdded")::int AS count,
			       COUNT(*)::int AS sessions
			FROM "GlobalSadhanaContribution"
			WHERE "globalSadhanaId" = ${id} AND "createdAt" >= ${since30}
			GROUP BY day
			ORDER BY day ASC
		`
	]);

	// Resolve member names for the top contributors leaderboard.
	const topMemberIds = topRaw.map((t) => t.memberId);
	const members = await prisma.member.findMany({
		where: { id: { in: topMemberIds } },
		select: { id: true, displayName: true, account: { select: { mobile: true } } }
	});
	const nameById = new Map(members.map((m) => [m.id, m]));
	const topContributors = topRaw.map((t) => ({
		memberId: t.memberId,
		name: nameById.get(t.memberId)?.displayName ?? '(unknown)',
		mobile: nameById.get(t.memberId)?.account?.mobile ?? null,
		total: t._sum.countAdded ?? 0,
		sessions: t._count._all
	}));

	const modalityBreakdown = byModality.map((m) => ({
		modality: m.modality,
		total: m._sum.countAdded ?? 0,
		sessions: m._count._all
	}));

	// Build a dense 30-day series (fill gaps with zero) for the activity chart.
	const dayMap = new Map(dailyRaw.map((d) => [new Date(d.day).toISOString().slice(0, 10), d]));
	const series: { date: string; count: number; sessions: number }[] = [];
	for (let i = 29; i >= 0; i--) {
		const d = new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
		const row = dayMap.get(d);
		series.push({ date: d, count: row?.count ?? 0, sessions: row?.sessions ?? 0 });
	}

	return {
		sadhana,
		stats: {
			enrollTotal,
			voiceTrained,
			hwTrained,
			activeContributors: distinctContributors.length,
			totalContributed: contribAgg._sum.countAdded ?? 0,
			totalSessions: contribAgg._count._all,
			modalityBreakdown,
			topContributors,
			recent,
			series
		}
	};
};
