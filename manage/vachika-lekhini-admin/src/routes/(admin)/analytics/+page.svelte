<script lang="ts">
	import PageHeader from '$lib/components/PageHeader.svelte';
	import StatCard from '$lib/components/StatCard.svelte';
	import BarChart from '$lib/components/BarChart.svelte';
	import DonutChart from '$lib/components/DonutChart.svelte';
	import {
		Users, UserCheck, Activity, Layers,
		TrendingUp, TrendingDown, Coins, Zap, Mic2, PenLine, Hand
	} from '@lucide/svelte';

	let { data } = $props();
	const s = $derived(data.stats);

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
	const totalSplit = $derived(donutData.reduce((a: number, d: { value: number }) => a + d.value, 0) || 1);

	const barData7 = $derived(
		s.sessions7d.map((d: { day: string; count: number }) => ({
			label: d.day,
			secondary: new Date(d.day + 'T00:00:00').toLocaleDateString('en-IN', { weekday: 'short' }),
			value: d.count,
		}))
	);

	const maxMember = $derived(Math.max(...data.topMembers.map((m: { total: number }) => m.total), 1));
	const maxMantra = $derived(Math.max(...data.topMantras.map((m: { count: number }) => m.count), 1));
</script>

<PageHeader title="Analytics" subtitle="Platform-wide usage metrics and trends" />

<!-- Key metrics -->
<section class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
	<StatCard label="Accounts"       value={s.totalAccounts}                  icon={Users}        />
	<StatCard label="Members"        value={s.totalMembers}                   icon={UserCheck}    tone="green" />
	<StatCard label="Total sessions" value={s.totalSessions.toLocaleString()} icon={Activity}     tone="brand" />
	<StatCard label="Sessions (24h)" value={s.recentActivity}                 icon={Zap}          tone="blue"  hint="Last 24 hours" />
	<StatCard label="Programs"       value={s.totalPrograms}                  icon={Layers}       tone="gray" />
	<StatCard label="Active programs"value={s.activePrograms}                 icon={Layers}       tone="blue"  hint="Not yet completed" />
	<StatCard label="Points earned"  value={s.totalRewardEarned.toLocaleString()} icon={TrendingUp}  tone="green" />
	<StatCard label="Points spent"   value={s.totalRewardSpent.toLocaleString()}  icon={TrendingDown} tone="red" />
</section>

<!-- Charts row -->
<div class="grid grid-cols-1 lg:grid-cols-3 gap-5 mb-6">

	<!-- 7-day bar chart -->
	<div class="card p-5 lg:col-span-2">
		<div class="flex items-center justify-between mb-4">
			<h2 class="font-bold text-gray-900 text-sm">Sessions — last 7 days</h2>
			<span class="text-xs text-gray-400">{s.sessions30d.toLocaleString()} in last 30 days</span>
		</div>
		<BarChart data={barData7} height={150} showValues={true} />
	</div>

	<!-- Modality donut -->
	<div class="card p-5">
		<h2 class="font-bold text-gray-900 text-sm mb-4">Session modality split</h2>
		{#if donutData.length === 0}
			<div class="h-32 grid place-items-center text-sm text-gray-400">No sessions yet.</div>
		{:else}
			<div class="flex flex-col items-center gap-4">
				<DonutChart data={donutData} size={130} thickness={26} />
				<div class="w-full space-y-2">
					{#each donutData as slice}
						<div>
							<div class="flex items-center justify-between text-xs mb-1">
								<div class="flex items-center gap-1.5">
									{#if slice.label === 'voice'}
										<Mic2 size={12} style="color:{slice.color}" />
									{:else if slice.label === 'handwriting'}
										<PenLine size={12} style="color:{slice.color}" />
									{:else}
										<Hand size={12} style="color:{slice.color}" />
									{/if}
									<span class="font-medium text-gray-700 capitalize">{slice.label}</span>
								</div>
								<span class="font-bold tabular-nums text-gray-500">
									{slice.value.toLocaleString()} ({Math.round((slice.value / totalSplit) * 100)}%)
								</span>
							</div>
							<div class="h-1.5 rounded-full bg-gray-100 overflow-hidden">
								<div
									class="h-1.5 rounded-full"
									style="width:{Math.round((slice.value / totalSplit) * 100)}%; background:{slice.color}"
								></div>
							</div>
						</div>
					{/each}
				</div>
			</div>
		{/if}
	</div>
</div>

<!-- Top members + top mantras -->
<div class="grid grid-cols-1 lg:grid-cols-2 gap-5">

	<!-- Top members -->
	<div class="card overflow-hidden">
		<div class="px-5 py-3.5 border-b border-gray-100">
			<h2 class="font-bold text-gray-900 text-sm">Top members by total chants</h2>
		</div>
		{#if data.topMembers.length === 0}
			<div class="px-5 py-10 text-center text-sm text-gray-400">No data yet.</div>
		{:else}
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

	<!-- Top mantras -->
	<div class="card overflow-hidden">
		<div class="px-5 py-3.5 border-b border-gray-100">
			<h2 class="font-bold text-gray-900 text-sm">Top mantras by session count</h2>
		</div>
		{#if data.topMantras.length === 0}
			<div class="px-5 py-10 text-center text-sm text-gray-400">No data yet.</div>
		{:else}
			<ul class="divide-y divide-gray-50">
				{#each data.topMantras as item, i}
					<li class="px-5 py-3">
						<div class="flex items-center justify-between gap-3 mb-1.5">
							<div class="flex items-center gap-2 min-w-0">
								<span class="w-5 h-5 rounded-full bg-brand-50 text-brand-700 text-[10px] font-bold grid place-items-center shrink-0">{i + 1}</span>
								<span class="text-sm font-medium text-gray-900 truncate">{item.name}</span>
							</div>
							<span class="text-xs font-bold tabular-nums text-gray-500 shrink-0">{item.count.toLocaleString()}</span>
						</div>
						<div class="h-1.5 rounded-full bg-gray-100 overflow-hidden">
							<div class="h-1.5 rounded-full bg-brand-400" style="width:{Math.round((item.count / maxMantra) * 100)}%"></div>
						</div>
					</li>
				{/each}
			</ul>
		{/if}
	</div>
</div>
