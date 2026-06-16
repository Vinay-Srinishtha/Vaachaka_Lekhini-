import type { PageServerLoad } from './$types';
import { prisma } from '$lib/server/prisma';

export const load: PageServerLoad = async ({ url }) => {
	const board = (url.searchParams.get('board') ?? 'progress') as 'progress' | 'streak' | 'sessions';
	const search = url.searchParams.get('q')?.trim() ?? '';

	// Summary stats always shown at top
	const [totalMembers, totalSessions, totalProgress, activeStreaks] = await Promise.all([
		prisma.member.count(),
		prisma.session.count(),
		prisma.$queryRaw<{ total: number }[]>`
			SELECT COALESCE(SUM("totalChants" + "totalWritings"), 0)::int AS total
			FROM "Program"`,
		prisma.$queryRaw<{ cnt: number }[]>`
			SELECT COUNT(DISTINCT "memberId")::int AS cnt
			FROM "Program"
			WHERE "currentStreak" > 0`,
	]);

	type ProgressRow = { rank: number; member_id: string; name: string; mobile: string; total_progress: number; longest_streak: number; current_streak: number; session_count: number };
	type StreakRow    = { rank: number; member_id: string; name: string; mobile: string; total_progress: number; longest_streak: number; current_streak: number; session_count: number };
	type SessionRow  = { rank: number; member_id: string; name: string; mobile: string; total_progress: number; longest_streak: number; current_streak: number; session_count: number };

	const BASE_CTE = `
		WITH member_stats AS (
		  SELECT
		    m.id                                                            AS member_id,
		    m."displayName"                                                 AS name,
		    a.mobile,
		    COALESCE(SUM(p."totalChants" + p."totalWritings"), 0)::int      AS total_progress,
		    COALESCE(MAX(p."longestStreak"), 0)::int                        AS longest_streak,
		    COALESCE(MAX(p."currentStreak"), 0)::int                        AS current_streak,
		    (SELECT COUNT(*)::int FROM "Session" s WHERE s."memberId" = m.id) AS session_count
		  FROM "Member" m
		  JOIN "Account" a ON a.id = m."accountId" AND a."isBanned" = false
		  LEFT JOIN "Program" p ON p."memberId" = m.id
		  GROUP BY m.id, m."displayName", a.mobile
		)`;

	let rows: ProgressRow[] | StreakRow[] | SessionRow[] = [];

	if (board === 'streak') {
		rows = await prisma.$queryRawUnsafe<StreakRow[]>(`
			${BASE_CTE}
			SELECT
			  ROW_NUMBER() OVER (ORDER BY longest_streak DESC, total_progress DESC)::int AS rank,
			  member_id, name, mobile, total_progress, longest_streak, current_streak, session_count
			FROM member_stats
			${search ? `WHERE (name ILIKE '%' || $1 || '%' OR mobile ILIKE '%' || $1 || '%')` : ''}
			ORDER BY rank
			LIMIT 200
		`, ...(search ? [search] : []));
	} else if (board === 'sessions') {
		rows = await prisma.$queryRawUnsafe<SessionRow[]>(`
			${BASE_CTE}
			SELECT
			  ROW_NUMBER() OVER (ORDER BY session_count DESC, total_progress DESC)::int AS rank,
			  member_id, name, mobile, total_progress, longest_streak, current_streak, session_count
			FROM member_stats
			${search ? `WHERE (name ILIKE '%' || $1 || '%' OR mobile ILIKE '%' || $1 || '%')` : ''}
			ORDER BY rank
			LIMIT 200
		`, ...(search ? [search] : []));
	} else {
		rows = await prisma.$queryRawUnsafe<ProgressRow[]>(`
			${BASE_CTE}
			SELECT
			  ROW_NUMBER() OVER (ORDER BY total_progress DESC, longest_streak DESC)::int AS rank,
			  member_id, name, mobile, total_progress, longest_streak, current_streak, session_count
			FROM member_stats
			${search ? `WHERE (name ILIKE '%' || $1 || '%' OR mobile ILIKE '%' || $1 || '%')` : ''}
			ORDER BY rank
			LIMIT 200
		`, ...(search ? [search] : []));
	}

	return {
		board,
		search,
		rows: rows.map((r) => ({
			rank:          Number(r.rank),
			memberId:      r.member_id,
			name:          r.name,
			mobile:        r.mobile,
			totalProgress: Number(r.total_progress),
			longestStreak: Number(r.longest_streak),
			currentStreak: Number(r.current_streak),
			sessionCount:  Number(r.session_count),
			streakActive:  Number(r.current_streak) > 0,
		})),
		stats: {
			totalMembers,
			totalSessions,
			totalProgress: Number((totalProgress as { total: number }[])[0]?.total ?? 0),
			activeStreaks:  Number((activeStreaks as { cnt: number }[])[0]?.cnt ?? 0),
		},
	};
};
