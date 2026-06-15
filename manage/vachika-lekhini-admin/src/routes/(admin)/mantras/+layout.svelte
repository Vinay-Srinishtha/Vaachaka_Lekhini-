<script lang="ts">
	import { Plus, Edit2, Trash2, Eye, EyeOff } from '@lucide/svelte';
	import PageHeader from '$lib/components/PageHeader.svelte';
	import DataTable from '$lib/components/DataTable.svelte';
	import type { Column } from '$lib/components/DataTable.types';
	import { canAccessSection } from '$lib/roles';
	import { enhance } from '$app/forms';
	import { page } from '$app/state';

	let { data, children } = $props();
	const canEdit = $derived(canAccessSection(data.admin?.role, 'mantras'));

	const columns: Column[] = [
		{ key: 'nameRoman', label: 'Name', sortable: true },
		{ key: 'slug', label: 'Slug', hidden: 'md' },
		{ key: 'deity', label: 'Deity', sortable: true, hidden: 'lg' },
		{ key: 'isActive', label: 'Status', sortable: true },
		{ key: 'sortOrder', label: 'Order', sortable: true, hidden: 'lg', align: 'right' },
		{ key: 'actions', label: '', align: 'right' }
	];
</script>

<PageHeader title="Mantras" subtitle="Catalog served to the Flutter app via /api/v1/mantras">
	{#snippet actions()}
		{#if canEdit}
			<a href="/mantras/new" class="btn-primary" data-sveltekit-noscroll>
				<Plus size={16} /> New mantra
			</a>
		{/if}
	{/snippet}
</PageHeader>

<DataTable
	{columns}
	rows={data.mantras}
	total={data.total}
	currentPage={data.query.page}
	pageSize={data.query.pageSize}
	defaultSort={{ col: 'sortOrder', dir: 'asc' }}
	searchPlaceholder="Search mantras by name, slug or deity…"
	emptyTitle={data.query.q ? `No mantras match "${data.query.q}"` : 'No mantras yet'}
	emptyHint={canEdit && !data.query.q ? 'Click "New mantra" to add the first one.' : ''}
>
	{#snippet row(m)}
		<tr class="hover:bg-gray-50">
			<td class="px-4 py-3">
				<div class="flex items-center gap-3">
					<div class="w-8 h-8 rounded-full bg-brand-100 text-brand-700 grid place-items-center text-base shrink-0">
						{m.nameDevanagari.slice(0, 1)}
					</div>
					<div class="min-w-0">
						<div class="font-medium text-gray-900 truncate">{m.nameRoman}</div>
						<div class="text-xs text-gray-500 truncate">{m.nameDevanagari}</div>
					</div>
				</div>
			</td>
			<td class="px-4 py-3 hidden md:table-cell">
				<code class="text-xs text-gray-600">{m.slug}</code>
			</td>
			<td class="px-4 py-3 hidden lg:table-cell text-gray-600">{m.deity ?? '—'}</td>
			<td class="px-4 py-3">
				{#if m.isActive}
					<span class="chip bg-green-100 text-green-700">active</span>
				{:else}
					<span class="chip bg-gray-100 text-gray-600">hidden</span>
				{/if}
			</td>
			<td class="px-4 py-3 hidden lg:table-cell text-right text-gray-600">{m.sortOrder}</td>
			<td class="px-4 py-3">
				<div class="flex items-center gap-1 justify-end">
					{#if canEdit}
						<form method="POST" action="/mantras?/toggleActive" use:enhance>
							<input type="hidden" name="id" value={m.id} />
							<button class="p-2 rounded hover:bg-gray-100 text-gray-500" title={m.isActive ? 'Hide from app' : 'Show in app'}>
								{#if m.isActive}<EyeOff size={16} />{:else}<Eye size={16} />{/if}
							</button>
						</form>
					{/if}
					<a
						href={`/mantras/${m.id}/edit?${page.url.searchParams.toString()}`}
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
								p.set('delete', m.id);
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

<!-- Nested route slot: /mantras/new and /mantras/[id]/edit render modals here -->
{@render children()}
