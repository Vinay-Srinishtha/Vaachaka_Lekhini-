<script lang="ts">
	import {
		Globe, ArrowLeft, Pencil, Users, Target, Mic, PenLine, Hand,
		TrendingUp, CalendarDays, Trophy, Activity
	} from '@lucide/svelte';

	let { data } = $props();
	const s = $derived(data.sadhana);
	const st = $derived(data.stats);

	const STATUS_COLORS: Record<string, string> = {
		draft: 'bg-slate-100 text-slate-600',
		published: 'bg-blue-50 text-blue-700 border border-blue-200',
		active: 'bg-green-50 text-green-700 border border-green-200',
		paused: 'bg-amber-50 text-amber-700 border border-amber-200',
		completed: 'bg-purple-50 text-purple-700 border border-purple-200',
		archived: 'bg-slate-50 text-slate-500 border border-slate-200'
	};
	const STATUS_LABELS: Record<string, string> = {
		draft: 'Draft', published: 'Published', active: 'Active',
		paused: 'Paused', completed: 'Completed', archived: 'Archived'
	};
	const MODALITY = {
		voice: { label: 'Voice chanting', icon: Mic, color: 'bg-brand-500', text: 'text-brand-700', soft: 'bg-brand-50' },
		handwriting: { label: 'Handwriting', icon: PenLine, color: 'bg-blue-500', text: 'text-blue-700', soft: 'bg-blue-50' },
		manual: { label: 'Manual', icon: Hand, color: 'bg-slate-400', text: 'text-slate-600', soft: 'bg-slate-50' }
	} as const;

	function fmt(n: number) {
		return (n ?? 0).toLocaleString('en-IN');
	}
	function dayLabel(iso: string) {
		return new Date(iso).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
	}

	const pct = $derived(s.targetCount > 0 ? Math.min(100, (s.currentCount / s.targetCount) * 100) : 0);
	const remaining = $derived(Math.max(0, s.targetCount - s.currentCount));

	const daysRunning = $derived(
		Math.max(1, Math.ceil((Date.now() - new Date(s.startAt).getTime()) / 86_400_000))
	);
	const avgPerDay = $derived(Math.round(s.currentCount / daysRunning));
	const projectedDays = $derived(avgPerDay > 0 ? Math.ceil(remaining / avgPerDay) : null);

	const avgPerMember = $derived(
		st.activeContributors > 0 ? Math.round(st.totalContributed / st.activeContributors) : 0
	);

	// Activity chart scaling
	const maxDay = $derived(Math.max(1, ...st.series.map((d: any) => d.count)));
	const last7 = $derived(st.series.slice(-7).reduce((a: number, d: any) => a + d.count, 0));

	const modalityTotal = $derived(
		Math.max(1, st.modalityBreakdown.reduce((a: number, m: any) => a + m.total, 0))
	);
</script>

