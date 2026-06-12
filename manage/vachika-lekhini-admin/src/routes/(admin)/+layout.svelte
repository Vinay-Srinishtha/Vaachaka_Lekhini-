<script lang="ts">
	import Sidebar from '$lib/components/Sidebar.svelte';
	import Topbar from '$lib/components/Topbar.svelte';
	import Toast from '$lib/components/Toast.svelte';
	import { onMount, onDestroy } from 'svelte';
	import { afterNavigate, invalidateAll } from '$app/navigation';
	import { navigating } from '$app/state';

	let { data, children } = $props();
	const admin = $derived(data.admin!);

	// Persist desktop-collapsed preference; default expanded.
	let collapsed = $state(false);
	let mobileOpen = $state(false);
	let pendingPath = $state<string | null>(null);
	const navigationBusy = $derived(pendingPath !== null || navigating.to !== null);

	afterNavigate(() => {
		pendingPath = null;
	});

	// SSE subscription — each Flutter write triggers a change event that causes
	// SvelteKit to re-run all load functions immediately (sub-second latency).
	let es: EventSource | null = null;

	onMount(() => {
		const saved = localStorage.getItem('sidebar:collapsed');
		if (saved === '1') collapsed = true;

		es = new EventSource('/api/admin/stream');
		es.addEventListener('change', () => invalidateAll());
		es.onerror = () => {
			// On error/disconnect, reconnect after 3 s.
			es?.close();
			setTimeout(() => {
				es = new EventSource('/api/admin/stream');
				es.addEventListener('change', () => invalidateAll());
			}, 3000);
		};
	});

	onDestroy(() => {
		es?.close();
	});

	function toggleCollapsed() {
		collapsed = !collapsed;
		localStorage.setItem('sidebar:collapsed', collapsed ? '1' : '0');
	}
</script>

<div class="min-h-screen">
	{#if navigationBusy}
		<div class="fixed inset-x-0 top-0 z-[60] h-[3px] overflow-hidden bg-brand-950/15" aria-hidden="true">
			<div class="nav-progress h-full w-1/3 bg-gradient-to-r from-brand-300 via-brand-500 to-brand-300"></div>
		</div>
	{/if}

	<Sidebar
		role={admin.role}
		{collapsed}
		{mobileOpen}
		{pendingPath}
		onToggleCollapsed={toggleCollapsed}
		onCloseMobile={() => (mobileOpen = false)}
		onNavigateStart={(href) => (pendingPath = href)}
	/>

	<div class="transition-[padding] duration-200 {collapsed ? 'md:pl-16' : 'md:pl-64'}">
		<Topbar {admin} {pendingPath} onOpenMobile={() => (mobileOpen = true)} />
		<main
			class="relative px-4 md:px-6 lg:px-8 py-6"
			aria-busy={navigationBusy}
		>
			{#if navigationBusy}
				<div
					class="nav-status pointer-events-none fixed right-4 top-[4.75rem] z-30 flex items-center gap-2
						rounded-full border border-brand-100 bg-white/95 px-3 py-1.5 text-xs font-semibold
						text-brand-700 shadow-lg shadow-brand-950/10 backdrop-blur-sm"
					role="status"
					aria-live="polite"
				>
					<span class="size-3.5 animate-spin rounded-full border-2 border-brand-200 border-t-brand-600"></span>
					Loading
				</div>
			{/if}
			{@render children()}
		</main>
	</div>
</div>

<Toast />

<style>
	.nav-progress {
		animation: nav-progress 700ms ease-in-out infinite;
	}

	.nav-status {
		animation: nav-status-in 120ms ease-out 140ms both;
	}

	@keyframes nav-progress {
		from {
			transform: translateX(-100%);
		}
		to {
			transform: translateX(400%);
		}
	}

	@keyframes nav-status-in {
		from {
			opacity: 0;
			transform: translateY(-4px);
		}
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}
</style>
