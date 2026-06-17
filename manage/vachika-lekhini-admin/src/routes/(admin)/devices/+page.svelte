<script lang="ts">
	import PageHeader from '$lib/components/PageHeader.svelte';
	import DataTable from '$lib/components/DataTable.svelte';
	import StatCard from '$lib/components/StatCard.svelte';
	import type { Column } from '$lib/components/DataTable.types';
	import { Smartphone, ShieldAlert, Apple, BotIcon } from '@lucide/svelte';
	import { page } from '$app/state';

	let { data } = $props();

	const columns: Column[] = [
		{ key: 'account',    label: 'Account' },
		{ key: 'platform',   label: 'Platform' },
		{ key: 'appVersion', label: 'Version',   hidden: 'md' },
		{ key: 'pushToken',  label: 'FCM Token', hidden: 'lg' },
		{ key: 'lastSeenAt', label: 'Last seen', sortable: true },
		{ key: 'createdAt',  label: 'First seen',sortable: true, hidden: 'lg' },
	];

	const PLATFORMS = [
		{ value: '',        label: 'All platforms' },
		{ value: 'android', label: 'Android'       },
		{ value: 'ios',     label: 'iOS'           },
		{ value: 'web',     label: 'Web'           },
	];

	function fmt(d: Date | string | null) {
		if (!d) return '—';
		return new Date(d).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' });
	}

	function platformChip(p: string) {
		if (p === 'android') return 'bg-green-100 text-green-700';
		if (p === 'ios')     return 'bg-blue-100  text-blue-700';
		return 'bg-gray-100 text-gray-600';
	}

	function buildUrl(p: string) {
		const u = new URL(page.url.toString());
		if (p) u.searchParams.set('platform', p); else u.searchParams.delete('platform');
		u.searchParams.set('page', '1');
		return u.toString();
	}
</script>

<PageHeader title="Devices" subtitle="Registered devices and active JWT sessions" />

<div class="grid grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
	<StatCard label="Total devices"    value={data.total}         hint="Ever registered"                         icon={Smartphone}  />
	<StatCard label="Revoked tokens"   value={data.revokedCount}  hint="Active revocations (not yet expired)"    icon={ShieldAlert} tone="red" />
	<StatCard label="Filtered results" value={data.devices.length} hint="Use platform filter to narrow"           icon={Smartphone}  tone="gray" />
</div>

<!-- Platform filter tabs -->
<div class="mb-4 flex gap-2 flex-wrap">
	{#each PLATFORMS as p}
		<a
			href={buildUrl(p.value)}
			class="px-3.5 py-1.5 rounded-full text-sm font-semibold transition border
				{data.platform === p.value
				? 'bg-brand-600 text-white border-brand-600 shadow-sm'
				: 'bg-white text-gray-600 border-gray-200 hover:border-brand-400 hover:text-brand-600'}"
		>{p.label}</a>
	{/each}
</div>

<DataTable
	{columns}
	rows={data.devices}
	total={data.total}
	currentPage={data.query.page}
	pageSize={data.query.pageSize}
	defaultSort={{ col: 'lastSeenAt', dir: 'desc' }}
	searchPlaceholder="Search by mobile or version…"
	emptyTitle="No devices registered"
	emptyHint="Devices appear when a user logs in on a phone or tablet."
>
	{#snippet row(d)}
		<tr class="hover:bg-gray-50 transition-colors">
			<td class="px-4 py-3">
				<div class="text-sm font-semibold text-gray-900">{d.account.mobile}</div>
				{#if d.account.isBanned}
					<span class="chip bg-red-100 text-red-700 text-[10px] mt-0.5">banned</span>
				{/if}
			</td>
			<td class="px-4 py-3">
				<span class="chip {platformChip(d.platform)}">{d.platform}</span>
			</td>
			<td class="px-4 py-3 text-sm text-gray-500 hidden md:table-cell">{d.appVersion ?? '—'}</td>
			<td class="px-4 py-3 hidden lg:table-cell">
				{#if d.pushToken}
					<code class="text-[11px] text-gray-400 truncate max-w-[120px] block font-mono">{d.pushToken.slice(0, 22)}…</code>
				{:else}
					<span class="text-sm text-gray-300">—</span>
				{/if}
			</td>
			<td class="px-4 py-3 text-sm text-gray-400">{fmt(d.lastSeenAt)}</td>
			<td class="px-4 py-3 text-sm text-gray-400 hidden lg:table-cell">{fmt(d.createdAt)}</td>
		</tr>
	{/snippet}
</DataTable>
