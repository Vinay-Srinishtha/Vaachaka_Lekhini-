import type { LayoutServerLoad } from './$types';
import { listStoreItems, STORE_SORT_COLS } from '$lib/server/store';
import { parseListQuery } from '$lib/server/list-query';
import { requireRole } from '$lib/server/auth';

export const load: LayoutServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const query = parseListQuery(event.url, { col: 'sortOrder', dir: 'asc' }, STORE_SORT_COLS);
	const { rows, total } = await listStoreItems({
		q: query.q,
		skip: query.skip,
		take: query.take,
		sort: query.sort
	});
	return {
		items: rows,
		total,
		query: { q: query.q, page: query.page, pageSize: query.pageSize, sort: query.sort }
	};
};
