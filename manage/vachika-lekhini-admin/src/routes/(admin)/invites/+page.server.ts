import type { PageServerLoad } from './$types';
import { prisma } from '$lib/server/prisma';
import { parseListQuery } from '$lib/server/list-query';
import { requireRole } from '$lib/server/auth';

const SORT_COLS = ['createdAt', 'acceptedAt', 'status'] as const;

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'editor');
	const q = parseListQuery(event.url, { col: 'createdAt', dir: 'desc' }, SORT_COLS);
	const status = event.url.searchParams.get('status') ?? '';

	const where: Record<string, unknown> = {};
	if (['pending', 'accepted', 'expired'].includes(status)) where.status = status;
	if (q.q) {
		where.OR = [
			{ inviter: { mobile: { contains: q.q } } },
			{ inviteeMobile: { contains: q.q } }
		];
	}

	const [rows, total] = await Promise.all([
		prisma.invite.findMany({
			where,
			orderBy: { [q.sort.col]: q.sort.dir },
			skip: q.skip,
			take: q.take,
			include: {
				inviter: { select: { mobile: true } },
				invitee: { select: { mobile: true } }
			}
		}),
		prisma.invite.count({ where })
	]);

	return {
		invites: rows,
		total,
		status,
		query: { q: q.q, page: q.page, pageSize: q.pageSize, sort: q.sort }
	};
};
