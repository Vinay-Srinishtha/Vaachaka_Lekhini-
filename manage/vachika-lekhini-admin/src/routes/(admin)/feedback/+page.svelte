<script lang="ts">
	import { page } from '$app/state';
	import { goto } from '$app/navigation';
	import SearchInput from '$lib/components/SearchInput.svelte';
	import Pagination from '$lib/components/Pagination.svelte';
	import { patchQuery } from '$lib/url';
	import type { PageData } from './$types';
	const { data }: { data: PageData } = $props();

	const statusColor: Record<string, string> = {
		open: 'bg-amber-100 text-amber-800 border-amber-200',
		resolved: 'bg-green-100 text-green-800 border-green-200',
		dismissed: 'bg-gray-100 text-gray-500 border-gray-200'
	};

	const STATUS_TABS = [
		{ value: '', label: 'All' },
		{ value: 'open', label: 'Open' },
		{ value: 'resolved', label: 'Resolved' },
		{ value: 'dismissed', label: 'Dismissed' }
	];

	function setStatus(s: string) {
		goto(patchQuery(page.url, { status: s || null, page: null }), { keepFocus: true, noScroll: true });
	}
</script>

<svelte:head><title>Feedback</title></svelte:head>

<div class="space-y-4">
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-xl font-semibold">User Feedback</h1>
			<p class="text-sm text-gray-500 mt-0.5">Sorted newest first · click a row to view details</p>
		</div>
		<span class="bg-slate-100 text-slate-600 text-xs font-semibold px-3 py-1 rounded-full">{data.total} total</span>
	</div>

	<!-- Search + status filter -->
	<div class="flex flex-col sm:flex-row gap-3">
		<div class="flex-1">
			<SearchInput placeholder="Search by subject, mobile or status…" />
		</div>
		<div class="flex gap-1 shrink-0">
			{#each STATUS_TABS as tab}
				<button
					onclick={() => setStatus(tab.value)}
					class="px-3 py-1.5 text-xs font-semibold rounded-lg border transition-colors {data.status === tab.value
						? 'bg-brand-600 text-white border-brand-600'
						: 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'}"
				>
					{tab.label}
				</button>
			{/each}
		</div>
	</div>

	{#if data.reports.length === 0}
		<div class="flex flex-col items-center justify-center py-16 text-gray-400" role="status">
			<svg class="w-10 h-10 mb-3 opacity-40" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
			</svg>
			<p class="text-sm">{data.query.q ? `No feedback matches "${data.query.q}"` : 'No feedback submitted yet.'}</p>
		</div>
	{:else}
		<div class="bg-white rounded-xl border border-slate-200 overflow-hidden">
			<div class="grid grid-cols-[120px_1fr_160px_110px] gap-4 px-4 py-2 border-b border-slate-100 bg-slate-50 text-xs font-semibold text-slate-500 uppercase tracking-wide">
				<span>Status</span>
				<span>Subject</span>
				<span>From</span>
				<span>Date</span>
			</div>

			{#each data.reports as r (r.id)}
				<a
					href="/feedback/{r.id}"
					class="grid grid-cols-[120px_1fr_160px_110px] gap-4 px-4 py-3 border-b border-slate-100 last:border-0 hover:bg-slate-50 transition-colors items-center group"
				>
					<span class="text-xs font-semibold px-2 py-0.5 rounded-full border w-fit {statusColor[r.status] ?? 'bg-gray-100 text-gray-600 border-gray-200'}">
						{r.status}
					</span>
					<span class="font-medium text-sm text-slate-800 truncate group-hover:text-brand-600 transition-colors">{r.subject}</span>
					<span class="text-xs text-slate-400 truncate">{r.mobile ?? 'anonymous'}</span>
					<span class="text-xs text-slate-400">{new Date(r.createdAt).toLocaleDateString()}</span>
				</a>
			{/each}

			<Pagination total={data.total} pageSize={data.query.pageSize} currentPage={data.query.page} />
		</div>
	{/if}
</div>
