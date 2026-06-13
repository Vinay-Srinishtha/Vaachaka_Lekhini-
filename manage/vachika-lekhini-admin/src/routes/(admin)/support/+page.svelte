<script lang="ts">
	import { enhance } from '$app/forms';
	export let data: import('./$types').PageData;

	const statusColor: Record<string, string> = {
		open: 'bg-amber-100 text-amber-800',
		resolved: 'bg-green-100 text-green-800',
		dismissed: 'bg-gray-100 text-gray-500'
	};

	let expanded: string | null = null;
</script>

<svelte:head><title>Support Reports</title></svelte:head>

<div class="space-y-4">
	<div class="flex items-center justify-between">
		<h1 class="text-xl font-semibold">Support Reports</h1>
		<span class="text-sm text-gray-500">{data.reports.length} total</span>
	</div>

	{#if data.reports.length === 0}
		<p class="text-gray-500 text-sm py-8 text-center">No reports yet.</p>
	{:else}
		<div class="space-y-3">
			{#each data.reports as r (r.id)}
				<div class="border border-gray-200 rounded-lg overflow-hidden">
					<button
						type="button"
						class="w-full flex items-start gap-3 px-4 py-3 text-left hover:bg-gray-50 transition"
						on:click={() => (expanded = expanded === r.id ? null : r.id)}
					>
						<span class="text-xs font-medium px-2 py-0.5 rounded-full mt-0.5 {statusColor[r.status] ?? 'bg-gray-100 text-gray-600'}">
							{r.status}
						</span>
						<div class="flex-1 min-w-0">
							<p class="font-medium text-sm truncate">{r.subject}</p>
							<p class="text-xs text-gray-400 mt-0.5">
								{r.mobile ?? 'anonymous'} · {new Date(r.createdAt).toLocaleString()}
							</p>
						</div>
						<span class="text-gray-400 text-xs">{expanded === r.id ? '▲' : '▼'}</span>
					</button>

					{#if expanded === r.id}
						<div class="px-4 pb-4 border-t border-gray-100">
							<p class="text-sm text-gray-700 whitespace-pre-wrap mt-3">{r.body}</p>
							{#if r.memberId}
								<p class="text-xs text-gray-400 mt-2">Member ID: {r.memberId}</p>
							{/if}
							<div class="flex gap-2 mt-3">
								{#each ['open', 'resolved', 'dismissed'] as s}
									{#if s !== r.status}
										<form method="POST" action="?/setStatus" use:enhance>
											<input type="hidden" name="id" value={r.id} />
											<input type="hidden" name="status" value={s} />
											<button
												class="text-xs px-3 py-1 rounded border border-gray-200 hover:bg-gray-50"
											>Mark {s}</button>
										</form>
									{/if}
								{/each}
							</div>
						</div>
					{/if}
				</div>
			{/each}
		</div>
	{/if}
</div>
