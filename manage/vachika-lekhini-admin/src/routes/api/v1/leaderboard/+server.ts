import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { requireAccount } from '$lib/server/user-auth';

/// GET /api/v1/leaderboard?sort=total_chants|streak  (Bearer)
/// Returns members ranked by totalProgress (chants + writings) or current streak.
/// Capped at 50. Uses pre-computed Program totals — authoritative and fast.
///
/// Each entry:
///   id           — member id
///   name         — display name
///   total_chants — totalChants + totalWritings (combined totalProgress)
///   streak_days  — highest Program.currentStreak across all member programs
///   is_self      — true if the member belongs to the calling account
export const GET: RequestHandler = async (event) => {
	const account = await requireAccount(event);
	const sortParam = event.url.searchParams.get('sort') ?? 'total_chants';
	const byStreak = sortParam === 'streak';

	// Aggregate per member from pre-computed Program totals (server-authoritative).
	// One row per account — ROW_NUMBER() keeps the best-scoring member per account.
	// last_active_date: most recent session date across all programs for the member.
	// streak_active = current_streak > 0 AND last practice was today or yesterday
	// (i.e. the streak has not yet been broken by a missed day).
	type Row = { id: string; name: string; total_progress: number; streak_days: number; current_streak: number; account_id: string; last_active_date: Date | null };
	const rows = byStreak
		? await prisma.$queryRaw<Row[]>`
			WITH agg AS (
			  SELECT m.id,
			         m."displayName"                                              AS name,
			         COALESCE(SUM(p."totalChants" + p."totalWritings"), 0)::int   AS total_progress,
			         COALESCE(MAX(p."longestStreak"), 0)::int                     AS streak_days,
			         COALESCE(MAX(p."currentStreak"), 0)::int                     AS current_streak,
			         MAX(p."lastActiveDate")                                       AS last_active_date,
			         m."accountId"                                                AS account_id
			  FROM "Member" m
			  JOIN "Account" a2 ON a2.id = m."accountId" AND a2."isBanned" = false
			  LEFT JOIN "Program" p ON p."memberId" = m.id
			  GROUP BY m.id, m."displayName", m."accountId"
			),
			ranked AS (
			  SELECT *, ROW_NUMBER() OVER (
			    PARTITION BY account_id
			    ORDER BY streak_days DESC, total_progress DESC
			  ) AS rn
			  FROM agg
			)
			SELECT id, name, total_progress, streak_days, current_streak, last_active_date, account_id
			FROM ranked
			WHERE rn = 1
			ORDER BY streak_days DESC, total_progress DESC
			LIMIT 50`
		: await prisma.$queryRaw<Row[]>`
			WITH agg AS (
			  SELECT m.id,
			         m."displayName"                                              AS name,
			         COALESCE(SUM(p."totalChants" + p."totalWritings"), 0)::int   AS total_progress,
			         COALESCE(MAX(p."longestStreak"), 0)::int                     AS streak_days,
			         COALESCE(MAX(p."currentStreak"), 0)::int                     AS current_streak,
			         MAX(p."lastActiveDate")                                       AS last_active_date,
			         m."accountId"                                                AS account_id
			  FROM "Member" m
			  JOIN "Account" a2 ON a2.id = m."accountId" AND a2."isBanned" = false
			  LEFT JOIN "Program" p ON p."memberId" = m.id
			  GROUP BY m.id, m."displayName", m."accountId"
			),
			ranked AS (
			  SELECT *, ROW_NUMBER() OVER (
			    PARTITION BY account_id
			    ORDER BY total_progress DESC, streak_days DESC
			  ) AS rn
			  FROM agg
			)
			SELECT id, name, total_progress, streak_days, current_streak, last_active_date, account_id
			FROM ranked
			WHERE rn = 1
			ORDER BY total_progress DESC, streak_days DESC
			LIMIT 50`;

	const todayUtc = new Date();
	todayUtc.setUTCHours(0, 0, 0, 0);
	const yesterdayUtc = new Date(todayUtc.getTime() - 86_400_000);

	const entries = rows.map((r) => {
		const lastDate = r.last_active_date ? new Date(r.last_active_date) : null;
		if (lastDate) lastDate.setUTCHours(0, 0, 0, 0);
		const practicedTodayOrYesterday =
			lastDate !== null &&
			(lastDate.getTime() === todayUtc.getTime() ||
				lastDate.getTime() === yesterdayUtc.getTime());
		return {
			id: r.id,
			name: r.name,
			total_chants: Number(r.total_progress),
			streak_days: Number(r.streak_days),
			streak_active: Number(r.current_streak) > 0 && practicedTodayOrYesterday,
			is_self: r.account_id === account.id
		};
	});

	return snakeJson(
		{ entries },
		{ headers: { 'cache-control': 'private, max-age=60' } }
	);
};
