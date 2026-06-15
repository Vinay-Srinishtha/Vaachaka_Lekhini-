<script lang="ts">
	import { Plus, Edit2, Trash2 } from '@lucide/svelte';
	import PageHeader from '$lib/components/PageHeader.svelte';
	import DataTable from '$lib/components/DataTable.svelte';
	import type { Column } from '$lib/components/DataTable.types';
	import { canAccessSection } from '$lib/roles';
	import { page } from '$app/state';

	let { data, children } = $props();
	const canEdit = $derived(canAccessSection(data.admin?.role, 'config'));

	const columns: Column[] = [
		{ key: 'key', label: 'Key', sortable: true },
		{ key: 'valueType', label: 'Type', sortable: true },
		{ key: 'value', label: 'Value' },
		{ key: 'description', label: 'Description', hidden: 'lg' },
		{ key: 'actions', label: '', align: 'right' }
	];

	function previewValue(v: unknown): string {
		if (typeof v === 'string') return v.length > 40 ? v.slice(0, 40) + '…' : v;
		const s = JSON.stringify(v);
		return s.length > 50 ? s.slice(0, 50) + '…' : s;
	}

	const typeTone: Record<string, string> = {
		bool: 'bg-blue-100 text-blue-700',
		int: 'bg-purple-100 text-purple-700',
		string: 'bg-emerald-100 text-emerald-700',
		json: 'bg-amber-100 text-amber-700'
	};
</script>

<PageHeader title="Config & Flags" subtitle="Remote config served at /api/v1/config — Flutter app polls this">
	{#snippet actions()}
		{#if canEdit}
			<a href="/config/new" class="btn-primary" data-sveltekit-noscroll>
				<Plus size={16} /> New flag
			</a>
		{/if}
	{/snippet}
</PageHeader>

<DataTable
	{columns}
	rows={data.flags}
	total={data.total}
	currentPage={data.query.page}
	pageSize={data.query.pageSize}
	defaultSort={{ col: 'key', dir: 'asc' }}
	searchPlaceholder="Search by key or description…"
	emptyTitle={data.query.q ? `No flags match "${data.query.q}"` : 'No flags yet'}
	emptyHint={canEdit && !data.query.q ? 'Click "New flag" to add the first one.' : ''}
>
	{#snippet row(f)}
		<tr class="hover:bg-gray-50">
			<td class="px-4 py-3">
				<code class="text-xs text-gray-900 font-medium">{f.key}</code>
			</td>
			<td class="px-4 py-3">
				<span class="chip {typeTone[f.valueType] ?? 'bg-gray-100 text-gray-700'}">{f.valueType}</span>
			</td>
			<td class="px-4 py-3">
				<code class="text-xs text-gray-700">{previewValue(f.value)}</code>
			</td>
			<td class="px-4 py-3 hidden lg:table-cell text-gray-600 text-xs max-w-md truncate">
				{f.description ?? '—'}
			</td>
			<td class="px-4 py-3">
				<div class="flex items-center gap-1 justify-end">
					<a
						href={`/config/${encodeURIComponent(f.key)}/edit?${page.url.searchParams.toString()}`}
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
								p.set('delete', f.key);
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
