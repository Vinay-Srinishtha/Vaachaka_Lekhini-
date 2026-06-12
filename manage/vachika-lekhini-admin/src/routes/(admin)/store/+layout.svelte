<script lang="ts">
	import { Plus, Edit2, Trash2, Eye, EyeOff, Image as ImageIcon } from '@lucide/svelte';
	import PageHeader from '$lib/components/PageHeader.svelte';
	import DataTable from '$lib/components/DataTable.svelte';
	import type { Column } from '$lib/components/DataTable.types';
	import { hasRole } from '$lib/roles';
	import { enhance } from '$app/forms';
	import { page } from '$app/state';
	import { toasts } from '$lib/stores/toast';

	let { data, children } = $props();
	const canEdit = $derived(hasRole(data.admin?.role, 'editor'));

	const columns: Column[] = [
		{ key: 'name', label: 'Item', sortable: true },
		{ key: 'pointsCost', label: 'Cost', sortable: true, align: 'right' },
		{ key: 'stock', label: 'Stock', align: 'right', hidden: 'md' },
		{ key: 'isActive', label: 'Status', sortable: true },
		{ key: 'sortOrder', label: 'Order', sortable: true, hidden: 'lg', align: 'right' },
		{ key: 'actions', label: '', align: 'right' }
	];

	function fmtNum(n: number) {
		return n.toLocaleString();
	}
</script>

<PageHeader title="Store" subtitle="Rewards items shown in the Flutter Store tab">
	{#snippet actions()}
		{#if canEdit}
			<a href="/store/new" class="btn-primary" data-sveltekit-noscroll>
				<Plus size={16} /> New item
			</a>
		{/if}
	{/snippet}
</PageHeader>

<DataTable
	{columns}
	rows={data.items}
	total={data.total}
	currentPage={data.query.page}
	pageSize={data.query.pageSize}
	defaultSort={{ col: 'sortOrder', dir: 'asc' }}
	searchPlaceholder="Search by name, slug or description…"
	emptyTitle={data.query.q ? `No items match "${data.query.q}"` : 'No store items yet'}
	emptyHint={canEdit && !data.query.q ? 'Click "New item" to add the first one.' : ''}
>
	{#snippet row(it)}
		<tr class="hover:bg-gray-50">
			<td class="px-4 py-3">
				<div class="flex items-center gap-3">
					<div class="w-10 h-10 rounded-lg bg-gray-100 overflow-hidden grid place-items-center text-gray-400 shrink-0">
						{#if it.imageUrl}
							<img src={it.imageUrl} alt="" class="w-full h-full object-cover" />
						{:else}
							<ImageIcon size={16} />
						{/if}
					</div>
					<div class="min-w-0">
						<div class="font-medium text-gray-900 truncate">{it.name}</div>
						<div class="text-xs text-gray-500 truncate"><code>{it.slug}</code></div>
					</div>
				</div>
			</td>
			<td class="px-4 py-3 text-right tabular-nums text-gray-700 font-medium">{fmtNum(it.pointsCost)}</td>
			<td class="px-4 py-3 text-right tabular-nums text-gray-600 hidden md:table-cell">
				{it.stock === null ? '∞' : fmtNum(it.stock)}
			</td>
			<td class="px-4 py-3">
				{#if it.isActive}
					<span class="chip bg-green-100 text-green-700">active</span>
				{:else}
					<span class="chip bg-gray-100 text-gray-600">hidden</span>
				{/if}
			</td>
			<td class="px-4 py-3 hidden lg:table-cell text-right text-gray-600">{it.sortOrder}</td>
			<td class="px-4 py-3">
				<div class="flex items-center gap-1 justify-end">
					{#if canEdit}
						<form method="POST" action="/store?/toggleActive" use:enhance={() => {
								const wasActive = it.isActive;
								return async ({ result, update }) => {
									await update();
									if (result.type === 'success') toasts.show(wasActive ? 'Item hidden from store' : 'Item now visible in store');
								};
							}}>
							<input type="hidden" name="id" value={it.id} />
							<button class="p-2 rounded hover:bg-gray-100 text-gray-500" title={it.isActive ? 'Hide from app' : 'Show in app'}>
								{#if it.isActive}<EyeOff size={16} />{:else}<Eye size={16} />{/if}
							</button>
						</form>
					{/if}
					<a
						href={`/store/${it.id}/edit?${page.url.searchParams.toString()}`}
						class="p-2 rounded hover:bg-gray-100 text-gray-500"
						title="Edit"
						data-sveltekit-noscroll
					>
						<Edit2 size={16} />
					</a>
					{#if canEdit}
						<a
							href={`?${(() => {
								const p = new URLSearchParams(page.url.searchParams);
								p.set('delete', it.id);
								return p.toString();
							})()}`}
							class="p-2 rounded hover:bg-red-50 text-red-600"
							title="Delete"
							data-sveltekit-noscroll
							data-sveltekit-replacestate
						>
							<Trash2 size={16} />
						</a>
					{/if}
				</div>
			</td>
		</tr>
	{/snippet}
</DataTable>

{@render children()}
