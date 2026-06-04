<script lang="ts">
	import { ChevronLeft, ChevronRight } from '@lucide/svelte';
	import { page } from '$app/state';
	import { patchQuery } from '$lib/url';

	interface Props {
		total: number;
		pageSize: number;
		currentPage: number;
	}

	let { total, pageSize, currentPage }: Props = $props();

	const totalPages = $derived(Math.max(1, Math.ceil(total / pageSize)));
	const startIdx = $derived(total === 0 ? 0 : (currentPage - 1) * pageSize + 1);
	const endIdx = $derived(Math.min(total, currentPage * pageSize));

	function hrefForPage(p: number): string {
		return patchQuery(page.url, { page: p === 1 ? null : p });
	}
</script>

<div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 px-4 py-3 border-t border-gray-100">
	<div class="text-xs text-gray-500">
		{#if total === 0}
			No results
		{:else}
			Showing <span class="font-medium text-gray-700">{startIdx}–{endIdx}</span> of
			<span class="font-medium text-gray-700">{total}</span>
		{/if}
	</div>
	<div class="flex items-center gap-1">
		<a
			href={hrefForPage(Math.max(1, currentPage - 1))}
			class="btn-secondary !px-2 !py-1.5 {currentPage <= 1 ? 'pointer-events-none opacity-50' : ''}"
			aria-label="Previous page"
		>
			<ChevronLeft size={14} />
		</a>
		<span class="text-xs text-gray-600 px-2">
			Page <span class="font-medium text-gray-900">{currentPage}</span> / {totalPages}
		</span>
		<a
			href={hrefForPage(Math.min(totalPages, currentPage + 1))}
			class="btn-secondary !px-2 !py-1.5 {currentPage >= totalPages
				? 'pointer-events-none opacity-50'
				: ''}"
			aria-label="Next page"
		>
			<ChevronRight size={14} />
		</a>
	</div>
</div>
