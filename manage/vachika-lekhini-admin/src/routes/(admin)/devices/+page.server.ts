import type { PageServerLoad } from './$types';
import { prisma } from '$lib/server/prisma';
import { parseListQuery } from '$lib/server/list-query';
import { requireRole } from '$lib/server/auth';

const SORT_COLS = ['lastSeenAt', 'createdAt'] as const;

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'editor');
	const q = parseListQuery(event.url, { col: 'lastSeenAt', dir: 'desc' }, SORT_COLS);
	const platform = event.url.searchParams.get('platform') ?? '';

	const where: Record<string, unknown> = {};
	if (['android', 'ios', 'web'].includes(platform)) where.platform = platform;
	if (q.q) {
		where.OR = [
			{ account: { mobile: { contains: q.q } } },
			{ appVersion: { contains: q.q } }
		];
	}

	const [rows, total, revokedCount] = await Promise.all([
		prisma.device.findMany({
			where,
			orderBy: { [q.sort.col]: q.sort.dir },
			skip: q.skip,
			take: q.take,
			include: {
				account: { select: { mobile: true, isBanned: true } }
			}
		}),
		prisma.device.count({ where }),
		prisma.revokedToken.count({ where: { expiresAt: { gte: new Date() } } })
	]);

	return {
		devices: rows,
		total,
		revokedCount,
		platform,
		query: { q: q.q, page: q.page, pageSize: q.pageSize, sort: q.sort }
	};
};
