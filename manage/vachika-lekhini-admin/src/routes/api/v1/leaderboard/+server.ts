import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { requireAccount } from '$lib/server/user-auth';

/// GET /api/v1/leaderboard?sort=total_chants|streak  (Bearer)
/// Returns the calling user's own members + all other members in the DB,
/// ranked by total chants or longest streak. Capped at 50 entries.
///
/// Each entry:
///   id           — member id
///   name         — display name
///   total_chants — sum of all Session.countAdded for that member
///   streak_days  — highest Program.currentStreak across all member programs
///                  (server-authoritative consecutive-day streak, not calendar days)
///   is_self      — true if the member belongs to the calling account
export const GET: RequestHandler = async (event) => {
	const account = await requireAccount(event);
	const sortParam = event.url.searchParams.get('sort') ?? 'total_chants';
	const byStreak = sortParam === 'streak';

	// Aggregate per-member stats in one query.
	const rows = await prisma.member.findMany({
		select: {
			id: true,
			displayName: true,
			accountId: true,
			programs: {
				select: {
					currentStreak: true,
					sessions: { select: { countAdded: true } }
				}
			}
		},
		take: 200 // pull top pool then sort in JS
	});

	const entries = rows.map((m) => {
		const totalChants = m.programs
			.flatMap((p) => p.sessions)
			.reduce((s, sess) => s + sess.countAdded, 0);
		// currentStreak is a server-computed consecutive-day streak stored on
		// the Program row. daysElapsed is a Flutter client-side computed getter
		// that is not a Prisma field — it would always resolve to undefined here.
		const streakDays = m.programs.reduce(
			(max, p) => (p.currentStreak > max ? p.currentStreak : max),
			0
		);
		return {
			id: m.id,
			name: m.displayName,
			total_chants: totalChants,
			streak_days: streakDays,
			is_self: m.accountId === account.id
		};
	});

	entries.sort((a, b) =>
		byStreak
			? b.streak_days - a.streak_days
			: b.total_chants - a.total_chants
	);

	return snakeJson(
		{ entries: entries.slice(0, 50) },
		{ headers: { 'cache-control': 'private, max-age=30' } }
	);
};
