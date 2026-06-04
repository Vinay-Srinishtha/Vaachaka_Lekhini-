<script lang="ts">
	import { ShieldOff, ShieldCheck, ChevronRight } from '@lucide/svelte';
	import PageHeader from '$lib/components/PageHeader.svelte';
	import DataTable from '$lib/components/DataTable.svelte';
	import type { Column } from '$lib/components/DataTable.types';
	import { enhance } from '$app/forms';
	import { page } from '$app/state';

	let { data, form } = $props();

	const columns: Column[] = [
		{ key: 'mobile', label: 'Mobile', sortable: true },
		{ key: 'primary', label: 'Primary member' },
		{ key: 'members', label: 'Members', align: 'right' },
		{ key: 'referralCode', label: 'Referral', hidden: 'md' },
		{ key: 'isBanned', label: 'Status', sortable: true },
		{ key: 'createdAt', label: 'Joined', sortable: true, hidden: 'lg' },
		{ key: 'lastSeenAt', label: 'Last seen', sortable: true, hidden: 'lg' },
		{ key: 'actions', label: '', align: 'right' }
	];

	function fmt(d: Date | string | null) {
		if (!d) return '—';
		return new Date(d).toLocaleDateString(undefined, {
			year: 'numeric',
			month: 'short',
			day: 'numeric'
		});
	}
</script>

<PageHeader title="Accounts" subtitle="One row per registered mobile number — each owns up to 4 family members" />

{#if form?.error}
	<div class="mb-4 text-sm rounded-lg bg-red-50 text-red-700 border border-red-200 px-3 py-2">
		{form.error}
	</div>
{/if}

<DataTable
	{columns}
	rows={data.accounts}
	total={data.total}
	currentPage={data.query.page}
	pageSize={data.query.pageSize}
	defaultSort={{ col: 'createdAt', dir: 'desc' }}
	searchPlaceholder="Search by mobile, referral or member name…"
	emptyTitle={data.query.q ? `No accounts match "${data.query.q}"` : 'No accounts yet'}
	emptyHint="Accounts appear once the Flutter app starts syncing."
>
	{#snippet row(a)}
		<tr class="hover:bg-gray-50">
			<td class="px-4 py-3">
				<a
					href={`/accounts/${a.id}?${page.url.searchParams.toString()}`}
					class="flex items-center gap-3 group"
				>
					<div class="w-8 h-8 rounded-full bg-gray-100 text-gray-600 grid place-items-center text-xs font-medium shrink-0">
						{a.mobile.slice(-2)}
					</div>
					<div class="min-w-0">
						<div class="font-medium text-gray-900 group-hover:text-brand-700 truncate">{a.countryCode} {a.mobile}</div>
						<div class="text-[11px] text-gray-500 truncate">
							{a.passwordSetAt ? 'OTP + password' : 'OTP only'}
						</div>
					</div>
				</a>
			</td>
			<td class="px-4 py-3 text-gray-700">{a.members[0]?.displayName ?? '—'}</td>
			<td class="px-4 py-3 text-right tabular-nums text-gray-700">{a._count.members}</td>
			<td class="px-4 py-3 hidden md:table-cell">
				{#if a.referralCode}<code class="text-xs text-gray-600">{a.referralCode}</code>{:else}—{/if}
			</td>
			<td class="px-4 py-3">
				{#if a.isBanned}
					<span class="chip bg-red-100 text-red-700" title={a.bannedReason ?? ''}>banned</span>
				{:else}
					<span class="chip bg-green-100 text-green-700">active</span>
				{/if}
			</td>
			<td class="px-4 py-3 hidden lg:table-cell text-gray-600 text-xs">{fmt(a.createdAt)}</td>
			<td class="px-4 py-3 hidden lg:table-cell text-gray-600 text-xs">{fmt(a.lastSeenAt)}</td>
			<td class="px-4 py-3">
				<div class="flex items-center gap-1 justify-end">
					<form method="POST" action="?/toggleBan" use:enhance>
						<input type="hidden" name="id" value={a.id} />
						{#if !a.isBanned}
							<input type="hidden" name="reason" value="Admin action" />
						{/if}
						<button
							class={a.isBanned ? 'btn-secondary !px-2 !py-1.5' : 'btn-danger !px-2 !py-1.5'}
							title={a.isBanned ? 'Unban' : 'Ban'}
						>
							{#if a.isBanned}<ShieldCheck size={14} /> <span class="hidden sm:inline">Unban</span>
							{:else}<ShieldOff size={14} /> <span class="hidden sm:inline">Ban</span>{/if}
						</button>
					</form>
					<a
						href={`/accounts/${a.id}?${page.url.searchParams.toString()}`}
						class="p-2 rounded hover:bg-gray-100 text-gray-400"
						title="Open"
					>
						<ChevronRight size={16} />
					</a>
				</div>
			</td>
		</tr>
	{/snippet}
</DataTable>
