<script lang="ts">
	interface Props {
		values: number[];
		width?: number;
		height?: number;
		color?: string;
		fill?: boolean;
	}

	let { values, width = 80, height = 28, color = '#ea580c', fill = true }: Props = $props();

	const pts = $derived(() => {
		if (!values.length) return { points: '', area: '' };
		const max = Math.max(...values, 1);
		const min = Math.min(...values);
		const range = max - min || 1;
		const pad = 2;
		const w = width - pad * 2;
		const h = height - pad * 2;
		const coords = values.map((v, i) => {
			const x = pad + (i / Math.max(values.length - 1, 1)) * w;
			const y = pad + h - ((v - min) / range) * h;
			return { x, y };
		});
		const line = coords.map((p, i) => `${i === 0 ? 'M' : 'L'}${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(' ');
		const area =
			line +
			` L${coords[coords.length - 1].x.toFixed(1)},${height - pad} L${pad},${height - pad} Z`;
		return { points: line, area };
	});
</script>

<svg
	viewBox="0 0 {width} {height}"
	style="width:{width}px;height:{height}px"
	aria-hidden="true"
>
	{#if fill && pts().area}
		<path d={pts().area} fill={color} opacity="0.12" />
	{/if}
	{#if pts().points}
		<path d={pts().points} fill="none" stroke={color} stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round" />
	{/if}
</svg>
