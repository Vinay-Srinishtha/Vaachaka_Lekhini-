import type { LayoutServerLoad } from './$types';
import { listFlags, FLAG_SORT_COLS } from '$lib/server/flags';
import { parseListQuery } from '$lib/server/list-query';
import { requireRole } from '$lib/server/auth';

export const load: LayoutServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const query = parseListQuery(event.url, { col: 'key', dir: 'asc' }, FLAG_SORT_COLS);
	const { rows, total } = await listFlags({
		q: query.q,
		skip: query.skip,
		take: query.take,
		sort: query.sort
	});
	return {
		flags: rows,
		total,
		query: { q: query.q, page: query.page, pageSize: query.pageSize, sort: query.sort }
	};
};
