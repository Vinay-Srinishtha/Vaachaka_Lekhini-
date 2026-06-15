import type { PageServerLoad } from './$types';
import { prisma } from '$lib/server/prisma';

export const load: PageServerLoad = async () => {
	const now = new Date();
	const DAY = 86_400_000;
	const todayStart     = new Date(now.getFullYear(), now.getMonth(), now.getDate());
	const yesterdayStart = new Date(todayStart.getTime() - DAY);
	const days7ago       = new Date(now.getTime() - 7 * DAY);
	const days30ago      = new Date(now.getTime() - 30 * DAY);

	const [
		mantraCount, activeMantras,
		storeCount, flagCount,
		accountCount, bannedAccountCount,
		memberCount,
		programCount, activePrograms, completedPrograms,
		sessionCount, sessionsToday, sessionsYesterday, sessions24h,
		deviceCount,
		chantsToday,
		rewardEarned, rewardSpent,
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
		prisma.program.count({ where: { completedAt: { not: null } } }),
		prisma.session.count(),
		prisma.session.count({ where: { startedAt: { gte: todayStart } } }),
		prisma.session.count({ where: { startedAt: { gte: yesterdayStart, lt: todayStart } } }),
		prisma.session.count({ where: { startedAt: { gte: new Date(now.getTime() - DAY) } } }),
		prisma.device.count(),
		prisma.session.aggregate({ where: { startedAt: { gte: todayStart } }, _sum: { countAdded: true } }),
		prisma.rewardEvent.aggregate({ where: { kind: 'earn' }, _sum: { amount: true } }),
		prisma.rewardEvent.aggregate({ where: { kind: 'spend' }, _sum: { amount: true } }),
		prisma.account.findMany({
			orderBy: { createdAt: 'desc' },
			take: 6,
			select: { id: true, mobile: true, createdAt: true, isBanned: true, _count: { select: { members: true } } }
		}),
		prisma.session.groupBy({ by: ['modality'], _count: true }),
	]);

	// 30-day + 7-day daily session counts (single raw query covers both)
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

	// 7-day view (last 7 entries with weekday labels)
	const sessions7d = sessions30d.slice(-7).map((d, i) => {
		const date = new Date(now.getTime() - (6 - i) * DAY);
		return { ...d, weekday: date.toLocaleDateString('en-IN', { weekday: 'short' }) };
	});

	// Top mantras by program count
	const topMantrasRaw = await prisma.$queryRaw<{ name: string; count: number }[]>`
		SELECT m."nameRoman" AS name, COUNT(p.id)::int AS count
		FROM "Program" p
		JOIN "Mantra" m ON m.id = p."mantraId"
		GROUP BY m.id, m."nameRoman"
		ORDER BY count DESC
		LIMIT 5`;
	const topMantras = topMantrasRaw.map((r) => ({ name: r.name, count: Number(r.count) }));

	// Top members by total progress (chants + writings)
	const topMembersRaw = await prisma.$queryRaw<{ name: string; total: number }[]>`
		SELECT m."displayName" AS name,
		       COALESCE(SUM(p."totalChants" + p."totalWritings"), 0)::int AS total
		FROM "Member" m
		JOIN "Account" ab ON ab.id = m."accountId" AND ab."isBanned" = false
		LEFT JOIN "Program" p ON p."memberId" = m.id
		GROUP BY m.id, m."displayName"
		ORDER BY total DESC
		LIMIT 5`;
	const topMembers = topMembersRaw.map((r) => ({ name: r.name, total: Number(r.total) }));

	// Leaderboards — top 8 per category
	const [lbStreakRaw, lbProgressRaw, lbSessionsRaw] = await Promise.all([
		prisma.$queryRaw<{ name: string; mobile: string; value: number }[]>`
			SELECT m."displayName" AS name, a.mobile, MAX(p."longestStreak")::int AS value
			FROM "Program" p
			JOIN "Member" m ON m.id = p."memberId"
			JOIN "Account" a ON a.id = m."accountId" AND a."isBanned" = false
			GROUP BY m."displayName", a.mobile
			ORDER BY value DESC LIMIT 8`,
		prisma.$queryRaw<{ name: string; mobile: string; value: number }[]>`
			SELECT m."displayName" AS name, a.mobile,
			       SUM(p."totalChants" + p."totalWritings")::int AS value
			FROM "Program" p
			JOIN "Member" m ON m.id = p."memberId"
			JOIN "Account" a ON a.id = m."accountId" AND a."isBanned" = false
			GROUP BY m."displayName", a.mobile
			ORDER BY value DESC LIMIT 8`,
		prisma.$queryRaw<{ name: string; mobile: string; value: number }[]>`
			SELECT m."displayName" AS name, a.mobile, COUNT(s.id)::int AS value
			FROM "Session" s
			JOIN "Member" m ON m.id = s."memberId"
			JOIN "Account" a ON a.id = m."accountId" AND a."isBanned" = false
			GROUP BY m."displayName", a.mobile
			ORDER BY value DESC LIMIT 8`,
	]);
	const toBoard = (rows: { name: string; mobile: string; value: number }[]) =>
		rows.map((r) => ({ name: r.name, mobile: r.mobile, value: Number(r.value) }));
	const leaderboards = {
		streak:   toBoard(lbStreakRaw),
		progress: toBoard(lbProgressRaw),
		sessions: toBoard(lbSessionsRaw),
	};

	const sessionsDelta =
		sessionsYesterday > 0
			? Math.round(((sessionsToday - sessionsYesterday) / sessionsYesterday) * 100)
			: sessionsToday > 0 ? 100 : 0;

	const spark7 = sessions30d.slice(-7).map((d) => d.count);

	return {
		stats: {
			mantraCount, activeMantras,
			storeCount, flagCount,
			accountCount, bannedAccountCount,
			memberCount,
			programCount, activePrograms, completedPrograms,
			sessionCount, sessionsToday, sessionsYesterday, sessionsDelta, sessions24h,
			deviceCount,
			chantsToday: chantsToday._sum.countAdded ?? 0,
			rewardEarned: rewardEarned._sum.amount ?? 0,
			rewardSpent:  rewardSpent._sum.amount ?? 0,
		},
		sessions30d,
		sessions7d,
		spark7,
		modalitySplit,
		recentAccounts,
		topMantras,
		topMembers,
		leaderboards,
	};
};
