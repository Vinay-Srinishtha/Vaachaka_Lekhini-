<script lang="ts">
	import type { Snippet } from 'svelte';
	interface Props {
		title: string;
		subtitle?: string;
		actions?: Snippet;
	}
	let { title, subtitle, actions }: Props = $props();
</script>

<div class="mb-5 flex flex-col sm:flex-row sm:items-end sm:justify-between gap-3">
	<div>
		<h1 class="text-xl md:text-2xl font-bold text-gray-900">{title}</h1>
		{#if subtitle}<p class="text-sm text-gray-500 mt-1">{subtitle}</p>{/if}
	</div>
	{#if actions}
		<div class="flex items-center gap-2">{@render actions()}</div>
	{/if}
</div>
