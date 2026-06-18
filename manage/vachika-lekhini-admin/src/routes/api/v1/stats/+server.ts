import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';

/// GET /api/v1/stats?mantra_id=<slug>  — public community statistics.
/// No auth required — these are aggregate, non-personal figures.
///
/// `mantra_id` is a mantra **slug** (e.g. "sri_rama") — NOT a DB cuid.
/// The slug is resolved to the DB id before querying Program rows.
///
/// When mantra_id is supplied the counts are scoped to that mantra:
///   global_chant_count — sum of Session.countAdded for programs of this mantra
///   member_count       — distinct accounts that have a program for this mantra
///
/// Without mantra_id both fields cover the entire platform.
export const GET: RequestHandler = async ({ url }) => {
	const mantraSlug = url.searchParams.get('mantra_id') ?? undefined;

	// Resolve slug → DB cuid so Program.mantraId comparisons are correct.
	let resolvedMantraId: string | undefined;
	if (mantraSlug) {
		const mantra = await prisma.mantra.findUnique({
			where: { slug: mantraSlug },
			select: { id: true }
		});
		resolvedMantraId = mantra?.id ?? undefined;
		// Unknown slug — return zeros rather than scanning the whole platform.
		if (!resolvedMantraId) {
			return snakeJson(
				{ global_chant_count: 0, member_count: 0 },
				{ headers: { 'cache-control': 'public, max-age=30, stale-while-revalidate=120' } }
			);
		}
	}

	const [countAgg, memberCount] = await Promise.all([
		// Total chants — optionally scoped to one mantra via program join.
		prisma.session.aggregate({
			where: resolvedMantraId ? { program: { mantraId: resolvedMantraId } } : undefined,
			_sum: { countAdded: true }
		}),
		// Unique accounts practising this mantra (not member rows).
		resolvedMantraId
			? prisma.program
					.findMany({
						where: { mantraId: resolvedMantraId },
						select: { member: { select: { accountId: true } } },
						distinct: ['memberId']
					})
					.then((rows) => new Set(rows.map((r) => r.member.accountId)).size)
			: prisma.account.count()
	]);

	return snakeJson(
		{
			global_chant_count: countAgg._sum.countAdded ?? 0,
			member_count: memberCount
		},
		{
			headers: {
				'cache-control': 'public, max-age=30, stale-while-revalidate=120'
			}
		}
	);
};
