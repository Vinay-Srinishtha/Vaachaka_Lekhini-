import type { LayoutServerLoad } from './$types';
import { listMantras, MANTRA_SORT_COLS } from '$lib/server/mantras';
import { parseListQuery } from '$lib/server/list-query';
import { requireRole } from '$lib/server/auth';

/// Layout load: list + total. Nested routes (/new, /:id/edit) inherit this
/// so the list stays mounted while modals overlay it.
export const load: LayoutServerLoad = async (event) => {
	requireRole(event, 'viewer');

	const query = parseListQuery(event.url, { col: 'sortOrder', dir: 'asc' }, MANTRA_SORT_COLS);
	const { rows, total } = await listMantras({
		q: query.q,
		skip: query.skip,
		take: query.take,
		sort: query.sort
	});

	return {
		mantras: rows,
		total,
		query: { q: query.q, page: query.page, pageSize: query.pageSize, sort: query.sort }
	};
};
