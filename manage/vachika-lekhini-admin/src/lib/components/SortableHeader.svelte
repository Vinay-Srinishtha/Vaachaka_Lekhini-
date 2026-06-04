<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { patchQuery, qSort, nextSortValue, type Sort } from '$lib/url';
	import { ArrowUp, ArrowDown, ArrowUpDown } from '@lucide/svelte';

	interface Props {
		col: string;
		label: string;
		defaultSort: Sort;
		align?: 'left' | 'right' | 'center';
	}

	let { col, label, defaultSort, align = 'left' }: Props = $props();

	const sort = $derived(qSort(page.url, defaultSort));
	const active = $derived(sort.col === col);

	function activate() {
		goto(patchQuery(page.url, { sort: nextSortValue(sort, col), page: null }), {
			keepFocus: true,
			noScroll: true,
			replaceState: true
		});
	}
</script>

<button
	type="button"
	onclick={activate}
	class="inline-flex items-center gap-1 hover:text-gray-900 transition {active
		? 'text-gray-900'
		: 'text-gray-600'} {align === 'right'
		? 'justify-end w-full'
		: align === 'center'
			? 'justify-center w-full'
			: ''}"
>
	{label}
	{#if !active}
		<ArrowUpDown size={12} class="text-gray-400" />
	{:else if sort.dir === 'asc'}
		<ArrowUp size={12} />
	{:else}
		<ArrowDown size={12} />
	{/if}
</button>
