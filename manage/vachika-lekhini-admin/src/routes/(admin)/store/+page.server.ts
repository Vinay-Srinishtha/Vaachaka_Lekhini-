import type { Actions, PageServerLoad } from './$types';
import { error, fail, redirect } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';
import { parseListQuery } from '$lib/server/list-query';
import { patchQuery } from '$lib/url';

const SORT_COLS = ['sortOrder', 'pointsCost', 'name', 'createdAt'] as const;

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const q = parseListQuery(event.url, { col: 'sortOrder', dir: 'asc' }, SORT_COLS);

	const where = q.q
		? {
				OR: [
					{ name: { contains: q.q, mode: 'insensitive' as const } },
					{ slug: { contains: q.q, mode: 'insensitive' as const } },
					{ description: { contains: q.q, mode: 'insensitive' as const } }
				]
			}
		: {};

	const [items, total] = await Promise.all([
		prisma.storeItem.findMany({
			where,
			orderBy: { [q.sort.col]: q.sort.dir },
			skip: q.skip,
			take: q.take
		}),
		prisma.storeItem.count({ where })
	]);

	return { items, total, query: { q: q.q, page: q.page, pageSize: q.pageSize } };
};

export const actions: Actions = {
	toggleActive: async (event) => {
		requireRole(event, 'editor');
		const data = await event.request.formData();
		const id = String(data.get('id') ?? '');
		if (!id) return fail(400, { error: 'Missing id' });
		const current = await prisma.storeItem.findUnique({
			where: { id },
			select: { isActive: true }
		});
		if (!current) throw error(404, 'Store item not found');
		await prisma.storeItem.update({ where: { id }, data: { isActive: !current.isActive } });
		return { ok: true };
	},

	delete: async (event) => {
		requireRole(event, 'editor');
		const data = await event.request.formData();
		const id = String(data.get('id') ?? '');
		if (!id) return fail(400, { error: 'Missing id' });
		await prisma.storeItem.delete({ where: { id } });
		throw redirect(303, patchQuery(event.url, { delete: null }));
	}
};
