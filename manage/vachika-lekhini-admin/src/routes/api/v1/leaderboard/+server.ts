import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { requireAccount } from '$lib/server/user-auth';

/// GET /api/v1/leaderboard?sort=total_chants|streak[&mantra_id=<id>]  (Bearer)
///
/// Global leaderboard — every practising member from every non-banned account
/// is ranked individually (no one-per-family deduplication).
///
/// Totals and streaks come from pre-computed Program denormalised columns
/// (kept up to date by POST /api/v1/sessions).
///
/// When mantra_id is supplied only programs for that mantra count and members
/// who never practised it are excluded.
///
/// Response shape per entry:
///   id              member id
///   name            display name
///   total_chants    totalChants + totalWritings across (filtered) programs
///   longest_streak  best-ever consecutive-day run  (rank key when sort=streak)
///   current_streak  active consecutive-day run right now
///   streak_active   current_streak > 0 AND practised today-or-yesterday
///   is_self         true when the member belongs to the caller's account
export const GET: RequestHandler = async (event) => {
	const account   = await requireAccount(event);
	const sortParam  = event.url.searchParams.get('sort') ?? 'total_chants';
	const mantraSlug = event.url.searchParams.get('mantra_id') ?? null;
	const byStreak   = sortParam === 'streak';

	// Flutter passes the mantra slug (e.g. "sri_rama"), not the DB cuid.
	// Resolve it here so the JOIN on Program.mantraId works correctly.
	let mantraId: string | null = null;
	if (mantraSlug) {
		const mantra = await prisma.mantra.findUnique({
			where: { slug: mantraSlug },
			select: { id: true }
		});
		if (!mantra) {
			// Unknown slug → empty leaderboard rather than full platform scan.
			return snakeJson({ entries: [] }, { headers: { 'cache-control': 'private, max-age=60' } });
		}
		mantraId = mantra.id;
	}

	type Row = {
		id: string;
		name: string;
		total_progress: bigint | number;
		longest_streak: bigint | number;
		current_streak: bigint | number;
		last_active_date: Date | null;
		account_id: string;
	};

	// Two separate queries keep the SQL simple and avoids dynamic fragment
	// interpolation bugs.  Both share the same shape; only ORDER BY differs.
	const rows: Row[] = byStreak
		? mantraId
			? await prisma.$queryRaw<Row[]>`
				SELECT m.id,
				       m."displayName"                                              AS name,
				       COALESCE(SUM(p."totalChants" + p."totalWritings"), 0)::int   AS total_progress,
				       COALESCE(MAX(p."longestStreak"),  0)::int                    AS longest_streak,
				       COALESCE(MAX(p."currentStreak"),  0)::int                    AS current_streak,
				       MAX(p."lastActiveDate")                                       AS last_active_date,
				       m."accountId"                                                AS account_id
				FROM "Member" m
				JOIN "Account" a ON a.id = m."accountId" AND a."isBanned" = false
				JOIN "Program" p ON p."memberId" = m.id AND p."mantraId" = ${mantraId}
				GROUP BY m.id, m."displayName", m."accountId"
				ORDER BY longest_streak DESC, total_progress DESC
				LIMIT 50`
			: await prisma.$queryRaw<Row[]>`
				SELECT m.id,
				       m."displayName"                                              AS name,
				       COALESCE(SUM(p."totalChants" + p."totalWritings"), 0)::int   AS total_progress,
				       COALESCE(MAX(p."longestStreak"),  0)::int                    AS longest_streak,
				       COALESCE(MAX(p."currentStreak"),  0)::int                    AS current_streak,
				       MAX(p."lastActiveDate")                                       AS last_active_date,
				       m."accountId"                                                AS account_id
				FROM "Member" m
				JOIN "Account" a ON a.id = m."accountId" AND a."isBanned" = false
				LEFT JOIN "Program" p ON p."memberId" = m.id
				GROUP BY m.id, m."displayName", m."accountId"
				ORDER BY longest_streak DESC, total_progress DESC
				LIMIT 50`
		: mantraId
			? await prisma.$queryRaw<Row[]>`
				SELECT m.id,
				       m."displayName"                                              AS name,
				       COALESCE(SUM(p."totalChants" + p."totalWritings"), 0)::int   AS total_progress,
				       COALESCE(MAX(p."longestStreak"),  0)::int                    AS longest_streak,
				       COALESCE(MAX(p."currentStreak"),  0)::int                    AS current_streak,
				       MAX(p."lastActiveDate")                                       AS last_active_date,
				       m."accountId"                                                AS account_id
				FROM "Member" m
				JOIN "Account" a ON a.id = m."accountId" AND a."isBanned" = false
				JOIN "Program" p ON p."memberId" = m.id AND p."mantraId" = ${mantraId}
				GROUP BY m.id, m."displayName", m."accountId"
				ORDER BY total_progress DESC, longest_streak DESC
				LIMIT 50`
			: await prisma.$queryRaw<Row[]>`
				SELECT m.id,
				       m."displayName"                                              AS name,
				       COALESCE(SUM(p."totalChants" + p."totalWritings"), 0)::int   AS total_progress,
				       COALESCE(MAX(p."longestStreak"),  0)::int                    AS longest_streak,
				       COALESCE(MAX(p."currentStreak"),  0)::int                    AS current_streak,
				       MAX(p."lastActiveDate")                                       AS last_active_date,
				       m."accountId"                                                AS account_id
				FROM "Member" m
				JOIN "Account" a ON a.id = m."accountId" AND a."isBanned" = false
				LEFT JOIN "Program" p ON p."memberId" = m.id
				GROUP BY m.id, m."displayName", m."accountId"
				ORDER BY total_progress DESC, longest_streak DESC
				LIMIT 50`;

	const todayUtc = new Date();
	todayUtc.setUTCHours(0, 0, 0, 0);
	const yesterdayUtc = new Date(todayUtc.getTime() - 86_400_000);

	const entries = rows.map((r) => {
		const lastDate = r.last_active_date ? new Date(r.last_active_date) : null;
		if (lastDate) lastDate.setUTCHours(0, 0, 0, 0);
		const practicedRecently =
			lastDate !== null &&
			(lastDate.getTime() === todayUtc.getTime() ||
				lastDate.getTime() === yesterdayUtc.getTime());
		const currentStreak = Number(r.current_streak);
		return {
			id:             r.id,
			name:           r.name,
			total_chants:   Number(r.total_progress),
			longest_streak: Number(r.longest_streak),
			current_streak: currentStreak,
			streak_active:  currentStreak > 0 && practicedRecently,
			is_self:        r.account_id === account.id
		};
	});

	return snakeJson(
		{ entries },
		{ headers: { 'cache-control': 'private, max-age=60' } }
	);
};
