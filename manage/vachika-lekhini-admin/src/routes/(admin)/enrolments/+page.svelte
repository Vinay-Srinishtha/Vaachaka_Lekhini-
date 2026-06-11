<script lang="ts">
	import PageHeader from '$lib/components/PageHeader.svelte';
	import DataTable from '$lib/components/DataTable.svelte';
	import type { Column } from '$lib/components/DataTable.types';
	import { page } from '$app/state';

	let { data } = $props();

	const voiceCols: Column[] = [
		{ key: 'member', label: 'Member' },
		{ key: 'mantra', label: 'Mantra' },
		{ key: 'sampleCount', label: 'Samples', align: 'right' },
		{ key: 'qualityScore', label: 'Quality', align: 'right' },
		{ key: 'enrolledAt', label: 'Enrolled', sortable: true }
	];

	const hwCols: Column[] = [
		{ key: 'member', label: 'Member' },
		{ key: 'mantra', label: 'Mantra' },
		{ key: 'mode', label: 'Mode' },
		{ key: 'personalized', label: 'Personalised' },
		{ key: 'createdAt', label: 'Date', sortable: true }
	];

	function fmt(d: Date | string) {
		return new Date(d).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
	}

	function buildTab(t: string) {
		const u = new URL(page.url.toString());
		u.searchParams.set('tab', t);
		u.searchParams.set('page', '1');
		return u.toString();
	}

	function hwModeChip(m: string) {
		if (m === 'writeOnScreen') return 'bg-blue-100 text-blue-700';
		if (m === 'captureCamera') return 'bg-green-100 text-green-700';
		if (m === 'uploadGallery') return 'bg-amber-100 text-amber-700';
		return 'bg-gray-100 text-gray-600';
	}
</script>

<PageHeader title="Enrolments" subtitle="Voice fingerprints and handwriting samples per member" />

<div class="mb-4 flex gap-2">
	<a href={buildTab('voice')} class="px-4 py-2 rounded-lg text-sm font-medium border transition
		{data.tab === 'voice' ? 'bg-brand-600 text-white border-brand-600' : 'bg-white text-gray-600 border-gray-200 hover:border-brand-400'}">
		🎤 Voice ({data.tab === 'voice' ? data.total : '—'})
	</a>
	<a href={buildTab('handwriting')} class="px-4 py-2 rounded-lg text-sm font-medium border transition
		{data.tab === 'handwriting' ? 'bg-brand-600 text-white border-brand-600' : 'bg-white text-gray-600 border-gray-200 hover:border-brand-400'}">
		✍️ Handwriting ({data.tab === 'handwriting' ? data.total : '—'})
	</a>
</div>

{#if data.tab === 'voice'}
	<DataTable
		columns={voiceCols}
		rows={data.voiceRows}
		total={data.total}
		currentPage={data.query.page}
		pageSize={data.query.pageSize}
		defaultSort={{ col: 'enrolledAt', dir: 'desc' }}
		searchPlaceholder="Search by member name…"
		emptyTitle="No voice enrolments"
		emptyHint="Voice enrolments appear when members complete voice setup in the app."
	>
		{#snippet row(v)}
			<tr class="hover:bg-gray-50">
				<td class="px-4 py-3 text-sm font-medium text-gray-900">{v.member.displayName}</td>
				<td class="px-4 py-3 text-sm text-gray-700">{v.mantra.nameRoman}</td>
				<td class="px-4 py-3 text-right tabular-nums text-sm text-gray-700">{v.sampleCount}</td>
				<td class="px-4 py-3 text-right tabular-nums text-sm text-gray-700">
					{v.qualityScore != null ? (v.qualityScore * 100).toFixed(0) + '%' : '—'}
				</td>
				<td class="px-4 py-3 text-sm text-gray-500">{fmt(v.enrolledAt)}</td>
			</tr>
		{/snippet}
	</DataTable>
{:else}
	<DataTable
		columns={hwCols}
		rows={data.hwRows}
		total={data.total}
		currentPage={data.query.page}
		pageSize={data.query.pageSize}
		defaultSort={{ col: 'createdAt', dir: 'desc' }}
		searchPlaceholder="Search by member name…"
		emptyTitle="No handwriting samples"
		emptyHint="Handwriting samples appear when members complete handwriting setup in the app."
	>
		{#snippet row(h)}
			<tr class="hover:bg-gray-50">
				<td class="px-4 py-3 text-sm font-medium text-gray-900">{h.member.displayName}</td>
				<td class="px-4 py-3 text-sm text-gray-700">{h.mantra.nameRoman}</td>
				<td class="px-4 py-3"><span class="chip {hwModeChip(h.mode)}">{h.mode}</span></td>
				<td class="px-4 py-3">
					{#if h.isPersonalized}
						<span class="chip bg-green-100 text-green-700">Yes</span>
					{:else}
						<span class="text-sm text-gray-400">—</span>
					{/if}
				</td>
				<td class="px-4 py-3 text-sm text-gray-500">{fmt(h.createdAt)}</td>
			</tr>
		{/snippet}
	</DataTable>
{/if}
