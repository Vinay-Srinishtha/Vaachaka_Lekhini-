import type { PageServerLoad } from './$types';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');

	const sadhanas = await prisma.globalSadhana.findMany({
		orderBy: [{ status: 'asc' }, { startAt: 'desc' }],
		select: {
			id: true,
			title: true,
			status: true,
			participationMode: true,
			targetCount: true,
			currentCount: true,
			startAt: true,
			endAt: true,
			imageUrl: true,
			isSponsored: true,
			completedAt: true,
			mantra: { select: { nameRoman: true, nameTelugu: true, slug: true } },
			_count: { select: { enrollments: true, contributions: true } }
		}
	});

	// Per-day contribution totals for the last 30 days (for sparklines)
	const thirtyDaysAgo = new Date();
	thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

	const recentContributions = await prisma.globalSadhanaContribution.groupBy({
		by: ['globalSadhanaId', 'createdAt'],
		_sum: { countAdded: true },
		where: { createdAt: { gte: thirtyDaysAgo } }
	});

	// Top contributors per sadhana
	const topContributors = await prisma.globalSadhanaContribution.groupBy({
		by: ['globalSadhanaId', 'memberId'],
		_sum: { countAdded: true },
		orderBy: { _sum: { countAdded: 'desc' } }
	});

	// Member names for top contributors
	const memberIds = [...new Set(topContributors.map((c) => c.memberId))].slice(0, 100);
	const members = await prisma.member.findMany({
		where: { id: { in: memberIds } },
		select: { id: true, displayName: true }
	});
	const memberMap = Object.fromEntries(members.map((m) => [m.id, m.displayName]));

	// Modality breakdown per sadhana
	const modalityBreakdown = await prisma.globalSadhanaContribution.groupBy({
		by: ['globalSadhanaId', 'modality'],
		_sum: { countAdded: true },
		_count: { id: true }
	});

	// Daily contributions bucketed by date string (YYYY-MM-DD) per sadhana
	const dailyMap: Record<string, Record<string, number>> = {};
	for (const row of recentContributions) {
		const sid = row.globalSadhanaId;
		const day = row.createdAt.toISOString().slice(0, 10);
		if (!dailyMap[sid]) dailyMap[sid] = {};
		dailyMap[sid][day] = (dailyMap[sid][day] ?? 0) + (row._sum.countAdded ?? 0);
	}

	// Top 5 contributors per sadhana
	const topMap: Record<string, { name: string; total: number }[]> = {};
	for (const row of topContributors) {
		const sid = row.globalSadhanaId;
		if (!topMap[sid]) topMap[sid] = [];
		if (topMap[sid].length < 5) {
			topMap[sid].push({ name: memberMap[row.memberId] ?? 'Unknown', total: row._sum.countAdded ?? 0 });
		}
	}

	// Modality breakdown per sadhana
	const modalityMap: Record<string, Record<string, number>> = {};
	for (const row of modalityBreakdown) {
		const sid = row.globalSadhanaId;
		if (!modalityMap[sid]) modalityMap[sid] = {};
		modalityMap[sid][row.modality] = row._sum.countAdded ?? 0;
	}

	return { sadhanas, dailyMap, topMap, modalityMap };
};
