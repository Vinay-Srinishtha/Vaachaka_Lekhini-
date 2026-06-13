import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';

/// GET /api/v1/stats?mantra_id=<slug>  — public community statistics.
/// No auth required — these are aggregate, non-personal figures.
///
/// When mantra_id is supplied the counts are scoped to that mantra:
///   global_chant_count — sum of Session.countAdded for programs of this mantra
///   member_count       — distinct accounts that have a program for this mantra
///
/// Without mantra_id both fields cover the entire platform.
export const GET: RequestHandler = async ({ url }) => {
	const mantraId = url.searchParams.get('mantra_id') ?? undefined;

	const [countAgg, memberCount] = await Promise.all([
		// Total chants — optionally scoped to one mantra via program join
		prisma.session.aggregate({
			where: mantraId ? { program: { mantraId } } : undefined,
			_sum: { countAdded: true }
		}),
		// Unique people practising this mantra (distinct accountId, not member rows)
		mantraId
			? prisma.program
					.findMany({
						where: { mantraId },
						select: { member: { select: { accountId: true } } },
						distinct: ['memberId']
					})
					.then((rows) => new Set(rows.map((r) => r.member.accountId)).size)
			: prisma.account.count()
	]);

	const globalChantCount = countAgg._sum.countAdded ?? 0;

	return snakeJson(
		{ global_chant_count: globalChantCount, member_count: memberCount },
		{
			headers: {
				// Cache 30 s on edge; Flutter polls every ~60 s.
				'cache-control': 'public, max-age=30, stale-while-revalidate=120'
			}
		}
	);
};
