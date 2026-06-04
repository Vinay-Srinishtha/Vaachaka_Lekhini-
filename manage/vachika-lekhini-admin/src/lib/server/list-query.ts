/// Shared parsing of list URL params (`q`, `sort`, `page`, `pageSize`).
/// Every list page is URL-driven — same shape for every resource so the
/// DataTable component stays generic.

import type { Sort } from '$lib/url';

export const DEFAULT_PAGE_SIZE = 20;

export interface ListQuery {
	q: string;
	page: number;
	pageSize: number;
	sort: Sort;
	skip: number;
	take: number;
}

export function parseListQuery(
	url: URL,
	defaultSort: Sort,
	allowedSortCols: readonly string[]
): ListQuery {
	const q = (url.searchParams.get('q') ?? '').trim();
	const page = clampInt(url.searchParams.get('page'), 1, 1, 100_000);
	const pageSize = clampInt(url.searchParams.get('pageSize'), DEFAULT_PAGE_SIZE, 1, 200);

	let sort: Sort = defaultSort;
	const rawSort = url.searchParams.get('sort');
	if (rawSort) {
		const [col, dir] = rawSort.split(':');
		if (allowedSortCols.includes(col) && (dir === 'asc' || dir === 'desc')) {
			sort = { col, dir };
		}
	}
	return {
		q,
		page,
		pageSize,
		sort,
		skip: (page - 1) * pageSize,
		take: pageSize
	};
}

function clampInt(raw: string | null, fallback: number, min: number, max: number): number {
	if (raw === null) return fallback;
	const n = parseInt(raw, 10);
	if (!Number.isFinite(n)) return fallback;
	return Math.max(min, Math.min(max, n));
}
