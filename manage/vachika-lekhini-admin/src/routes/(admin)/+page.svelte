<script lang="ts">
	import StatCard from '$lib/components/StatCard.svelte';
	import BarChart from '$lib/components/BarChart.svelte';
	import DonutChart from '$lib/components/DonutChart.svelte';
	import {
		BookOpen, ShoppingBag, Users, UserCheck,
		Activity, Smartphone, Layers, Mic2, PenLine, Hand,
		TrendingUp, TrendingDown, CalendarDays, Flame, Trophy, Zap, CheckCircle2
	} from '@lucide/svelte';

	let { data } = $props();
	const s = $derived(data.stats);

	function fmtDate(d: Date | string) {
		return new Date(d).toLocaleDateString('en-IN', { year: 'numeric', month: 'short', day: 'numeric' });
	}

	const MODALITY_COLORS: Record<string, string> = {
		voice:       '#a855f7',
		handwriting: '#f59e0b',
		manual:      '#3b82f6',
	};
	const donutData = $derived(
		data.modalitySplit.map((m: { modality: string; _count: number }) => ({
			label: m.modality,
			value: m._count,
			color: MODALITY_COLORS[m.modality] ?? '#6b7280',
		}))
	);
	const totalSessions = $derived(donutData.reduce((a: number, d: { value: number }) => a + d.value, 0) || 1);

	const barData30 = $derived(
		data.sessions30d.map((d: { day: string; count: number }) => ({
			label: d.day,
			secondary: d.day.split(' ')[0],
			value: d.count,
		}))
	);

	const barData7 = $derived(
		data.sessions7d.map((d: { day: string; count: number; weekday: string }) => ({
			label: d.weekday,
			secondary: d.day.split(' ')[0],
			value: d.count,
		}))
	);
</script>

