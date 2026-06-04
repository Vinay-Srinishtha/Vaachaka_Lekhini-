<script lang="ts">
	import { Check } from '@lucide/svelte';

	interface Props {
		name: string;
		options: readonly string[];
		value: string[];
		label?: (v: string) => string;
	}

	let { name, options, value = $bindable([]), label = (v) => v }: Props = $props();

	function toggle(opt: string) {
		value = value.includes(opt) ? value.filter((v) => v !== opt) : [...value, opt];
	}
</script>

<!-- One hidden input per selected value — form-friendly multi-value submission. -->
{#each value as v}
	<input type="hidden" name={name} value={v} />
{/each}

<div class="flex flex-wrap gap-2">
	{#each options as opt (opt)}
		{@const active = value.includes(opt)}
		<button
			type="button"
			class="px-3 py-1.5 rounded-full text-xs font-medium border transition flex items-center gap-1.5
				{active
				? 'bg-brand-600 text-white border-brand-600'
				: 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'}"
			onclick={() => toggle(opt)}
		>
			{#if active}<Check size={12} />{/if}
			{label(opt)}
		</button>
	{/each}
</div>
