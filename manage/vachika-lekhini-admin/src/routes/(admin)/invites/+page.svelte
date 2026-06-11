<script lang="ts">
	import PageHeader from '$lib/components/PageHeader.svelte';
	import DataTable from '$lib/components/DataTable.svelte';
	import type { Column } from '$lib/components/DataTable.types';
	import { page } from '$app/state';

	let { data } = $props();

	const columns: Column[] = [
		{ key: 'inviter', label: 'Inviter' },
		{ key: 'invitee', label: 'Invitee' },
		{ key: 'status', label: 'Status', sortable: true },
		{ key: 'reward', label: 'Reward' },
		{ key: 'createdAt', label: 'Sent', sortable: true },
		{ key: 'acceptedAt', label: 'Accepted', hidden: 'lg' }
	];

	const STATUSES = [
		{ value: '', label: 'All' },
		{ value: 'pending', label: 'Pending' },
		{ value: 'accepted', label: 'Accepted' },
		{ value: 'expired', label: 'Expired' }
	];

	function fmt(d: Date | string | null) {
		if (!d) return '—';
		return new Date(d).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
	}

	function statusChip(s: string) {
		if (s === 'accepted') return 'bg-green-100 text-green-700';
		if (s === 'expired') return 'bg-gray-100 text-gray-600';
		return 'bg-amber-100 text-amber-700';
	}

	function buildUrl(s: string) {
		const u = new URL(page.url.toString());
		if (s) u.searchParams.set('status', s); else u.searchParams.delete('status');
		u.searchParams.set('page', '1');
		return u.toString();
	}
</script>

<PageHeader title="Invites" subtitle="Referral invitations sent by members" />

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
	rows={data.invites}
	total={data.total}
	currentPage={data.query.page}
	pageSize={data.query.pageSize}
	defaultSort={{ col: 'createdAt', dir: 'desc' }}
	searchPlaceholder="Search by mobile number…"
	emptyTitle="No invites sent yet"
	emptyHint="Invite links appear when members share their referral code in the app."
>
	{#snippet row(i)}
		<tr class="hover:bg-gray-50">
			<td class="px-4 py-3 text-sm font-medium text-gray-900">{i.inviter.mobile}</td>
			<td class="px-4 py-3 text-sm text-gray-700">
				{i.invitee?.mobile ?? i.inviteeMobile ?? '—'}
			</td>
			<td class="px-4 py-3"><span class="chip {statusChip(i.status)}">{i.status}</span></td>
			<td class="px-4 py-3">
				{#if i.rewardGranted}
					<span class="chip bg-green-100 text-green-700">Granted</span>
				{:else}
					<span class="text-sm text-gray-400">—</span>
				{/if}
			</td>
			<td class="px-4 py-3 text-sm text-gray-500">{fmt(i.createdAt)}</td>
			<td class="px-4 py-3 text-sm text-gray-500 hidden lg:table-cell">{fmt(i.acceptedAt)}</td>
		</tr>
	{/snippet}
</DataTable>
