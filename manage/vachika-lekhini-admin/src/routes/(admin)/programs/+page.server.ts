import type { PageServerLoad } from './$types';
import { prisma } from '$lib/server/prisma';
import { parseListQuery } from '$lib/server/list-query';
import { requireRole } from '$lib/server/auth';

const SORT_COLS = ['createdAt', 'startedAt', 'completedAt', 'totalWritings', 'targetWritings'] as const;

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'editor');
	const q = parseListQuery(event.url, { col: 'createdAt', dir: 'desc' }, SORT_COLS);
	const status = event.url.searchParams.get('status') ?? 'all'; // 'all' | 'active' | 'completed'

	const searchFilter = q.q
		? {
				OR: [
					{ member: { displayName: { contains: q.q, mode: 'insensitive' as const } } },
					{ mantra: { nameRoman: { contains: q.q, mode: 'insensitive' as const } } },
					{ mantra: { nameDevanagari: { contains: q.q, mode: 'insensitive' as const } } }
				]
			}
		: {};

	const statusFilter =
		status === 'completed'
			? { completedAt: { not: null } }
			: status === 'active'
				? { completedAt: null }
				: {};

	const where = { AND: [searchFilter, statusFilter] };

	const orderBy =
		q.sort.col === 'createdAt' || q.sort.col === 'startedAt' || q.sort.col === 'completedAt'
			? { [q.sort.col]: q.sort.dir }
			: { [q.sort.col]: q.sort.dir };

	const [rows, total] = await Promise.all([
		prisma.program.findMany({
			where,
			orderBy,
			skip: q.skip,
			take: q.take,
			include: {
				member: { select: { id: true, displayName: true, account: { select: { mobile: true } } } },
				mantra: { select: { id: true, nameRoman: true, nameDevanagari: true } },
				_count: { select: { sessions: true } }
			}
		}),
		prisma.program.count({ where })
	]);

	return {
		programs: rows,
		total,
		query: { q: q.q, page: q.page, pageSize: q.pageSize, sort: q.sort, status }
	};
};
