<script lang="ts">
	import { ArrowLeft, User, Smartphone, Star } from '@lucide/svelte';
	import { page } from '$app/state';

	let { data } = $props();
	const a = $derived(data.account);

	function fmt(d: Date | string | null) {
		if (!d) return '—';
		return new Date(d).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });
	}

	const relationLabel: Record<string, string> = {
		self: 'Self',
		spouse: 'Spouse',
		parent: 'Parent',
		child: 'Child',
		sibling: 'Sibling',
		friend: 'Friend',
		other: 'Other'
	};
</script>

<a
	href={`/accounts?${page.url.searchParams.toString()}`}
	class="inline-flex items-center gap-1 text-sm text-gray-600 hover:text-brand-700 mb-4"
>
	<ArrowLeft size={16} /> All accounts
</a>

<header class="mb-6 flex items-start justify-between gap-3">
	<div>
		<h1 class="text-xl md:text-2xl font-bold text-gray-900">{a.countryCode} {a.mobile}</h1>
		<p class="text-sm text-gray-500 mt-1">
			{a._count.members} {a._count.members === 1 ? 'member' : 'members'} ·
			{a.passwordSetAt ? 'OTP + password' : 'OTP only'} ·
			joined {fmt(a.createdAt)}
		</p>
	</div>
	{#if a.isBanned}
		<span class="chip bg-red-100 text-red-700">banned</span>
	{:else}
		<span class="chip bg-green-100 text-green-700">active</span>
	{/if}
</header>

<section class="space-y-4">
	<h2 class="text-sm font-semibold text-gray-700 uppercase tracking-wide">Family members</h2>
	<div class="grid grid-cols-1 md:grid-cols-2 gap-3">
		{#each a.members as m (m.id)}
			<div class="card p-4">
				<div class="flex items-start gap-3">
					<div class="w-10 h-10 rounded-full bg-brand-100 text-brand-700 grid place-items-center font-bold">
						{m.displayName.slice(0, 1).toUpperCase()}
					</div>
					<div class="flex-1 min-w-0">
						<div class="flex items-center gap-2">
							<div class="font-medium text-gray-900 truncate">{m.displayName}</div>
							{#if m.isPrimary}
								<span class="chip bg-amber-100 text-amber-700 inline-flex items-center gap-1">
									<Star size={10} /> primary
								</span>
							{/if}
						</div>
						<div class="text-xs text-gray-500 mt-0.5">
							{relationLabel[m.relation] ?? m.relation} · {m.language}
						</div>
						<div class="mt-3 grid grid-cols-3 gap-2 text-center">
							<div>
								<div class="text-base font-semibold text-gray-900">{m._count.programs}</div>
								<div class="text-[10px] text-gray-500 uppercase tracking-wide">Programs</div>
							</div>
							<div>
								<div class="text-base font-semibold text-gray-900">{m._count.sessions}</div>
								<div class="text-[10px] text-gray-500 uppercase tracking-wide">Sessions</div>
							</div>
							<div>
								<div class="text-base font-semibold text-gray-900">{m.rewardPointsBalance}</div>
								<div class="text-[10px] text-gray-500 uppercase tracking-wide">Points</div>
							</div>
						</div>
					</div>
				</div>
			</div>
		{/each}
	</div>
</section>

<section class="mt-8 space-y-3">
	<h2 class="text-sm font-semibold text-gray-700 uppercase tracking-wide">Recent sessions</h2>
	<div class="card overflow-hidden">
		{#if data.recentSessions.length === 0}
			<div class="px-5 py-10 text-center text-sm text-gray-500">No sessions yet.</div>
		{:else}
			<ul class="divide-y divide-gray-100">
				{#each data.recentSessions as s (s.id)}
					<li class="px-5 py-3 flex items-center justify-between gap-3">
						<div class="min-w-0">
							<div class="text-sm font-medium text-gray-900 truncate">
								{s.member.displayName} · {s.program.mantra.nameRoman}
							</div>
							<div class="text-xs text-gray-500">{fmt(s.startedAt)} · {s.modality} · {s.durationSec}s</div>
						</div>
						<div class="text-sm font-semibold text-brand-700 tabular-nums">+{s.countAdded}</div>
					</li>
				{/each}
			</ul>
		{/if}
	</div>
</section>

<section class="mt-8 space-y-3">
	<h2 class="text-sm font-semibold text-gray-700 uppercase tracking-wide">Devices</h2>
	<div class="card overflow-hidden">
		{#if a.devices.length === 0}
			<div class="px-5 py-10 text-center text-sm text-gray-500">No devices registered.</div>
		{:else}
			<ul class="divide-y divide-gray-100">
				{#each a.devices as d (d.id)}
					<li class="px-5 py-3 flex items-center justify-between">
						<div class="flex items-center gap-3">
							<Smartphone size={16} class="text-gray-400" />
							<div>
								<div class="text-sm font-medium text-gray-900">
									{d.platform}{d.appVersion ? ` · v${d.appVersion}` : ''}
								</div>
								<div class="text-xs text-gray-500">Last seen {fmt(d.lastSeenAt)}</div>
							</div>
						</div>
						{#if d.pushToken}
							<span class="chip bg-blue-50 text-blue-700">push enabled</span>
						{/if}
					</li>
				{/each}
			</ul>
		{/if}
	</div>
</section>
