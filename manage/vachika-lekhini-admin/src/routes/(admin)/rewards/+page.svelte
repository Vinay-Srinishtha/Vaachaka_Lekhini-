<script lang="ts">
	import PageHeader from '$lib/components/PageHeader.svelte';
	import DataTable from '$lib/components/DataTable.svelte';
	import StatCard from '$lib/components/StatCard.svelte';
	import Modal from '$lib/components/Modal.svelte';
	import type { Column } from '$lib/components/DataTable.types';
	import { Coins, TrendingUp, TrendingDown, Settings2, Gift } from '@lucide/svelte';
	import { page } from '$app/state';
	import { enhance } from '$app/forms';

	let { data, form } = $props();

	let rateInput = $state(data.rewardRate);
	let rateSaving = $state(false);
	let rateSaved = $state(false);

	// Grant points dialog state
	let grantOpen = $state(false);
	let grantSaving = $state(false);
	let grantMemberId = $state('');
	let grantKind = $state<'gift' | 'refund'>('gift');
	let grantAmount = $state(100);
	let grantNote = $state('');
	const formAny = form as any;
	let grantError = $state<string | null>(formAny?.grantError ?? null);
	let grantSuccess = $state(false);

	function onRateSuccess() {
		rateSaving = false;
		rateSaved = true;
		setTimeout(() => (rateSaved = false), 2000);
	}

	function openGrant() {
		grantMemberId = data.members[0]?.id ?? '';
		grantKind = 'gift';
		grantAmount = 100;
		grantNote = '';
		grantError = null;
		grantSuccess = false;
		grantOpen = true;
	}

	function closeGrant() {
		grantOpen = false;
	}

	const columns: Column[] = [
		{ key: 'member', label: 'Member' },
		{ key: 'kind', label: 'Type' },
		{ key: 'amount', label: 'Points', align: 'right', sortable: true },
		{ key: 'source', label: 'Source', hidden: 'md' },
		{ key: 'storeItem', label: 'Store Item', hidden: 'lg' },
		{ key: 'balance', label: 'Balance', align: 'right', hidden: 'md' },
		{ key: 'occurredAt', label: 'Date', sortable: true }
	];

	const KINDS = [
		{ value: '', label: 'All types' },
		{ value: 'earn', label: 'Earn' },
		{ value: 'spend', label: 'Spend' },
		{ value: 'milestone', label: 'Milestone' },
		{ value: 'gift', label: 'Gift' },
		{ value: 'refund', label: 'Refund' }
	];

	function fmt(d: Date | string) {
		return new Date(d).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });
	}

	function kindChip(k: string) {
		if (k === 'earn' || k === 'milestone' || k === 'gift' || k === 'refund') return 'bg-green-100 text-green-700';
		return 'bg-red-100 text-red-700';
	}

	const earned = $derived(data.totals.find((t: { kind: string }) => t.kind === 'earn')?._sum?.amount ?? 0);
	const spent = $derived(data.totals.find((t: { kind: string }) => t.kind === 'spend')?._sum?.amount ?? 0);

	function buildUrl(kind: string) {
		const u = new URL(page.url.toString());
		if (kind) u.searchParams.set('kind', kind); else u.searchParams.delete('kind');
		u.searchParams.set('page', '1');
		return u.toString();
	}
</script>

