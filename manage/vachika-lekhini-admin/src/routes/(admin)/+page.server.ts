import type { PageServerLoad } from './$types';
import { prisma } from '$lib/server/prisma';

export const load: PageServerLoad = async () => {
	const now = new Date();
	const DAY = 86_400_000;
	const todayStart    = new Date(now.getFullYear(), now.getMonth(), now.getDate());
	const yesterdayStart = new Date(todayStart.getTime() - DAY);
	const days30ago     = new Date(now.getTime() - 30 * DAY);

	const [
		mantraCount, activeMantras,
		storeCount, flagCount,
		accountCount, bannedAccountCount,
		memberCount,
		programCount, activePrograms,
		sessionCount,
		sessionsToday, sessionsYesterday,
		deviceCount,
		chantsToday,
		recentAccounts,
		modalitySplit,
	] = await Promise.all([
		prisma.mantra.count(),
		prisma.mantra.count({ where: { isActive: true } }),
		prisma.storeItem.count({ where: { isActive: true } }),
		prisma.featureFlag.count(),
		prisma.account.count(),
		prisma.account.count({ where: { isBanned: true } }),
		prisma.member.count(),
		prisma.program.count(),
		prisma.program.count({ where: { completedAt: null } }),
		prisma.session.count(),
		prisma.session.count({ where: { startedAt: { gte: todayStart } } }),
		prisma.session.count({ where: { startedAt: { gte: yesterdayStart, lt: todayStart } } }),
		prisma.device.count(),
		prisma.session.aggregate({ where: { startedAt: { gte: todayStart } }, _sum: { countAdded: true } }),
		prisma.account.findMany({
			orderBy: { createdAt: 'desc' },
			take: 6,
			select: { id: true, mobile: true, createdAt: true, isBanned: true, _count: { select: { members: true } } }
		}),
		prisma.session.groupBy({ by: ['modality'], _count: true }),
	]);

	// 30-day daily session counts
	const raw30d = await prisma.$queryRaw<{ day: string; cnt: number; chants: number }[]>`
		SELECT date_trunc('day', "startedAt")::text AS day,
		       count(*)::int                        AS cnt,
		       coalesce(sum("countAdded"),0)::int    AS chants
		FROM "Session"
		WHERE "startedAt" >= ${days30ago}
		GROUP BY 1 ORDER BY 1
	`;

	const sessions30d: { day: string; count: number; chants: number }[] = [];
	for (let i = 29; i >= 0; i--) {
		const d   = new Date(now.getTime() - i * DAY);
		const key = d.toISOString().slice(0, 10);
		const lbl = d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
		const hit = raw30d.find((r) => r.day.startsWith(key));
		sessions30d.push({ day: lbl, count: hit ? Number(hit.cnt) : 0, chants: hit ? Number(hit.chants) : 0 });
	}

	// Top 5 mantras by program count
	const topMantraGroups = await prisma.program.groupBy({
		by: ['mantraId'],
		_count: { mantraId: true },
		orderBy: { _count: { mantraId: 'desc' } },
		take: 5,
	});
	const topMantraRows = topMantraGroups.length
		? await prisma.mantra.findMany({
				where: { id: { in: topMantraGroups.map((t) => t.mantraId) } },
				select: { id: true, nameRoman: true },
			})
		: [];
	const topMantras = topMantraGroups.map((t) => ({
		name:  topMantraRows.find((r) => r.id === t.mantraId)?.nameRoman ?? 'Unknown',
		count: t._count.mantraId,
	}));

	const sessionsDelta =
		sessionsYesterday > 0
			? Math.round(((sessionsToday - sessionsYesterday) / sessionsYesterday) * 100)
			: sessionsToday > 0 ? 100 : 0;

	// 7-day sparkline for sessions (last entry in sessions30d)
	const spark7 = sessions30d.slice(-7).map((d) => d.count);

	return {
		stats: {
			mantraCount, activeMantras,
			storeCount, flagCount,
			accountCount, bannedAccountCount,
			memberCount,
			programCount, activePrograms,
			sessionCount,
			sessionsToday, sessionsYesterday, sessionsDelta,
			deviceCount,
			chantsToday: chantsToday._sum.countAdded ?? 0,
		},
		sessions30d,
		spark7,
		modalitySplit,
		recentAccounts,
		topMantras,
	};
};
