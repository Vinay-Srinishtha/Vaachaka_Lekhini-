<script lang="ts" generics="Row">
	import type { Snippet } from 'svelte';
	import SortableHeader from './SortableHeader.svelte';
	import Pagination from './Pagination.svelte';
	import SearchInput from './SearchInput.svelte';
	import type { Sort } from '$lib/url';
	import type { Column } from './DataTable.types';

	interface Props {
		columns: Column[];
		rows: Row[];
		total: number;
		pageSize: number;
		currentPage: number;
		defaultSort: Sort;
		emptyTitle?: string;
		emptyHint?: string;
		searchable?: boolean;
		searchPlaceholder?: string;
		toolbar?: Snippet;
		row: Snippet<[Row]>;
	}

	let {
		columns,
		rows,
		total,
		pageSize,
		currentPage,
		defaultSort,
		emptyTitle = 'No results',
		emptyHint = '',
		searchable = true,
		searchPlaceholder = 'Search…',
		toolbar,
		row
	}: Props = $props();

	const hiddenCls: Record<NonNullable<Column['hidden']>, string> = {
		sm: 'hidden sm:table-cell',
		md: 'hidden md:table-cell',
		lg: 'hidden lg:table-cell'
	};

	const alignCls: Record<NonNullable<Column['align']>, string> = {
		left: 'text-left',
		right: 'text-right',
		center: 'text-center'
	};
</script>

<div class="card overflow-hidden">
	{#if searchable || toolbar}
		<div class="flex flex-col sm:flex-row sm:items-center gap-3 px-4 py-3 border-b border-gray-100">
			{#if searchable}
				<SearchInput placeholder={searchPlaceholder} />
			{/if}
			{#if toolbar}
				<div class="sm:ml-auto flex items-center gap-2">
					{@render toolbar()}
				</div>
			{/if}
		</div>
	{/if}

	<div class="overflow-x-auto">
		<table class="w-full text-sm">
			<thead class="bg-gray-50 text-gray-600 text-xs uppercase tracking-wide">
				<tr>
					{#each columns as col (col.key)}
						<th
							class="px-4 py-3 font-semibold {alignCls[col.align ?? 'left']} {col.hidden
								? hiddenCls[col.hidden]
								: ''} {col.thClass ?? ''}"
						>
							{#if col.sortable}
								<SortableHeader
									col={col.key}
									label={col.label}
									{defaultSort}
									align={col.align ?? 'left'}
								/>
							{:else}
								{col.label}
							{/if}
						</th>
					{/each}
				</tr>
			</thead>
			<tbody class="divide-y divide-gray-100">
				{#each rows as r, i (i)}
					{@render row(r)}
				{:else}
					<tr>
						<td colspan={columns.length} class="text-center py-12">
							<div class="text-sm font-medium text-gray-700">{emptyTitle}</div>
							{#if emptyHint}
								<div class="text-xs text-gray-500 mt-1">{emptyHint}</div>
							{/if}
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>

	<Pagination {total} {pageSize} {currentPage} />
</div>
