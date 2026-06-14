<script lang="ts">
	import { enhance } from '$app/forms';
	import type { PageData } from './$types';
	const { data, form }: { data: PageData; form: any } = $props();
	const r = $derived(data.report);

	const statusColor: Record<string, string> = {
		open: 'bg-amber-100 text-amber-800 border-amber-200',
		resolved: 'bg-green-100 text-green-800 border-green-200',
		dismissed: 'bg-gray-100 text-gray-500 border-gray-200'
	};
</script>

<svelte:head><title>Report · {data.report.subject}</title></svelte:head>

<div class="max-w-2xl space-y-6">

	<!-- Back -->
	<a href="/support" class="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-800 transition-colors">
		<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
			<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
		</svg>
		All reports
	</a>

	{#if form?.ok}
		<div class="rounded-lg bg-green-50 border border-green-200 px-4 py-3 text-sm text-green-700">Status updated.</div>
	{/if}

	<!-- Header card -->
	<div class="bg-white rounded-xl border border-slate-200 p-6">
		<div class="flex items-start justify-between gap-4">
			<div class="flex-1 min-w-0">
				<h1 class="text-lg font-semibold text-slate-900 leading-snug">{r.subject}</h1>
				<div class="flex flex-wrap gap-3 mt-2 text-xs text-slate-400">
					<span>From: <span class="text-slate-600 font-medium">{r.mobile ?? 'anonymous'}</span></span>
					{#if r.memberId}<span>Member: <span class="font-mono text-slate-500">{r.memberId}</span></span>{/if}
					<span>Received: <span class="text-slate-600">{new Date(r.createdAt).toLocaleString()}</span></span>
				</div>
			</div>
			<span class="text-xs font-semibold px-3 py-1 rounded-full border shrink-0 {statusColor[r.status] ?? 'bg-gray-100 text-gray-600 border-gray-200'}">
				{r.status}
			</span>
		</div>
	</div>

	<!-- Body -->
	<div class="bg-white rounded-xl border border-slate-200 p-6">
		<h2 class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Message</h2>
		<p class="text-sm text-slate-700 whitespace-pre-wrap leading-relaxed">{r.body}</p>
	</div>

	<!-- Actions -->
	<div class="bg-white rounded-xl border border-slate-200 p-6">
		<h2 class="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Change Status</h2>
		<div class="flex flex-wrap gap-2">
			{#each ['open', 'resolved', 'dismissed'] as s}
				{#if s !== r.status}
					<form method="POST" action="?/setStatus" use:enhance>
						<input type="hidden" name="status" value={s} />
						<button
							class="text-sm px-4 py-2 rounded-lg border border-slate-200 hover:bg-slate-50 font-medium transition-colors"
							class:hover:border-green-300={s === 'resolved'}
							class:hover:text-green-700={s === 'resolved'}
							class:hover:border-red-200={s === 'dismissed'}
							class:hover:text-red-600={s === 'dismissed'}
						>
							Mark {s}
						</button>
					</form>
				{/if}
			{/each}
		</div>
	</div>
</div>
