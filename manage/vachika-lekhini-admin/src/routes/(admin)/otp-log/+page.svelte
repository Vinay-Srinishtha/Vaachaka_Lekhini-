<script lang="ts">
	import PageHeader from '$lib/components/PageHeader.svelte';
	import DataTable from '$lib/components/DataTable.svelte';
	import type { Column } from '$lib/components/DataTable.types';
	import { page } from '$app/state';

	let { data } = $props();

	const columns: Column[] = [
		{ key: 'mobile', label: 'Mobile' },
		{ key: 'status', label: 'Status' },
		{ key: 'attempts', label: 'Attempts', align: 'right', sortable: true },
		{ key: 'createdAt', label: 'Requested', sortable: true },
		{ key: 'expiresAt', label: 'Expires', hidden: 'lg' },
		{ key: 'consumedAt', label: 'Consumed', hidden: 'lg' }
	];

	const STATUSES = [
		{ value: '', label: 'All' },
		{ value: 'active', label: 'Active' },
		{ value: 'consumed', label: 'Consumed' },
		{ value: 'expired', label: 'Expired' }
	];

	function fmt(d: Date | string | null) {
		if (!d) return '—';
		return new Date(d).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });
	}

	function getStatus(c: { consumedAt: Date | null; expiresAt: Date }) {
		if (c.consumedAt) return 'consumed';
		if (new Date(c.expiresAt) < new Date()) return 'expired';
		return 'active';
	}

	function statusChip(s: string) {
		if (s === 'consumed') return 'bg-green-100 text-green-700';
		if (s === 'expired') return 'bg-gray-100 text-gray-600';
		return 'bg-blue-100 text-blue-700';
	}

	function buildUrl(s: string) {
		const u = new URL(page.url.toString());
		if (s) u.searchParams.set('status', s); else u.searchParams.delete('status');
		u.searchParams.set('page', '1');
		return u.toString();
	}
</script>

<PageHeader title="OTP Log" subtitle="All OTP challenges — active, consumed, and expired" />

<div class="mb-4 flex gap-2 flex-wrap">
	{#each STATUSES as s}
		<a
			href={buildUrl(s.value)}
			class="px-3 py-1.5 rounded-full text-sm font-medium transition border
				{data.status === s.value
				? 'bg-brand-600 text-white border-brand-600'
				: 'bg-white text-gray-600 border-gray-200 hover:border-brand-400'}"
		>{s.label}</a>
	{/each}
</div>

<DataTable
	{columns}
	rows={data.challenges}
	total={data.total}
	currentPage={data.query.page}
	pageSize={data.query.pageSize}
	defaultSort={{ col: 'createdAt', dir: 'desc' }}
	searchPlaceholder="Search by mobile number…"
	emptyTitle="No OTP challenges"
	emptyHint="OTP requests appear here as soon as someone tries to log in."
>
	{#snippet row(c)}
		{@const s = getStatus(c)}
		<tr class="hover:bg-gray-50">
			<td class="px-4 py-3">
				<div class="text-sm font-medium text-gray-900">{c.mobile}</div>
				{#if c.account?.isBanned}
					<span class="chip bg-red-100 text-red-700 text-[10px]">banned</span>
				{/if}
			</td>
			<td class="px-4 py-3"><span class="chip {statusChip(s)}">{s}</span></td>
			<td class="px-4 py-3 text-right tabular-nums text-sm {c.attempts >= 3 ? 'text-red-600 font-semibold' : 'text-gray-700'}">{c.attempts}</td>
			<td class="px-4 py-3 text-sm text-gray-500">{fmt(c.createdAt)}</td>
			<td class="px-4 py-3 text-sm text-gray-500 hidden lg:table-cell">{fmt(c.expiresAt)}</td>
			<td class="px-4 py-3 text-sm text-gray-500 hidden lg:table-cell">{fmt(c.consumedAt)}</td>
		</tr>
	{/snippet}
</DataTable>
