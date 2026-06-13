/// Tiny helpers for building URL-driven UI state.
/// All admin filter/sort/page/modal state lives in query params so back-button
/// + shared links work.

export type QueryPatch = Record<string, string | number | null | undefined>;

/// Patch the current URL's query string with `patch`. Keys set to `null` or
/// empty string are removed. Returns a path+query suitable for `goto()`.
export function patchQuery(url: URL, patch: QueryPatch): string {
	const params = new URLSearchParams(url.searchParams);
	for (const [k, v] of Object.entries(patch)) {
		if (v === null || v === undefined || v === '') {
			params.delete(k);
		} else {
			params.set(k, String(v));
		}
	}
	const qs = params.toString();
	return `${url.pathname}${qs ? '?' + qs : ''}`;
}

export interface Sort {
	col: string;
	dir: 'asc' | 'desc';
}

/// Parse `?sort=col:dir`. Returns fallback if missing/invalid.
export function qSort(url: URL, fallback: Sort): Sort {
	const raw = url.searchParams.get('sort');
	if (!raw) return fallback;
	const [col, dir] = raw.split(':');
	if (!col || (dir !== 'asc' && dir !== 'desc')) return fallback;
	return { col, dir };
}

export function nextSortValue(current: Sort, col: string): string {
	const dir = current.col === col && current.dir === 'asc' ? 'desc' : 'asc';
	return `${col}:${dir}`;
}
