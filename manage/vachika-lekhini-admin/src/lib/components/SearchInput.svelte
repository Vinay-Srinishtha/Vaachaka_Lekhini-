<script lang="ts">
	import { Search, X } from '@lucide/svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { patchQuery } from '$lib/url';

	interface Props {
		paramKey?: string;
		placeholder?: string;
		debounceMs?: number;
		/// When the query changes, also reset these query keys (commonly `page`).
		resetParams?: string[];
	}

	let {
		paramKey = 'q',
		placeholder = 'Search…',
		debounceMs = 250,
		resetParams = ['page']
	}: Props = $props();

	let value = $state('');
	let timer: ReturnType<typeof setTimeout> | null = null;

	// Mirror the URL → input. Runs on prop or URL change so back/forward
	// navigation updates the input too.
	$effect(() => {
		const current = page.url.searchParams.get(paramKey) ?? '';
		if (current !== value) value = current;
	});

	function commit(v: string) {
		const patch: Record<string, string | null> = { [paramKey]: v.trim() || null };
		for (const k of resetParams) patch[k] = null;
		goto(patchQuery(page.url, patch), { keepFocus: true, noScroll: true, replaceState: true });
	}

	function onInput(e: Event) {
		value = (e.target as HTMLInputElement).value;
		if (timer) clearTimeout(timer);
		timer = setTimeout(() => commit(value), debounceMs);
	}

	function clear() {
		value = '';
		commit('');
	}
</script>

<div class="relative w-full sm:max-w-xs">
	<Search
		size={16}
		class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none"
	/>
	<input
		type="search"
		{placeholder}
		value={value}
		oninput={onInput}
		class="input pl-9 pr-9"
		aria-label={placeholder}
	/>
	{#if value}
		<button
			type="button"
			class="absolute right-2 top-1/2 -translate-y-1/2 p-1 rounded text-gray-400 hover:text-gray-700 hover:bg-gray-100"
			onclick={clear}
			aria-label="Clear search"
		>
			<X size={14} />
		</button>
	{/if}
</div>