<!-- Header -->
<div class="mb-6 flex flex-wrap items-start justify-between gap-4">
	<div class="min-w-0">
		<a href="/global-sadhana" class="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-700 mb-2">
			<ArrowLeft size={15} /> Back to programs
		</a>
		<h1 class="text-xl font-semibold text-slate-900 flex items-center gap-2 flex-wrap">
			<Globe size={20} class="text-brand-600 shrink-0" />
			<span class="truncate">{s.title}</span>
			<span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold {STATUS_COLORS[s.status]}">
				{STATUS_LABELS[s.status]}
			</span>
			{#if s.isSponsored}
				<span class="inline-flex items-center rounded-full bg-amber-50 px-2 py-0.5 text-xs font-semibold text-amber-700 border border-amber-200">⭐ Sponsored</span>
			{/if}
		</h1>
		<p class="mt-1 text-sm text-slate-500">
			{s.mantra.nameRoman}{s.mantra.nameTelugu ? ` · ${s.mantra.nameTelugu}` : ''} ·
			{s.participationMode === 'both' ? 'Voice & Handwriting' : s.participationMode === 'voice' ? 'Voice only' : 'Handwriting only'} ·
			started {new Date(s.startAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
		</p>
	</div>
	<a href="/global-sadhana/{s.id}/edit" class="inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50 transition-colors">
		<Pencil size={15} /> Edit
	</a>
</div>

<!-- Progress hero -->
<div class="mb-6 rounded-2xl border border-brand-200 bg-gradient-to-br from-brand-50 to-white p-6">
	<div class="flex flex-wrap items-end justify-between gap-4">
		<div>
			<div class="text-sm font-medium text-brand-700 flex items-center gap-1.5">
				<Target size={15} /> Progress to target
			</div>
			<div class="mt-1 text-3xl font-bold text-slate-900">
				{fmt(s.currentCount)} <span class="text-lg font-medium text-slate-400">/ {fmt(s.targetCount)}</span>
			</div>
		</div>
		<div class="text-right">
			<div class="text-3xl font-bold text-brand-600">{pct.toFixed(1)}%</div>
			<div class="text-xs text-slate-500">{fmt(remaining)} remaining</div>
		</div>
	</div>
	<div class="mt-4 h-3 rounded-full bg-white border border-brand-100 overflow-hidden">
		<div class="h-full rounded-full bg-brand-500 transition-all" style="width: {pct}%"></div>
	</div>
	<div class="mt-4 grid grid-cols-2 sm:grid-cols-4 gap-4 text-sm">
		<div>
			<div class="text-slate-400 text-xs">Days running</div>
			<div class="font-semibold text-slate-800">{daysRunning}</div>
		</div>
		<div>
			<div class="text-slate-400 text-xs">Avg / day</div>
			<div class="font-semibold text-slate-800">{fmt(avgPerDay)}</div>
		</div>
		<div>
			<div class="text-slate-400 text-xs">Last 7 days</div>
			<div class="font-semibold text-slate-800">{fmt(last7)}</div>
		</div>
		<div>
			<div class="text-slate-400 text-xs">Projected finish</div>
			<div class="font-semibold text-slate-800">
				{#if s.completedAt}
					Completed
				{:else if projectedDays === null}
					—
				{:else}
					~{projectedDays} day{projectedDays === 1 ? '' : 's'}
				{/if}
			</div>
		</div>
	</div>
</div>

<!-- KPI grid -->
<div class="mb-6 grid grid-cols-2 lg:grid-cols-4 gap-3">
	{#each [
		{ label: 'Members enrolled', value: fmt(st.enrollTotal), sub: 'joined the sadhana', icon: Users, color: 'border-blue-200 bg-blue-50' },
		{ label: 'Active contributors', value: fmt(st.activeContributors), sub: `${st.enrollTotal > 0 ? Math.round((st.activeContributors / st.enrollTotal) * 100) : 0}% of enrolled`, icon: Activity, color: 'border-green-200 bg-green-50' },
		{ label: 'Contributions', value: fmt(st.totalSessions), sub: 'practice sessions', icon: TrendingUp, color: 'border-purple-200 bg-purple-50' },
		{ label: 'Avg / member', value: fmt(avgPerMember), sub: 'chants / writings', icon: Target, color: 'border-amber-200 bg-amber-50' },
	] as card}
		{@const Icon = card.icon}
		<div class="rounded-xl border {card.color} p-4">
			<div class="flex items-center justify-between">
				<div class="text-2xl font-bold text-slate-900">{card.value}</div>
				<Icon size={18} class="text-slate-400" />
			</div>
			<div class="text-sm font-medium text-slate-700 mt-0.5">{card.label}</div>
			<div class="text-xs text-slate-400 mt-0.5">{card.sub}</div>
		</div>
	{/each}
</div>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
	<!-- 30-day activity -->
	<div class="lg:col-span-2 rounded-xl border border-slate-200 bg-white p-5">
		<h2 class="text-sm font-semibold text-slate-800 flex items-center gap-1.5 mb-4">
			<CalendarDays size={15} class="text-slate-400" /> Daily activity · last 30 days
		</h2>
		{#if st.totalSessions === 0}
			<div class="py-12 text-center text-sm text-slate-400">No contributions yet.</div>
		{:else}
			<div class="flex items-end gap-[3px] h-40">
				{#each st.series as d (d.date)}
					<div class="group relative flex-1 flex flex-col justify-end h-full">
						<div
							class="w-full rounded-t bg-brand-400 hover:bg-brand-600 transition-colors"
							style="height: {Math.max(2, (d.count / maxDay) * 100)}%"
						></div>
						<div class="pointer-events-none absolute bottom-full left-1/2 -translate-x-1/2 mb-1 hidden group-hover:block whitespace-nowrap rounded bg-slate-900 px-2 py-1 text-xs text-white z-10">
							{dayLabel(d.date)}: {fmt(d.count)} ({d.sessions} sessions)
						</div>
					</div>
				{/each}
			</div>
			<div class="mt-2 flex justify-between text-[11px] text-slate-400">
				<span>{dayLabel(st.series[0].date)}</span>
				<span>{dayLabel(st.series[st.series.length - 1].date)}</span>
			</div>
		{/if}
	</div>

	<!-- Modality breakdown + training readiness -->
	<div class="space-y-4">
		<div class="rounded-xl border border-slate-200 bg-white p-5">
			<h2 class="text-sm font-semibold text-slate-800 mb-4">By modality</h2>
			{#if st.modalityBreakdown.length === 0}
				<div class="py-6 text-center text-sm text-slate-400">No data yet.</div>
			{:else}
				<div class="space-y-3">
					{#each st.modalityBreakdown as m (m.modality)}
						{@const meta = MODALITY[m.modality as keyof typeof MODALITY] ?? MODALITY.manual}
						{@const Icon = meta.icon}
						<div>
							<div class="flex items-center justify-between text-sm mb-1">
								<span class="inline-flex items-center gap-1.5 {meta.text} font-medium">
									<Icon size={14} /> {meta.label}
								</span>
								<span class="text-slate-500">{fmt(m.total)} · {Math.round((m.total / modalityTotal) * 100)}%</span>
							</div>
							<div class="h-2 rounded-full bg-slate-100 overflow-hidden">
								<div class="h-full rounded-full {meta.color}" style="width: {(m.total / modalityTotal) * 100}%"></div>
							</div>
						</div>
					{/each}
				</div>
			{/if}
		</div>

		<div class="rounded-xl border border-slate-200 bg-white p-5">
			<h2 class="text-sm font-semibold text-slate-800 mb-3">Training readiness</h2>
			<div class="space-y-2 text-sm">
				<div class="flex items-center justify-between">
					<span class="inline-flex items-center gap-1.5 text-slate-600"><Mic size={14} class="text-brand-500" /> Voice trained</span>
					<span class="font-semibold text-slate-800">{fmt(st.voiceTrained)} / {fmt(st.enrollTotal)}</span>
				</div>
				<div class="flex items-center justify-between">
					<span class="inline-flex items-center gap-1.5 text-slate-600"><PenLine size={14} class="text-blue-500" /> Handwriting trained</span>
					<span class="font-semibold text-slate-800">{fmt(st.hwTrained)} / {fmt(st.enrollTotal)}</span>
				</div>
			</div>
		</div>
	</div>
</div>

<!-- Top contributors -->
<div class="mt-4 rounded-xl border border-slate-200 bg-white p-5">
	<h2 class="text-sm font-semibold text-slate-800 flex items-center gap-1.5 mb-4">
		<Trophy size={15} class="text-amber-500" /> Top contributors
	</h2>
	{#if st.topContributors.length === 0}
		<div class="py-8 text-center text-sm text-slate-400">No contributions yet.</div>
	{:else}
		<div class="overflow-x-auto">
			<table class="w-full text-sm">
				<thead>
					<tr class="text-left text-xs text-slate-400 border-b border-slate-100">
						<th class="py-2 pr-3 font-medium">#</th>
						<th class="py-2 pr-3 font-medium">Member</th>
						<th class="py-2 pr-3 font-medium text-right">Contributed</th>
						<th class="py-2 pr-3 font-medium text-right">Sessions</th>
						<th class="py-2 font-medium text-right">% of total</th>
					</tr>
				</thead>
				<tbody>
					{#each st.topContributors as c, i (c.memberId)}
						<tr class="border-b border-slate-50 last:border-0">
							<td class="py-2 pr-3 text-slate-400">{i + 1}</td>
							<td class="py-2 pr-3">
								<div class="font-medium text-slate-800">{c.name}</div>
								{#if c.mobile}<div class="text-xs text-slate-400">{c.mobile}</div>{/if}
							</td>
							<td class="py-2 pr-3 text-right font-semibold text-slate-800">{fmt(c.total)}</td>
							<td class="py-2 pr-3 text-right text-slate-500">{fmt(c.sessions)}</td>
							<td class="py-2 text-right text-slate-500">
								{s.currentCount > 0 ? Math.round((c.total / s.currentCount) * 100) : 0}%
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}
</div>

<!-- Recent contributions -->
<div class="mt-4 rounded-xl border border-slate-200 bg-white p-5">
	<h2 class="text-sm font-semibold text-slate-800 mb-4">Recent contributions</h2>
	{#if st.recent.length === 0}
		<div class="py-8 text-center text-sm text-slate-400">No contributions yet.</div>
	{:else}
		<div class="divide-y divide-slate-50">
			{#each st.recent as r (r.id)}
				{@const meta = MODALITY[r.modality as keyof typeof MODALITY] ?? MODALITY.manual}
				{@const Icon = meta.icon}
				<div class="flex items-center justify-between py-2.5 text-sm">
					<div class="flex items-center gap-2.5 min-w-0">
						<span class="inline-flex items-center justify-center w-7 h-7 rounded-full {meta.soft} {meta.text} shrink-0">
							<Icon size={14} />
						</span>
						<div class="min-w-0">
							<div class="font-medium text-slate-800 truncate">{r.member.displayName}</div>
							<div class="text-xs text-slate-400">{meta.label}</div>
						</div>
					</div>
					<div class="text-right shrink-0">
						<div class="font-semibold text-slate-800">+{fmt(r.countAdded)}</div>
						<div class="text-xs text-slate-400">
							{new Date(r.createdAt).toLocaleString('en-IN', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}
						</div>
					</div>
				</div>
			{/each}
		</div>
	{/if}
</div>
