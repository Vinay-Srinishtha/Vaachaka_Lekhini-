<script lang="ts">
	import StatCard from '$lib/components/StatCard.svelte';
	import {
		BookOpen,
		ShoppingBag,
		Settings2,
		Users,
		UserCheck,
		Activity,
		ShieldAlert,
		Layers
	} from '@lucide/svelte';

	let { data } = $props();
	const s = $derived(data.stats);

	function fmtDate(d: Date | string) {
		return new Date(d).toLocaleDateString(undefined, {
			year: 'numeric',
			month: 'short',
			day: 'numeric'
		});
	}
</script>

<div class="space-y-6">
	<section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
		<StatCard
			label="Mantras"
			value={s.mantraCount}
			hint={`${s.activeMantras} visible in app`}
			icon={BookOpen}
		/>
		<StatCard label="Store items" value={s.storeCount} hint="Currently active" icon={ShoppingBag} tone="blue" />
		<StatCard label="Feature flags" value={s.flagCount} hint="Remote config keys" icon={Settings2} tone="gray" />
		<StatCard
			label="Accounts"
			value={s.accountCount}
			hint={`${s.bannedAccountCount} banned`}
			icon={Users}
			tone="green"
		/>
		<StatCard label="Family members" value={s.memberCount} icon={UserCheck} tone="brand" />
		<StatCard label="Active programs" value={s.programCount} icon={Layers} tone="blue" />
		<StatCard label="Chant sessions" value={s.sessionCount} icon={Activity} tone="brand" />
		<StatCard label="Banned" value={s.bannedAccountCount} icon={ShieldAlert} tone="red" />
	</section>

	<section class="grid grid-cols-1 lg:grid-cols-2 gap-4">
		<div class="card overflow-hidden">
			<div class="px-5 py-3 border-b border-gray-200 flex items-center justify-between">
				<h2 class="font-semibold text-gray-900">Recent accounts</h2>
				<a href="/accounts" class="text-sm text-brand-600 hover:underline">View all</a>
			</div>
			{#if data.recentAccounts.length === 0}
				<div class="px-5 py-10 text-center text-sm text-gray-500">No accounts yet.</div>
			{:else}
				<ul class="divide-y divide-gray-100">
					{#each data.recentAccounts as a (a.id)}
						<li class="px-5 py-3 flex items-center justify-between">
							<div>
								<div class="text-sm font-medium text-gray-900">{a.mobile}</div>
								<div class="text-xs text-gray-500">
									{a._count.members} {a._count.members === 1 ? 'member' : 'members'} · joined {fmtDate(a.createdAt)}
								</div>
							</div>
							{#if a.isBanned}
								<span class="chip bg-red-100 text-red-700">banned</span>
							{:else}
								<span class="chip bg-green-100 text-green-700">active</span>
							{/if}
						</li>
					{/each}
				</ul>
			{/if}
		</div>

		<div class="card overflow-hidden">
			<div class="px-5 py-3 border-b border-gray-200 flex items-center justify-between">
				<h2 class="font-semibold text-gray-900">Top mantras by program count</h2>
				<a href="/mantras" class="text-sm text-brand-600 hover:underline">Manage</a>
			</div>
			{#if data.topMantras.length === 0}
				<div class="px-5 py-10 text-center text-sm text-gray-500">No programs created yet.</div>
			{:else}
				<ul class="divide-y divide-gray-100">
					{#each data.topMantras as row (row.mantra.id)}
						<li class="px-5 py-3 flex items-center justify-between">
							<div class="text-sm font-medium text-gray-900">{row.mantra.nameRoman}</div>
							<span class="text-sm text-gray-600">{row.count} programs</span>
						</li>
					{/each}
				</ul>
			{/if}
		</div>
	</section>
</div>