<div class="space-y-6">

	<!-- ── Hero stat grid ── -->
	<section class="grid grid-cols-2 lg:grid-cols-4 gap-4">
		<StatCard
			label="Sessions Today"
			value={s.sessionsToday.toLocaleString()}
			hint="vs yesterday"
			icon={Activity}
			tone="brand"
			delta={s.sessionsDelta}
			spark={data.spark7}
		/>
		<StatCard label="Sessions (24h)" value={s.sessions24h.toLocaleString()} icon={Zap} tone="blue" hint="Last 24 hours" />
		<StatCard label="Members" value={s.memberCount.toLocaleString()} icon={UserCheck} tone="green" hint="Family members registered" />
		<StatCard label="Devices" value={s.deviceCount.toLocaleString()} icon={Smartphone} tone="gray" hint="Registered installs" />

		<StatCard label="Total Sessions" value={s.sessionCount.toLocaleString()} icon={TrendingUp} tone="brand" hint="All time" />
		<StatCard label="Accounts" value={s.accountCount.toLocaleString()} icon={Users} tone="gray"
			hint={s.bannedAccountCount > 0 ? `${s.bannedAccountCount} banned` : 'All active'} />
		<StatCard label="Active Programs" value={s.activePrograms.toLocaleString()} icon={Layers} tone="blue" hint="In progress" />
		<StatCard label="Completed Programs" value={s.completedPrograms.toLocaleString()} icon={CheckCircle2} tone="green" hint="Goal reached" />

		<StatCard label="Points Earned" value={s.rewardEarned.toLocaleString()} icon={TrendingUp} tone="green" hint="All time" />
		<StatCard label="Points Spent" value={s.rewardSpent.toLocaleString()} icon={TrendingDown} tone="red" hint="Redeemed" />
		<StatCard label="Mantras" value={s.mantraCount.toLocaleString()} icon={BookOpen} tone="amber" hint={`${s.activeMantras} visible in app`} />
		<StatCard label="Store Items" value={s.storeCount.toLocaleString()} icon={ShoppingBag} tone="blue" hint="Active listings" />
	</section>

	<!-- ── Charts row ── -->
	<section class="grid grid-cols-1 lg:grid-cols-3 gap-4">

		<!-- 30-day bar chart -->
		<div class="card p-5 lg:col-span-2">
			<div class="flex items-center justify-between mb-4">
				<div>
					<h2 class="font-bold text-gray-900 text-sm">Sessions — last 30 days</h2>
					<p class="text-xs text-gray-400 mt-0.5">{s.sessionCount.toLocaleString()} sessions all-time</p>
				</div>
				<div class="flex items-center gap-1.5 text-xs text-gray-400">
					<CalendarDays size={13} />30d
				</div>
			</div>
			<BarChart data={barData30} height={140} showValues={false} />
		</div>

		<!-- Modality donut -->
		<div class="card p-5">
			<h2 class="font-bold text-gray-900 text-sm mb-4">Session type split</h2>
			{#if donutData.length === 0}
				<div class="h-32 grid place-items-center text-sm text-gray-400">No sessions yet.</div>
			{:else}
				<div class="flex items-center gap-5">
					<div class="shrink-0">
						<DonutChart data={donutData} size={120} thickness={22} />
					</div>
					<div class="space-y-2.5 flex-1 min-w-0">
						{#each donutData as slice}
							<div class="flex items-center justify-between gap-2">
								<div class="flex items-center gap-2 min-w-0">
									{#if slice.label === 'voice'}
										<Mic2 size={13} class="shrink-0" style="color:{slice.color}" />
									{:else if slice.label === 'handwriting'}
										<PenLine size={13} class="shrink-0" style="color:{slice.color}" />
									{:else}
										<Hand size={13} class="shrink-0" style="color:{slice.color}" />
									{/if}
									<span class="text-xs font-medium text-gray-700 capitalize truncate">{slice.label}</span>
								</div>
								<span class="text-xs font-bold tabular-nums text-gray-500">
									{slice.value.toLocaleString()} ({Math.round((slice.value / totalSessions) * 100)}%)
								</span>
							</div>
						{/each}
					</div>
				</div>
				<div class="mt-4 space-y-1.5">
					{#each donutData as slice}
						<div class="h-1.5 rounded-full bg-gray-100 overflow-hidden">
							<div class="h-1.5 rounded-full transition-all"
								style="width:{Math.round((slice.value / totalSessions) * 100)}%; background:{slice.color}"
							></div>
						</div>
					{/each}
				</div>
			{/if}
		</div>
	</section>

	<!-- ── 7-day detail + top members ── -->
	<section class="grid grid-cols-1 lg:grid-cols-3 gap-4">

		<!-- 7-day bar chart -->
		<div class="card p-5 lg:col-span-2">
			<div class="flex items-center justify-between mb-4">
				<h2 class="font-bold text-gray-900 text-sm">Sessions — last 7 days</h2>
				<span class="text-xs text-gray-400">{data.sessions7d.reduce((a: number, d: { count: number }) => a + d.count, 0).toLocaleString()} this week</span>
			</div>
			<BarChart data={barData7} height={140} showValues={true} />
		</div>

		<!-- Top members by progress -->
		<div class="card overflow-hidden">
			<div class="px-5 py-3.5 border-b border-gray-100">
				<h2 class="font-bold text-gray-900 text-sm">Top members by progress</h2>
			</div>
			{#if data.topMembers.length === 0}
				<div class="px-5 py-10 text-center text-sm text-gray-400">No data yet.</div>
			{:else}
				{@const maxMember = Math.max(...data.topMembers.map((m: { total: number }) => m.total), 1)}
				<ul class="divide-y divide-gray-50">
					{#each data.topMembers as item, i}
						<li class="px-5 py-3">
							<div class="flex items-center justify-between gap-3 mb-1.5">
								<div class="flex items-center gap-2 min-w-0">
									<span class="w-5 h-5 rounded-full bg-green-50 text-green-700 text-[10px] font-bold grid place-items-center shrink-0">{i + 1}</span>
									<span class="text-sm font-medium text-gray-900 truncate">{item.name}</span>
								</div>
								<span class="text-xs font-bold tabular-nums text-gray-500 shrink-0">{item.total.toLocaleString()}</span>
							</div>
							<div class="h-1.5 rounded-full bg-gray-100 overflow-hidden">
								<div class="h-1.5 rounded-full bg-green-400" style="width:{Math.round((item.total / maxMember) * 100)}%"></div>
							</div>
						</li>
					{/each}
				</ul>
			{/if}
		</div>
	</section>

	<!-- ── Recent accounts + top mantras ── -->
	<section class="grid grid-cols-1 lg:grid-cols-2 gap-4">
		<div class="card overflow-hidden">
			<div class="px-5 py-3.5 border-b border-gray-100 flex items-center justify-between">
				<h2 class="font-bold text-gray-900 text-sm">Recent accounts</h2>
				<a href="/accounts" class="text-xs text-brand-600 hover:underline font-medium">View all →</a>
			</div>
			{#if data.recentAccounts.length === 0}
				<div class="px-5 py-10 text-center text-sm text-gray-400">No accounts yet.</div>
			{:else}
				<ul class="divide-y divide-gray-50">
					{#each data.recentAccounts as a (a.id)}
						<li class="px-5 py-3 flex items-center justify-between gap-3">
							<div class="min-w-0">
								<div class="text-sm font-semibold text-gray-900 truncate">{a.mobile}</div>
								<div class="text-xs text-gray-400">
									{a._count.members} {a._count.members === 1 ? 'member' : 'members'} · {fmtDate(a.createdAt)}
								</div>
							</div>
							{#if a.isBanned}
								<span class="chip bg-red-100 text-red-700 shrink-0">banned</span>
							{:else}
								<span class="chip bg-emerald-100 text-emerald-700 shrink-0">active</span>
							{/if}
						</li>
					{/each}
				</ul>
			{/if}
		</div>

		<div class="card overflow-hidden">
			<div class="px-5 py-3.5 border-b border-gray-100 flex items-center justify-between">
				<h2 class="font-bold text-gray-900 text-sm">Top mantras by program count</h2>
				<a href="/mantras" class="text-xs text-brand-600 hover:underline font-medium">Manage →</a>
			</div>
			{#if data.topMantras.length === 0}
				<div class="px-5 py-10 text-center text-sm text-gray-400">No programs created yet.</div>
			{:else}
				{@const maxCount = Math.max(...data.topMantras.map((m: { count: number }) => m.count), 1)}
				<ul class="divide-y divide-gray-50">
					{#each data.topMantras as row, i (row.name)}
						<li class="px-5 py-3">
							<div class="flex items-center justify-between gap-3 mb-1.5">
								<div class="flex items-center gap-2 min-w-0">
									<span class="w-5 h-5 rounded-full bg-brand-50 text-brand-700 text-[10px] font-bold grid place-items-center shrink-0">{i + 1}</span>
									<span class="text-sm font-medium text-gray-900 truncate">{row.name}</span>
								</div>
								<span class="text-xs tabular-nums font-bold text-gray-500 shrink-0">{row.count}</span>
							</div>
							<div class="h-1.5 rounded-full bg-gray-100 overflow-hidden">
								<div class="h-1.5 rounded-full bg-brand-400 transition-all" style="width:{Math.round((row.count / maxCount) * 100)}%"></div>
							</div>
						</li>
					{/each}
				</ul>
			{/if}
		</div>
	</section>

	<!-- ── Leaderboards ── -->
	<section class="grid grid-cols-1 md:grid-cols-3 gap-4">
		{@const boards = [
			{ key: 'streak',   title: 'Longest Streak',      unit: 'days',     icon: Flame,  color: '#f97316' },
			{ key: 'progress', title: 'Highest Total Progress', unit: 'chants', icon: Trophy, color: '#a855f7' },
			{ key: 'sessions', title: 'Most Sessions',        unit: 'sessions', icon: Zap,    color: '#3b82f6' },
		]}
		{#each boards as board}
			{@const rows = (data.leaderboards as Record<string, { name: string; mobile: string; value: number }[]>)[board.key] ?? []}
			{@const maxVal = Math.max(...rows.map((r) => r.value), 1)}
			<div class="card overflow-hidden">
				<div class="px-5 py-3.5 border-b border-gray-100 flex items-center gap-2">
					<board.icon size={15} style="color:{board.color}" />
					<h2 class="font-bold text-gray-900 text-sm">{board.title}</h2>
				</div>
				{#if rows.length === 0}
					<div class="px-5 py-8 text-center text-sm text-gray-400">No data yet.</div>
				{:else}
					<ul class="divide-y divide-gray-50">
						{#each rows as row, i (row.mobile + row.name)}
							<li class="px-5 py-2.5">
								<div class="flex items-center justify-between gap-2 mb-1">
									<div class="flex items-center gap-2 min-w-0">
										<span class="w-5 h-5 rounded-full text-[10px] font-bold grid place-items-center shrink-0
											{i === 0 ? 'bg-amber-100 text-amber-700' : i === 1 ? 'bg-gray-100 text-gray-600' : i === 2 ? 'bg-orange-50 text-orange-600' : 'bg-gray-50 text-gray-400'}"
										>{i + 1}</span>
										<div class="min-w-0">
											<div class="text-xs font-semibold text-gray-900 truncate">{row.name}</div>
											<div class="text-[10px] text-gray-400 truncate">{row.mobile}</div>
										</div>
									</div>
									<span class="text-xs font-bold tabular-nums shrink-0" style="color:{board.color}">
										{row.value.toLocaleString()} <span class="font-normal text-gray-400">{board.unit}</span>
									</span>
								</div>
								<div class="h-1 rounded-full bg-gray-100 overflow-hidden">
									<div class="h-1 rounded-full transition-all"
										style="width:{Math.round((row.value / maxVal) * 100)}%; background:{board.color}; opacity:0.6"
									></div>
								</div>
							</li>
						{/each}
					</ul>
				{/if}
			</div>
		{/each}
	</section>

</div>
