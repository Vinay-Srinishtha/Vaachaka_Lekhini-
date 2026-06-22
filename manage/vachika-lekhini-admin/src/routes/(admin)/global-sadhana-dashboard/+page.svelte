<script lang="ts">
	import { Users, Flame, BarChart2, Zap, CheckCircle2, Clock, PauseCircle, FileText, ExternalLink } from '@lucide/svelte';

	let { data } = $props();

	// Build last-30-day date labels
	function last30Days(): string[] {
		const days: string[] = [];
		for (let i = 29; i >= 0; i--) {
			const d = new Date();
			d.setDate(d.getDate() - i);
			days.push(d.toISOString().slice(0, 10));
		}
		return days;
	}
	const days = last30Days();

	function pct(current: number, target: number) {
		if (target <= 0) return 0;
		return Math.min(100, Math.round((current / target) * 100));
	}

	function fmt(n: number) {
		if (n >= 10_000_000) return (n / 10_000_000).toFixed(1) + 'Cr';
		if (n >= 100_000) return (n / 100_000).toFixed(1) + 'L';
		if (n >= 1000) return (n / 1000).toFixed(1) + 'k';
		return n.toLocaleString();
	}

	function fmtDate(d: string | Date | null) {
		if (!d) return '—';
		return new Date(d).toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' });
	}

	const statusIcon: Record<string, typeof Flame> = {
		active: Flame,
		paused: PauseCircle,
		completed: CheckCircle2,
		draft: FileText,
		published: Clock,
		archived: Clock,
	};

	const statusColor: Record<string, string> = {
		active:    'bg-green-100 text-green-700 border-green-200',
		paused:    'bg-yellow-100 text-yellow-700 border-yellow-200',
		completed: 'bg-indigo-100 text-indigo-700 border-indigo-200',
		draft:     'bg-slate-100 text-slate-500 border-slate-200',
		published: 'bg-sky-100 text-sky-700 border-sky-200',
		archived:  'bg-slate-100 text-slate-400 border-slate-200',
	};

	const modalityColor: Record<string, string> = {
		chanting:    'bg-orange-100 text-orange-700',
		handwriting: 'bg-teal-100 text-teal-700',
		voice:       'bg-purple-100 text-purple-700',
	};

	// Summary stats
	const total      = data.sadhanas.length;
	const active     = data.sadhanas.filter((s: any) => s.status === 'active').length;
	const completed  = data.sadhanas.filter((s: any) => s.status === 'completed').length;
	const totalChants = data.sadhanas.reduce((a: number, s: any) => a + s.currentCount, 0);
	const totalEnrollments = data.sadhanas.reduce((a: number, s: any) => a + s._count.enrollments, 0);

	// Sparkline SVG for a sadhana's last-30-day activity
	function sparkline(sadId: string): string {
		const daily = data.dailyMap[sadId] ?? {};
		const vals = days.map(d => daily[d] ?? 0);
		const max = Math.max(...vals, 1);
		const W = 120, H = 32, pad = 2;
		const pts = vals.map((v, i) => {
			const x = pad + (i / (vals.length - 1)) * (W - pad * 2);
			const y = H - pad - ((v / max) * (H - pad * 2));
			return `${x.toFixed(1)},${y.toFixed(1)}`;
		}).join(' ');
		return `<svg viewBox="0 0 ${W} ${H}" xmlns="http://www.w3.org/2000/svg" class="w-full h-8">
			<polyline points="${pts}" fill="none" stroke="#E8893B" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round"/>
		</svg>`;
	}
</script>

<div class="mb-6">
	<h1 class="text-xl font-semibold text-slate-900">Global Sadhana Dashboard</h1>
	<p class="mt-1 text-sm text-slate-500">Detailed progress across all global sadhanas</p>
</div>

<!-- Summary stats -->
<div class="mb-6 grid grid-cols-2 md:grid-cols-5 gap-3">
	{#each [
		{ label: 'Total',        value: total,           icon: BarChart2, color: 'text-slate-700 bg-slate-50  border-slate-200' },
		{ label: 'Active',       value: active,          icon: Flame,     color: 'text-green-700 bg-green-50  border-green-200' },
		{ label: 'Completed',    value: completed,       icon: CheckCircle2, color: 'text-indigo-700 bg-indigo-50 border-indigo-200' },
		{ label: 'Total Chants', value: fmt(totalChants),icon: Zap,       color: 'text-orange-700 bg-orange-50 border-orange-200' },
		{ label: 'Enrollments',  value: fmt(totalEnrollments), icon: Users, color: 'text-teal-700 bg-teal-50 border-teal-200' },
	] as stat}
		<div class="rounded-xl border {stat.color} px-4 py-3 flex items-center gap-3">
			<svelte:component this={stat.icon} size={20} class="shrink-0 opacity-70" />
			<div>
				<div class="text-xl font-bold leading-tight">{stat.value}</div>
				<div class="text-xs font-medium opacity-70">{stat.label}</div>
			</div>
		</div>
	{/each}
</div>

