import type { PageServerLoad } from './$types';
import { prisma } from '$lib/server/prisma';
import { parseListQuery } from '$lib/server/list-query';
import { requireRole } from '$lib/server/auth';

const SORT_COLS = ['createdAt', 'expiresAt', 'attempts'] as const;

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'editor');
	const q = parseListQuery(event.url, { col: 'createdAt', dir: 'desc' }, SORT_COLS);

	const status = event.url.searchParams.get('status') ?? '';
	const now = new Date();

	const where: Record<string, unknown> = {};
	if (status === 'consumed') where.consumedAt = { not: null };
	if (status === 'expired') where.consumedAt = null, (where as Record<string, unknown>).expiresAt = { lt: now };
	if (status === 'active') where.consumedAt = null, (where as Record<string, unknown>).expiresAt = { gte: now };
	if (q.q) where.mobile = { contains: q.q };

	const [rows, total] = await Promise.all([
		prisma.otpChallenge.findMany({
			where,
			orderBy: { [q.sort.col]: q.sort.dir },
			skip: q.skip,
			take: q.take,
			include: { account: { select: { mobile: true, isBanned: true } } }
		}),
		prisma.otpChallenge.count({ where })
	]);

	return {
		challenges: rows,
		total,
		status,
		query: { q: q.q, page: q.page, pageSize: q.pageSize, sort: q.sort }
	};
};
