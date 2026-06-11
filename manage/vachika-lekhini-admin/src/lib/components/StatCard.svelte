<script lang="ts">
	import type { Component } from 'svelte';
	import Sparkline from './Sparkline.svelte';

	interface Props {
		label: string;
		value: number | string;
		hint?: string;
		icon?: Component;
		tone?: 'brand' | 'blue' | 'green' | 'red' | 'gray' | 'purple' | 'amber';
		delta?: number;   // % change vs previous period — positive = up
		spark?: number[]; // sparkline data points
	}

	let { label, value, hint, icon: Icon, tone = 'brand', delta, spark }: Props = $props();

	const tones: Record<NonNullable<Props['tone']>, { bg: string; text: string; sparkColor: string }> = {
		brand:  { bg: 'bg-brand-50',  text: 'text-brand-700',  sparkColor: '#ea580c' },
		blue:   { bg: 'bg-blue-50',   text: 'text-blue-700',   sparkColor: '#3b82f6' },
		green:  { bg: 'bg-green-50',  text: 'text-green-700',  sparkColor: '#22c55e' },
		red:    { bg: 'bg-red-50',    text: 'text-red-700',    sparkColor: '#ef4444' },
		gray:   { bg: 'bg-gray-100',  text: 'text-gray-600',   sparkColor: '#6b7280' },
		purple: { bg: 'bg-purple-50', text: 'text-purple-700', sparkColor: '#a855f7' },
		amber:  { bg: 'bg-amber-50',  text: 'text-amber-700',  sparkColor: '#f59e0b' },
	};

	const t = $derived(tones[tone]);

	const deltaColor = $derived(
		delta === undefined ? '' :
		delta > 0 ? 'text-green-600' :
		delta < 0 ? 'text-red-500' : 'text-gray-400'
	);
</script>

<div class="card p-5 flex flex-col gap-3">
	<div class="flex items-start justify-between gap-2">
		<div class="min-w-0 flex-1">
			<div class="text-xs font-semibold uppercase tracking-wide text-gray-400 truncate">{label}</div>
			<div class="mt-2 text-2xl md:text-3xl font-bold tabular-nums text-gray-900 leading-none">{value}</div>
			{#if hint}
				<div class="mt-1 text-xs text-gray-400">{hint}</div>
			{/if}
		</div>
		{#if Icon}
			<div class="w-10 h-10 rounded-xl grid place-items-center shrink-0 {t.bg} {t.text}">
				<Icon size={20} />
			</div>
		{/if}
	</div>

	{#if spark?.length || delta !== undefined}
		<div class="flex items-end justify-between pt-1 border-t border-gray-50">
			{#if spark && spark.length > 1}
				<Sparkline values={spark} width={80} height={28} color={t.sparkColor} />
			{:else}
				<div></div>
			{/if}
			{#if delta !== undefined}
				<span class="text-xs font-semibold {deltaColor}">
					{delta > 0 ? '▲' : delta < 0 ? '▼' : '–'}&nbsp;{Math.abs(delta)}% vs yesterday
				</span>
			{/if}
		</div>
	{/if}
</div>
