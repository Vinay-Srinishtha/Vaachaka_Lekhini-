import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';
import { fail } from '@sveltejs/kit';
import { parseListQuery } from '$lib/server/list-query';
import type { Actions, PageServerLoad } from './$types';

const SORT_COLS = ['createdAt', 'status', 'subject'] as const;

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const q = parseListQuery(event.url, { col: 'createdAt', dir: 'desc' }, SORT_COLS);
	const status = event.url.searchParams.get('status') ?? '';

	const where: Record<string, unknown> = { kind: 'report' };
	if (['open', 'resolved', 'dismissed'].includes(status)) where.status = status;
	if (q.q) {
		where.OR = [
			{ subject: { contains: q.q, mode: 'insensitive' } },
			{ mobile: { contains: q.q } },
			{ status: { contains: q.q, mode: 'insensitive' } }
		];
	}

	const [reports, total] = await Promise.all([
		prisma.supportReport.findMany({
			where,
			orderBy: { [q.sort.col]: q.sort.dir },
			skip: q.skip,
			take: q.take
		}),
		prisma.supportReport.count({ where })
	]);

	return {
		reports,
		total,
		status,
		query: { q: q.q, page: q.page, pageSize: q.pageSize }
	};
};

export const actions: Actions = {
	setStatus: async (event) => {
		requireRole(event, 'editor');
		const data = await event.request.formData();
		const id = data.get('id') as string;
		const status = data.get('status') as string;
		if (!id || !['open', 'resolved', 'dismissed'].includes(status)) {
			return fail(400, { error: 'Invalid input' });
		}
		await prisma.supportReport.update({ where: { id }, data: { status } });
		return { ok: true };
	}
};
