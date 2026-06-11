import type { PageServerLoad } from './$types';
import { prisma } from '$lib/server/prisma';
import { parseListQuery } from '$lib/server/list-query';
import { requireRole } from '$lib/server/auth';

const SORT_COLS = ['startedAt', 'durationSec', 'countAdded', 'createdAt'] as const;

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'editor');
	const q = parseListQuery(event.url, { col: 'startedAt', dir: 'desc' }, SORT_COLS);
	const modality = event.url.searchParams.get('modality') ?? '';

	const where: Record<string, unknown> = {};
	if (modality === 'voice' || modality === 'handwriting' || modality === 'manual') {
		where.modality = modality;
	}
	if (q.q) {
		where.OR = [
			{ member: { displayName: { contains: q.q, mode: 'insensitive' } } },
			{ program: { mantra: { nameRoman: { contains: q.q, mode: 'insensitive' } } } }
		];
	}

	const now = new Date();
	const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());

	const [rows, total, sessionsToday, totalChants, avgDuration] = await Promise.all([
		prisma.session.findMany({
			where,
			orderBy: { [q.sort.col]: q.sort.dir },
			skip: q.skip,
			take: q.take,
			include: {
				member: { select: { id: true, displayName: true } },
				program: { include: { mantra: { select: { nameRoman: true } } } }
			}
		}),
		prisma.session.count({ where }),
		prisma.session.count({ where: { startedAt: { gte: todayStart } } }),
		prisma.session.aggregate({ _sum: { countAdded: true } }),
		prisma.session.aggregate({ _avg: { durationSec: true } }),
	]);

	return {
		sessions: rows,
		total,
		modality,
		query: { q: q.q, page: q.page, pageSize: q.pageSize, sort: q.sort },
		summary: {
			sessionsToday,
			totalChants: totalChants._sum.countAdded ?? 0,
			avgDurationSec: Math.round(avgDuration._avg.durationSec ?? 0),
		},
	};
};
