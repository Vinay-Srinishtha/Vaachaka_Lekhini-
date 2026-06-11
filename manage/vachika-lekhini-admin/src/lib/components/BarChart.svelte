<script lang="ts">
	interface Bar {
		label: string;
		value: number;
		secondary?: string; // e.g. formatted date label
	}

	interface Props {
		data: Bar[];
		height?: number;
		color?: string;
		showValues?: boolean;
	}

	let { data, height = 140, color = '#ea580c', showValues = true }: Props = $props();

	const W = 480;
	const padT = showValues ? 20 : 6;
	const padB = 24;
	const padL = 4;
	const padR = 4;
	const plotH = height - padT - padB;
	const plotW = W - padL - padR;

	const maxVal = $derived(Math.max(...data.map((d) => d.value), 1));
	const barW = $derived(plotW / (data.length * 1.5 + 0.5));
	const gap = $derived((plotW - barW * data.length) / (data.length + 1));

	function barHeight(v: number) {
		return Math.max(v ? 3 : 1, (v / maxVal) * plotH);
	}

	function barX(i: number) {
		return padL + gap + i * (barW + gap);
	}
</script>

<svg viewBox="0 0 {W} {height}" class="w-full" style="height:{height}px" aria-hidden="true">
	<!-- Subtle gridlines -->
	{#each [0.25, 0.5, 0.75, 1] as f}
		<line
			x1={padL}
			y1={padT + plotH * (1 - f)}
			x2={W - padR}
			y2={padT + plotH * (1 - f)}
			stroke="#f3f4f6"
			stroke-width="1"
		/>
	{/each}

	<!-- Bars -->
	{#each data as bar, i}
		{@const bh = barHeight(bar.value)}
		{@const bx = barX(i)}
		{@const by = padT + plotH - bh}

		<rect
			x={bx}
			y={by}
			width={barW}
			height={bh}
			rx="3"
			fill={color}
			opacity={bar.value === 0 ? 0.15 : 0.85}
		>
			<title>{bar.label}: {bar.value.toLocaleString()}</title>
		</rect>

		{#if showValues && bar.value > 0}
			<text
				x={bx + barW / 2}
				y={by - 4}
				text-anchor="middle"
				font-size="9"
				fill="#6b7280"
				font-family="inherit"
			>{bar.value}</text>
		{/if}

		<text
			x={bx + barW / 2}
			y={height - 5}
			text-anchor="middle"
			font-size="9"
			fill="#9ca3af"
			font-family="inherit"
		>{bar.secondary ?? bar.label}</text>
	{/each}
</svg>