<PageHeader title="Rewards Ledger" subtitle="Append-only ledger of all point earn and spend events">
	{#snippet actions()}
		<button onclick={openGrant} class="btn-primary flex items-center gap-2">
			<Gift size={16} /> Grant Points
		</button>
	{/snippet}
</PageHeader>

<!-- Grant Points Modal -->
<Modal open={grantOpen} title="Grant Points" subtitle="Manually credit reward points to a member" size="lg" onClose={closeGrant}>
	<form
		method="POST"
		action="?/grantPoints"
		use:enhance={() => {
			grantSaving = true;
			grantError = null;
			return async ({ result, update }) => {
				await update({ reset: false });
				grantSaving = false;
				if (result.type === 'success') {
					grantSuccess = true;
					setTimeout(closeGrant, 1200);
				} else if (result.type === 'failure') {
					grantError = (result.data as any)?.grantError ?? 'Something went wrong';
				}
			};
		}}
		class="space-y-5"
	>
		<section class="card p-5 space-y-4">
			<p class="section-label">Recipient</p>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="grantMember">Member</label>
				<select id="grantMember" name="memberId" bind:value={grantMemberId} class="input">
					{#each data.members as m}
						<option value={m.id}>{m.displayName} · {m.rewardPointsBalance.toLocaleString()} pts</option>
					{/each}
				</select>
			</div>
		</section>
		<section class="card p-5 space-y-4">
			<p class="section-label">Grant details</p>
			<div class="grid grid-cols-2 gap-4">
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="grantKind">Type</label>
					<select id="grantKind" name="kind" bind:value={grantKind} class="input">
						<option value="gift">Gift</option>
						<option value="refund">Refund</option>
					</select>
				</div>
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="grantAmount">Points</label>
					<input id="grantAmount" name="amount" type="number" min="1" max="100000"
						bind:value={grantAmount} class="input" />
				</div>
			</div>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="grantNote">Note (optional)</label>
				<input id="grantNote" name="note" type="text" placeholder="Reason for grant…"
					bind:value={grantNote} maxlength="300" class="input" />
			</div>
		</section>
		{#if grantError}
			<p class="text-sm text-red-600 bg-red-50 rounded-lg px-4 py-2">{grantError}</p>
		{/if}
		{#if grantSuccess}
			<p class="text-sm text-green-700 font-medium bg-green-50 rounded-lg px-4 py-2">✓ Points granted successfully</p>
		{/if}
		<div class="flex justify-end gap-3">
			<button type="button" onclick={closeGrant} class="btn-secondary">Cancel</button>
			<button type="submit" disabled={grantSaving || grantSuccess} class="btn-primary">
				<Gift size={16} />
				{grantSaving ? 'Granting…' : 'Grant Points'}
			</button>
		</div>
	</form>
</Modal>

<!-- Reward Rate Config Card -->
<div class="bg-white border border-gray-200 rounded-xl p-5 mb-6 flex flex-col sm:flex-row sm:items-center gap-4">
	<div class="flex items-start gap-3 flex-1">
		<div class="mt-0.5 p-2 bg-brand-50 rounded-lg text-brand-600">
			<Settings2 size={18} />
		</div>
		<div>
			<p class="font-semibold text-gray-900 text-sm">Reward Rate</p>
			<p class="text-xs text-gray-500 mt-0.5">How many chants = 1 reward point. Takes effect on the next session sync from any device.</p>
		</div>
	</div>
	<form
		method="POST"
		action="?/setRate"
		use:enhance={() => {
			rateSaving = true;
			return ({ result }) => {
				if (result.type === 'success') onRateSuccess();
				else rateSaving = false;
			};
		}}
		class="flex items-center gap-3 shrink-0"
	>
		<div class="flex items-center gap-2 border border-gray-300 rounded-lg px-3 py-2 focus-within:ring-2 focus-within:ring-brand-400 bg-white">
			<input
				type="number"
				name="rate"
				min="1"
				max="10000"
				bind:value={rateInput}
				class="w-20 text-sm font-semibold text-gray-900 outline-none tabular-nums"
			/>
			<span class="text-xs text-gray-400 whitespace-nowrap">chants / pt</span>
		</div>
		<button
			type="submit"
			disabled={rateSaving}
			class="px-4 py-2 rounded-lg text-sm font-medium transition
				{rateSaved
					? 'bg-green-100 text-green-700'
					: 'bg-brand-600 text-white hover:bg-brand-700 disabled:opacity-60'}"
		>
			{rateSaved ? '✓ Saved' : rateSaving ? 'Saving…' : 'Save'}
		</button>
	</form>
</div>

<div class="grid grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
	<StatCard label="Total earned" value={earned.toLocaleString()} hint="All-time points granted" icon={TrendingUp} tone="green" />
	<StatCard label="Total spent" value={spent.toLocaleString()} hint="All-time points redeemed" icon={TrendingDown} tone="red" />
	<StatCard label="Net circulating" value={(earned - spent).toLocaleString()} hint="Points currently held by members" icon={Coins} tone="brand" />
</div>

<div class="mb-4 flex gap-2 flex-wrap">
	{#each KINDS as k}
		<a
			href={buildUrl(k.value)}
			class="px-3 py-1.5 rounded-full text-sm font-medium transition border
				{data.kind === k.value
				? 'bg-brand-600 text-white border-brand-600'
				: 'bg-white text-gray-600 border-gray-200 hover:border-brand-400'}"
		>{k.label}</a>
	{/each}
</div>

<DataTable
	{columns}
	rows={data.events}
	total={data.total}
	currentPage={data.query.page}
	pageSize={data.query.pageSize}
	defaultSort={{ col: 'occurredAt', dir: 'desc' }}
	searchPlaceholder="Search by member or source…"
	emptyTitle="No reward events"
	emptyHint="Events appear when members complete sessions or redeem store items."
>
	{#snippet row(e)}
		<tr class="hover:bg-gray-50">
			<td class="px-4 py-3 text-sm font-medium text-gray-900">{e.member.displayName}</td>
			<td class="px-4 py-3"><span class="chip {kindChip(e.kind)}">{e.kind}</span></td>
			<td class="px-4 py-3 text-right tabular-nums text-sm font-semibold {e.kind === 'spend' ? 'text-red-600' : 'text-green-600'}">
				{e.kind === 'spend' ? '−' : '+'}{e.amount.toLocaleString()}
			</td>
			<td class="px-4 py-3 text-xs text-gray-500 hidden md:table-cell max-w-[200px] truncate" title={e.source}>{e.source}</td>
			<td class="px-4 py-3 text-sm text-gray-700 hidden lg:table-cell">{e.storeItem?.name ?? '—'}</td>
			<td class="px-4 py-3 text-right tabular-nums text-sm text-gray-700 hidden md:table-cell">{e.member.rewardPointsBalance.toLocaleString()}</td>
			<td class="px-4 py-3 text-sm text-gray-500">{fmt(e.occurredAt)}</td>
		</tr>
	{/snippet}
</DataTable>