<!-- Per-sadhana cards -->
<div class="space-y-5">
	{#each data.sadhanas as s (s.id)}
		{@const progress = pct(s.currentCount, s.targetCount)}
		{@const topContribs = data.topMap[s.id] ?? []}
		{@const modality = data.modalityMap[s.id] ?? {}}
		{@const totalModal = Object.values(modality).reduce((a: number, v) => a + (v as number), 0)}
		<div class="rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden">
			<!-- Header -->
			<div class="flex items-start gap-4 p-5 pb-3">
				{#if s.imageUrl}
					<img src={s.imageUrl} alt="" class="w-14 h-14 rounded-xl object-cover border border-slate-100 shrink-0" />
				{:else}
					<div class="w-14 h-14 rounded-xl bg-orange-50 border border-orange-100 grid place-items-center shrink-0">
						<svelte:component this={Flame} size={24} class="text-orange-400" />
					</div>
				{/if}
				<div class="flex-1 min-w-0">
					<div class="flex flex-wrap items-center gap-2">
						<h2 class="text-base font-semibold text-slate-900 truncate">{s.title}</h2>
						{#if s.isSponsored}
							<span class="text-[10px] font-bold bg-amber-100 text-amber-700 border border-amber-200 rounded-full px-2 py-0.5">SPONSORED</span>
						{/if}
						<span class="inline-flex items-center gap-1 text-[11px] font-semibold border rounded-full px-2 py-0.5 {statusColor[s.status] ?? 'bg-slate-100 text-slate-500'}">
							{s.status}
						</span>
					</div>
					<p class="text-xs text-slate-500 mt-0.5">
						{s.mantra?.nameRoman ?? '—'}
						{#if s.startAt}· {fmtDate(s.startAt)}{#if s.endAt} → {fmtDate(s.endAt)}{/if}{/if}
					</p>
				</div>
				<a href="/global-sadhana/{s.id}" class="text-slate-400 hover:text-brand-600 shrink-0 mt-0.5" title="Edit">
					<svelte:component this={ExternalLink} size={15} />
				</a>
			</div>

			<!-- Progress bar -->
			<div class="px-5 pb-3">
				<div class="flex justify-between text-xs text-slate-500 mb-1">
					<span>{s.currentCount.toLocaleString()} chants</span>
					<span>{progress}% of {fmt(s.targetCount)}</span>
				</div>
				<div class="h-2.5 rounded-full bg-slate-100 overflow-hidden">
					<div
						class="h-full rounded-full transition-all duration-500 {progress >= 100 ? 'bg-indigo-500' : progress >= 70 ? 'bg-orange-500' : 'bg-orange-400'}"
						style="width:{progress}%"
					></div>
				</div>
			</div>

			<!-- Stats grid -->
			<div class="px-5 pb-4 grid grid-cols-2 md:grid-cols-4 gap-3 text-center">
				<div class="rounded-lg bg-slate-50 px-3 py-2">
					<div class="text-sm font-bold text-slate-800">{s._count.enrollments.toLocaleString()}</div>
					<div class="text-[10px] text-slate-500 uppercase tracking-wide">Enrolled</div>
				</div>
				<div class="rounded-lg bg-slate-50 px-3 py-2">
					<div class="text-sm font-bold text-slate-800">{s._count.contributions.toLocaleString()}</div>
					<div class="text-[10px] text-slate-500 uppercase tracking-wide">Sessions</div>
				</div>
				<div class="rounded-lg bg-slate-50 px-3 py-2">
					<div class="text-sm font-bold text-slate-800">{s.participationMode}</div>
					<div class="text-[10px] text-slate-500 uppercase tracking-wide">Mode</div>
				</div>
				<div class="rounded-lg bg-slate-50 px-3 py-2">
					<div class="text-sm font-bold text-slate-800">{s.targetCount > 0 ? fmt(s.targetCount - s.currentCount) : '—'}</div>
					<div class="text-[10px] text-slate-500 uppercase tracking-wide">Remaining</div>
				</div>
			</div>

			<!-- Bottom: sparkline + modality + top contributors -->
			<div class="border-t border-slate-100 px-5 py-4 grid grid-cols-1 md:grid-cols-3 gap-5">

				<!-- 30-day activity sparkline -->
				<div>
					<div class="text-[10px] font-semibold text-slate-400 uppercase tracking-wide mb-2">Last 30 days</div>
					{@html sparkline(s.id)}
				</div>

				<!-- Modality breakdown -->
				<div>
					<div class="text-[10px] font-semibold text-slate-400 uppercase tracking-wide mb-2">Modality</div>
					{#if totalModal === 0}
						<p class="text-xs text-slate-400 italic">No contributions yet</p>
					{:else}
						<div class="space-y-1.5">
							{#each Object.entries(modality) as [mode, count]}
								{@const modPct = totalModal > 0 ? Math.round(((count as number) / totalModal) * 100) : 0}
								<div class="flex items-center gap-2 text-xs">
									<span class="w-20 truncate capitalize {modalityColor[mode] ?? 'bg-slate-100 text-slate-600'} rounded px-1.5 py-0.5 text-[10px] font-semibold">{mode}</span>
									<div class="flex-1 h-1.5 rounded-full bg-slate-100">
										<div class="h-full rounded-full bg-orange-400" style="width:{modPct}%"></div>
									</div>
									<span class="w-8 text-right text-slate-500">{modPct}%</span>
								</div>
							{/each}
						</div>
					{/if}
				</div>

				<!-- Top contributors -->
				<div>
					<div class="text-[10px] font-semibold text-slate-400 uppercase tracking-wide mb-2">Top Contributors</div>
					{#if topContribs.length === 0}
						<p class="text-xs text-slate-400 italic">No contributions yet</p>
					{:else}
						<ol class="space-y-1">
							{#each topContribs as c, i}
								<li class="flex items-center gap-2 text-xs">
									<span class="w-4 text-slate-400 font-semibold text-right">{i + 1}.</span>
									<span class="flex-1 truncate text-slate-700 font-medium">{c.name}</span>
									<span class="text-orange-600 font-semibold tabular-nums">{fmt(c.total)}</span>
								</li>
							{/each}
						</ol>
					{/if}
				</div>
			</div>
		</div>
	{/each}

	{#if data.sadhanas.length === 0}
		<div class="rounded-2xl border border-dashed border-slate-200 py-16 text-center text-slate-400 text-sm">
			No global sadhanas yet.
		</div>
	{/if}
</div>
