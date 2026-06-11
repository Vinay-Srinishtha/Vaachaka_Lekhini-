<script lang="ts">
	import PageHeader from '$lib/components/PageHeader.svelte';
	import DataTable from '$lib/components/DataTable.svelte';
	import StatCard from '$lib/components/StatCard.svelte';
	import type { Column } from '$lib/components/DataTable.types';
	import { Activity, Zap, Hash, Timer } from '@lucide/svelte';
	import { page } from '$app/state';

	let { data } = $props();

	const columns: Column[] = [
		{ key: 'member',     label: 'Member' },
		{ key: 'mantra',     label: 'Mantra' },
		{ key: 'modality',   label: 'Mode' },
		{ key: 'countAdded', label: 'Count',    align: 'right', sortable: true },
		{ key: 'durationSec',label: 'Duration', align: 'right', sortable: true },
		{ key: 'startedAt',  label: 'Date',     sortable: true }
	];

	const MODALITIES = [
		{ value: '',             label: 'All modes'   },
		{ value: 'voice',        label: 'Voice'       },
		{ value: 'handwriting',  label: 'Handwriting' },
		{ value: 'manual',       label: 'Manual'      },
	];

	function fmt(d: Date | string | null) {
		if (!d) return '—';
		return new Date(d).toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' });
	}

	function fmtDur(s: number) {
		if (!s) return '—';
		if (s < 60) return `${s}s`;
		const m = Math.floor(s / 60), rem = s % 60;
		return rem ? `${m}m ${rem}s` : `${m}m`;
	}

	function modalityChip(m: string) {
		if (m === 'voice')        return 'bg-purple-100 text-purple-700';
		if (m === 'handwriting')  return 'bg-amber-100  text-amber-700';
		return 'bg-blue-100 text-blue-700';
	}

	function buildUrl(mod: string) {
		const u = new URL(page.url.toString());
		if (mod) u.searchParams.set('modality', mod); else u.searchParams.delete('modality');
		u.searchParams.set('page', '1');
		return u.toString();
	}
</script>

<PageHeader title="Practice Sessions" subtitle="Every chant session logged from the Flutter app" />

<!-- Summary cards -->
<div class="grid grid-cols-3 gap-4 mb-6">
	<StatCard label="Today's sessions"  value={data.summary.sessionsToday.toLocaleString()} icon={Zap}      tone="brand" />
	<StatCard label="Total chants"      value={data.summary.totalChants.toLocaleString()}   icon={Hash}     tone="green" hint="All-time cumulative" />
	<StatCard label="Avg session length"value={fmtDur(data.summary.avgDurationSec)}         icon={Timer}    tone="blue"  hint="Across all sessions" />
</div>

<!-- Mode filter tabs -->
<div class="mb-4 flex gap-2 flex-wrap">
	{#each MODALITIES as m}
		<a
			href={buildUrl(m.value)}
			class="px-3.5 py-1.5 rounded-full text-sm font-semibold transition border
				{data.modality === m.value
				? 'bg-brand-600 text-white border-brand-600 shadow-sm'
				: 'bg-white text-gray-600 border-gray-200 hover:border-brand-400 hover:text-brand-600'}"
		>{m.label}</a>
	{/each}
</div>

<DataTable
	{columns}
	rows={data.sessions}
	total={data.total}
	currentPage={data.query.page}
	pageSize={data.query.pageSize}
	defaultSort={{ col: 'startedAt', dir: 'desc' }}
	searchPlaceholder="Search by member or mantra…"
	emptyTitle="No sessions yet"
	emptyHint="Sessions appear once members start practising in the app."
>
	{#snippet row(s)}
		<tr class="hover:bg-gray-50 transition-colors">
			<td class="px-4 py-3 text-sm font-semibold text-gray-900">{s.member.displayName}</td>
			<td class="px-4 py-3 text-sm text-gray-600">{s.program.mantra.nameRoman}</td>
			<td class="px-4 py-3">
				<span class="chip {modalityChip(s.modality)}">{s.modality}</span>
			</td>
			<td class="px-4 py-3 text-right tabular-nums text-sm font-semibold text-gray-900">{s.countAdded.toLocaleString()}</td>
			<td class="px-4 py-3 text-right tabular-nums text-sm text-gray-600">{fmtDur(s.durationSec)}</td>
			<td class="px-4 py-3 text-sm text-gray-400">{fmt(s.startedAt)}</td>
		</tr>
	{/snippet}
</DataTable>
