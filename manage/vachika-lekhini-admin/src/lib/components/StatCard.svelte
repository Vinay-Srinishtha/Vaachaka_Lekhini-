<script lang="ts">
	import type { Component } from 'svelte';

	interface Props {
		label: string;
		value: number | string;
		hint?: string;
		icon?: Component;
		tone?: 'brand' | 'blue' | 'green' | 'red' | 'gray';
	}

	let { label, value, hint, icon: Icon, tone = 'brand' }: Props = $props();

	const tones: Record<NonNullable<Props['tone']>, string> = {
		brand: 'bg-brand-50 text-brand-700',
		blue: 'bg-blue-50 text-blue-700',
		green: 'bg-green-50 text-green-700',
		red: 'bg-red-50 text-red-700',
		gray: 'bg-gray-100 text-gray-700'
	};
</script>

<div class="card p-5">
	<div class="flex items-start justify-between gap-3">
		<div class="min-w-0">
			<div class="text-sm font-medium text-gray-500 truncate">{label}</div>
			<div class="mt-2 text-2xl md:text-3xl font-bold text-gray-900">{value}</div>
			{#if hint}
				<div class="mt-1 text-xs text-gray-500">{hint}</div>
			{/if}
		</div>
		{#if Icon}
			<div class="w-10 h-10 rounded-lg grid place-items-center shrink-0 {tones[tone]}">
				<Icon size={20} />
			</div>
		{/if}
	</div>
</div>
