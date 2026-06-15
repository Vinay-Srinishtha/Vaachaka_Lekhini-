<script lang="ts">
	import PageHeader from '$lib/components/PageHeader.svelte';
	import DataTable from '$lib/components/DataTable.svelte';
	import type { Column } from '$lib/components/DataTable.types';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';

	let { data } = $props();

	const columns: Column[] = [
		{ key: 'member', label: 'Member', sortable: false },
		{ key: 'mantra', label: 'Mantra', sortable: false },
		{ key: 'progress', label: 'Progress' },
		{ key: 'totalWritings', label: 'Count', align: 'right', sortable: false },
		{ key: 'sessions', label: 'Sessions', align: 'right', hidden: 'md' },
		{ key: 'status', label: 'Status' },
		{ key: 'startedAt', label: 'Started', sortable: true, hidden: 'lg' }
	];

	function fmt(d: Date | string | null) {
		if (!d) return '—';
		return new Date(d).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
	}

	function pct(done: number, target: number) {
		if (target === 0) return 0;
		return Math.min(100, Math.round((done / target) * 100));
	}

	function setStatus(s: string) {
		const url = new URL($page.url);
		url.searchParams.set('status', s);
		url.searchParams.set('page', '1');
		goto(url.toString());
	}

	const STATUS_FILTERS = [
		{ value: 'all', label: 'All' },
		{ value: 'active', label: 'Active' },
		{ value: 'completed', label: 'Completed' }
	];
</script>

<PageHeader title="Programs" subtitle="Every member's active and completed practice goals" />

<div class="px-4 pb-2 flex gap-2">
	{#each STATUS_FILTERS as f}
		<button
			onclick={() => setStatus(f.value)}
			class="px-3 py-1 rounded-full text-sm font-medium border transition-colors
				{data.query.status === f.value
					? 'bg-brand-600 text-white border-brand-600'
					: 'bg-white text-gray-600 border-gray-300 hover:border-brand-400 hover:text-brand-600'}"
		>
			{f.label}
		</button>
	{/each}
</div>

<DataTable
	{columns}
	rows={data.programs}
	total={data.total}
	currentPage={data.query.page}
	pageSize={data.query.pageSize}
	defaultSort={{ col: 'createdAt', dir: 'desc' }}
	searchPlaceholder="Search by member or mantra…"
	emptyTitle="No programs yet"
	emptyHint="Programs are created in the Flutter app when a member starts a new practice goal."
>
	{#snippet row(p)}
		<tr class="hover:bg-gray-50">
			<td class="px-4 py-3">
				<div class="text-sm font-medium text-gray-900">{p.member.displayName}</div>
				<div class="text-[11px] text-gray-500">{p.member.account.mobile}</div>
			</td>
			<td class="px-4 py-3">
				<div class="text-sm text-gray-800">{p.mantra.nameRoman}</div>
				<div class="text-[11px] text-gray-500">{p.mantra.nameDevanagari}</div>
			</td>
			<td class="px-4 py-3 w-36">
				<div class="flex items-center gap-2">
					<div class="flex-1 bg-gray-100 rounded-full h-2 overflow-hidden">
						<div
							class="h-2 rounded-full {p.completedAt ? 'bg-green-500' : 'bg-brand-500'}"
							style="width:{pct(p.totalWritings + p.totalChants, p.targetWritings)}%"
						></div>
					</div>
					<span class="text-[11px] text-gray-500 tabular-nums w-8 text-right">{pct(p.totalWritings + p.totalChants, p.targetWritings)}%</span>
				</div>
			</td>
			<td class="px-4 py-3 text-right tabular-nums text-sm text-gray-700">
				{(p.totalWritings + p.totalChants).toLocaleString()} / {p.targetWritings.toLocaleString()}
			</td>
			<td class="px-4 py-3 text-right tabular-nums text-sm text-gray-700 hidden md:table-cell">
				{p._count.sessions}
			</td>
			<td class="px-4 py-3">
				{#if p.completedAt}
					<span class="chip bg-green-100 text-green-700">Completed</span>
				{:else}
					<span class="chip bg-blue-100 text-blue-700">Active</span>
				{/if}
			</td>
			<td class="px-4 py-3 text-sm text-gray-500 hidden lg:table-cell">{fmt(p.startedAt)}</td>
		</tr>
	{/snippet}
</DataTable>
