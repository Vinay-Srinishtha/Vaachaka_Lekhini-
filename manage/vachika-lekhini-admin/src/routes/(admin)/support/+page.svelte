<script lang="ts">
	import type { PageData } from './$types';
	const { data }: { data: PageData } = $props();

	const statusColor: Record<string, string> = {
		open: 'bg-amber-100 text-amber-800 border-amber-200',
		resolved: 'bg-green-100 text-green-800 border-green-200',
		dismissed: 'bg-gray-100 text-gray-500 border-gray-200'
	};
</script>

<svelte:head><title>Support Reports</title></svelte:head>

<div class="space-y-4">
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-xl font-semibold">Support Reports</h1>
			<p class="text-sm text-gray-500 mt-0.5">Sorted newest first · click a row to view details</p>
		</div>
		<span class="bg-slate-100 text-slate-600 text-xs font-semibold px-3 py-1 rounded-full">{data.reports.length} total</span>
	</div>

	{#if data.reports.length === 0}
		<div class="flex flex-col items-center justify-center py-16 text-gray-400">
			<svg class="w-10 h-10 mb-3 opacity-40" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
			</svg>
			<p class="text-sm">No reports yet.</p>
		</div>
	{:else}
		<div class="bg-white rounded-xl border border-slate-200 overflow-hidden">
			<!-- Table header -->
			<div class="grid grid-cols-[120px_1fr_160px_110px] gap-4 px-4 py-2 border-b border-slate-100 bg-slate-50 text-xs font-semibold text-slate-500 uppercase tracking-wide">
				<span>Status</span>
				<span>Subject</span>
				<span>From</span>
				<span>Date</span>
			</div>

			{#each data.reports as r (r.id)}
				<a
					href="/support/{r.id}"
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
		</div>
	{/if}
</div>
