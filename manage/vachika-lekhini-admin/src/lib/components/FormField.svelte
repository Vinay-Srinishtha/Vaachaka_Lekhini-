<script lang="ts">
	import type { Snippet } from 'svelte';

	interface Props {
		label: string;
		name?: string;
		hint?: string;
		error?: string | null;
		required?: boolean;
		children: Snippet;
	}

	let { label, name, hint, error, required = false, children }: Props = $props();
</script>

<div>
	<label class="label" for={name}>
		{label}{#if required}<span class="text-red-500"> *</span>{/if}
	</label>
	{@render children()}
	{#if error}
		<p class="mt-1 text-xs text-red-600">{error}</p>
	{:else if hint}
		<p class="mt-1 text-xs text-gray-500">{hint}</p>
	{/if}
</div>
