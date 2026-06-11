<script lang="ts">
	interface Slice {
		label: string;
		value: number;
		color: string;
	}

	interface Props {
		data: Slice[];
		size?: number;
		thickness?: number;
		centerLabel?: string;
		centerSub?: string;
	}

	let { data, size = 130, thickness = 26, centerLabel = '', centerSub = '' }: Props = $props();

	const total = $derived(data.reduce((s, d) => s + d.value, 0) || 1);
	const cx = size / 2;
	const cy = size / 2;
	const r = (size - thickness) / 2;
	const circ = 2 * Math.PI * r;

	// Build stroke-dasharray segments
	const segments = $derived(() => {
		let offset = 0;
		return data.map((d) => {
			const pct = d.value / total;
			const dash = pct * circ;
			const seg = { ...d, pct, dash, offset: offset * circ };
			offset += pct;
			return seg;
		});
	});
</script>

<svg
	viewBox="0 0 {size} {size}"
	style="width:{size}px;height:{size}px;transform:rotate(-90deg)"
	aria-hidden="true"
>
	<!-- Background ring -->
	<circle cx={cx} cy={cy} r={r} fill="none" stroke="#f3f4f6" stroke-width={thickness} />

	<!-- Segments -->
	{#each segments() as seg}
		<circle
			cx={cx}
			cy={cy}
			r={r}
			fill="none"
			stroke={seg.color}
			stroke-width={thickness}
			stroke-dasharray="{seg.dash} {circ - seg.dash}"
			stroke-dashoffset={-seg.offset}
			stroke-linecap="butt"
		>
			<title>{seg.label}: {seg.value.toLocaleString()} ({Math.round(seg.pct * 100)}%)</title>
		</circle>
	{/each}
</svg>

{#if centerLabel}
	<div
		class="absolute inset-0 flex flex-col items-center justify-center pointer-events-none"
		style="transform:none"
	>
		<span class="text-lg font-bold text-gray-900 leading-tight">{centerLabel}</span>
		{#if centerSub}
			<span class="text-[10px] text-gray-400 mt-0.5">{centerSub}</span>
		{/if}
	</div>
{/if}
