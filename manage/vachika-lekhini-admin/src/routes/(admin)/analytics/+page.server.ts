import type { PageServerLoad } from './$types';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');

	const now = new Date();
	const day = 24 * 60 * 60 * 1000;
	const days7 = new Date(now.getTime() - 7 * day);
	const days30 = new Date(now.getTime() - 30 * day);

	const [
		totalAccounts,
		totalMembers,
		totalSessions,
		totalPrograms,
		activePrograms,
		totalRewardEarned,
		totalRewardSpent,
		sessions7d,
		sessions30d,
		topMantras,
		topMembers,
		modalitySplit,
		recentActivity
	] = await Promise.all([
		prisma.account.count(),
		prisma.member.count(),
		prisma.session.count(),
		prisma.program.count(),
		prisma.program.count({ where: { completedAt: null } }),
		prisma.rewardEvent.aggregate({ where: { kind: 'earn' }, _sum: { amount: true } }),
		prisma.rewardEvent.aggregate({ where: { kind: 'spend' }, _sum: { amount: true } }),
		// Sessions last 7 days grouped by day
		prisma.$queryRaw<{ day: string; count: bigint }[]>`
			SELECT date_trunc('day', "startedAt")::text as day, count(*)::int as count
			FROM "Session"
			WHERE "startedAt" >= ${days7}
			GROUP BY 1 ORDER BY 1
		`,
		prisma.session.count({ where: { startedAt: { gte: days30 } } }),
		// Top 5 mantras by session count
		prisma.session.groupBy({
			by: ['programId'],
			_count: true,
			orderBy: { _count: { programId: 'desc' } },
			take: 10
		}).then(async (groups) => {
			const programIds = groups.map((g) => g.programId);
			const programs = await prisma.program.findMany({
				where: { id: { in: programIds } },
				include: { mantra: { select: { nameRoman: true } } }
			});
			const map = Object.fromEntries(programs.map((p) => [p.id, p.mantra.nameRoman]));
			// Aggregate by mantra name — skip programs whose mantra was deleted
			const byMantra: Record<string, number> = {};
			for (const g of groups) {
				const name = map[g.programId];
				if (!name) continue;
				byMantra[name] = (byMantra[name] ?? 0) + g._count;
			}
			return Object.entries(byMantra)
				.sort((a, b) => b[1] - a[1])
				.slice(0, 5)
				.map(([name, count]) => ({ name, count }));
		}),
		// Top 5 members by total count
		prisma.session.groupBy({
			by: ['memberId'],
			_sum: { countAdded: true },
			orderBy: { _sum: { countAdded: 'desc' } },
			take: 5
		}).then(async (groups) => {
			const memberIds = groups.map((g) => g.memberId);
			const members = await prisma.member.findMany({
				where: { id: { in: memberIds } },
				select: { id: true, displayName: true }
			});
			const map = Object.fromEntries(members.map((m) => [m.id, m.displayName]));
			// Skip members that no longer exist in DB
			return groups
				.filter((g) => map[g.memberId])
				.map((g) => ({ name: map[g.memberId], total: g._sum.countAdded ?? 0 }));
		}),
		// Session modality split
		prisma.session.groupBy({ by: ['modality'], _count: true }),
		// Recent sessions (last 24h)
		prisma.session.count({ where: { startedAt: { gte: new Date(now.getTime() - day) } } })
	]);

	// Build 7-day bar data (fill missing days with 0)
	const barData: { day: string; count: number }[] = [];
	for (let i = 6; i >= 0; i--) {
		const d = new Date(now.getTime() - i * day);
		const key = d.toISOString().slice(0, 10);
		const found = sessions7d.find((r) => r.day.startsWith(key));
		barData.push({ day: key, count: found ? Number(found.count) : 0 });
	}

	return {
		stats: {
			totalAccounts,
			totalMembers,
			totalSessions,
			totalPrograms,
			activePrograms,
			totalRewardEarned: totalRewardEarned._sum.amount ?? 0,
			totalRewardSpent: totalRewardSpent._sum.amount ?? 0,
			sessions7d: barData,
			sessions30d,
			recentActivity
		},
		topMantras,
		topMembers,
		modalitySplit
	};
};
