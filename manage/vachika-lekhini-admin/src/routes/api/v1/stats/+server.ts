import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';

/// GET /api/v1/stats — public community statistics.
/// No auth required — these are aggregate, non-personal figures.
///
/// Response:
///   global_chant_count  — sum of every Session.countAdded in the DB
///   member_count        — total registered members (profiles)
export const GET: RequestHandler = async () => {
	const [countAgg, memberCount] = await Promise.all([
		prisma.session.aggregate({ _sum: { countAdded: true } }),
		prisma.member.count()
	]);

	const globalChantCount = countAgg._sum.countAdded ?? 0;

	return snakeJson(
		{ global_chant_count: globalChantCount, member_count: memberCount },
		{
			headers: {
				// Cache for 30 s on the edge; clients may poll every ~60 s.
				'cache-control': 'public, max-age=30, stale-while-revalidate=120'
			}
		}
	);
};
