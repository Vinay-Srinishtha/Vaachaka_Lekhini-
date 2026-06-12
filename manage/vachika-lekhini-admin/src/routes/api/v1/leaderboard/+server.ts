import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { requireAccount } from '$lib/server/user-auth';

/// GET /api/v1/leaderboard?sort=total_chants|streak  (Bearer)
/// Returns members ranked by total chants or longest streak. Capped at 50.
///
/// Each entry:
///   id           — member id
///   name         — display name
///   total_chants — sum of all Session.countAdded for that member
///   streak_days  — highest Program.currentStreak across all member programs
///   is_self      — true if the member belongs to the calling account
export const GET: RequestHandler = async (event) => {
	const account = await requireAccount(event);
	const sortParam = event.url.searchParams.get('sort') ?? 'total_chants';
	const byStreak = sortParam === 'streak';

	// Single aggregation query — DB does all grouping, sorting, and limiting.
	// Much faster than pulling 200 rows with nested relations into JS.
	type Row = { id: string; name: string; total_chants: number; streak_days: number; account_id: string };
	const rows = byStreak
		? await prisma.$queryRaw<Row[]>`
			SELECT m.id,
			       m."displayName"        AS name,
			       COALESCE(SUM(s."countAdded"), 0)::int AS total_chants,
			       COALESCE(MAX(p."currentStreak"), 0)::int AS streak_days,
			       m."accountId"          AS account_id
			FROM "Member" m
			LEFT JOIN "Program" p ON p."memberId" = m.id
			LEFT JOIN "Session" s ON s."memberId" = m.id
			GROUP BY m.id, m."displayName", m."accountId"
			ORDER BY streak_days DESC, total_chants DESC
			LIMIT 50`
		: await prisma.$queryRaw<Row[]>`
			SELECT m.id,
			       m."displayName"        AS name,
			       COALESCE(SUM(s."countAdded"), 0)::int AS total_chants,
			       COALESCE(MAX(p."currentStreak"), 0)::int AS streak_days,
			       m."accountId"          AS account_id
			FROM "Member" m
			LEFT JOIN "Program" p ON p."memberId" = m.id
			LEFT JOIN "Session" s ON s."memberId" = m.id
			GROUP BY m.id, m."displayName", m."accountId"
			ORDER BY total_chants DESC, streak_days DESC
			LIMIT 50`;

	const entries = rows.map((r) => ({
		id: r.id,
		name: r.name,
		total_chants: Number(r.total_chants),
		streak_days: Number(r.streak_days),
		is_self: r.account_id === account.id
	}));

	return snakeJson(
		{ entries },
		{ headers: { 'cache-control': 'private, max-age=60' } }
	);
};
