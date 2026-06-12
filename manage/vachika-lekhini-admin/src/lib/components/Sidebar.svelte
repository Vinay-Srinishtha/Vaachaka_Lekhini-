<script lang="ts">
	import { navigating, page } from '$app/state';
	import { preloadData } from '$app/navigation';
	import { NAV_ITEMS } from '$lib/nav';
	import { hasRole, type AdminRole } from '$lib/roles';
	import { ChevronsLeft, ChevronsRight, X } from '@lucide/svelte';

	interface Props {
		role: AdminRole;
		collapsed: boolean;
		mobileOpen: boolean;
		pendingPath: string | null;
		onToggleCollapsed: () => void;
		onCloseMobile: () => void;
		onNavigateStart: (href: string) => void;
	}

	let {
		role,
		collapsed,
		mobileOpen,
		pendingPath,
		onToggleCollapsed,
		onCloseMobile,
		onNavigateStart
	}: Props = $props();

	const items = $derived(NAV_ITEMS.filter((i) => !i.minRole || hasRole(role, i.minRole)));
	const grouped = $derived(buildGroups(items));

	function buildGroups(navItems: typeof items) {
		const groups: { label: string | null; items: typeof items }[] = [];
		const seen = new Set<string>();
		const ungrouped = navItems.filter((i) => !i.group);
		if (ungrouped.length) groups.push({ label: null, items: ungrouped });
		for (const item of navItems) {
			if (!item.group || seen.has(item.group)) continue;
			seen.add(item.group);
			groups.push({ label: item.group, items: navItems.filter((i) => i.group === item.group) });
		}
		return groups;
	}

	function isActive(href: string): boolean {
		const path = page.url.pathname;
		if (href === '/') return path === '/';
		return path === href || path.startsWith(href + '/');
	}

	function isLoading(href: string): boolean {
		const path = pendingPath ?? navigating.to?.url.pathname;
		if (!path) return false;
		if (href === '/') return path === '/';
		return path === href || path.startsWith(href + '/');
	}

	function preload(href: string) {
		void preloadData(href);
	}

	function startNavigation(event: MouseEvent, href: string) {
		if (
			event.button !== 0 ||
			event.metaKey ||
			event.ctrlKey ||
			event.shiftKey ||
			event.altKey ||
			isActive(href)
		) {
			return;
		}
		onNavigateStart(href);
	}
</script>

<!-- Mobile backdrop -->
{#if mobileOpen}
	<button
		aria-label="Close menu"
		class="fixed inset-0 z-30 bg-black/50 backdrop-blur-sm md:hidden"
		onclick={onCloseMobile}
	></button>
{/if}

<aside
	class="fixed inset-y-0 left-0 z-40 flex flex-col transition-all duration-200 ease-out
		bg-slate-900 text-slate-100
		{collapsed ? 'md:w-16' : 'md:w-64'}
		{mobileOpen ? 'w-64 translate-x-0' : 'w-64 -translate-x-full md:translate-x-0'}"
>
	<!-- Brand header -->
	<div class="h-16 flex items-center px-4 shrink-0 border-b border-slate-700/60">
		<div class="w-9 h-9 rounded-xl grid place-items-center font-bold text-lg shrink-0
			bg-gradient-to-br from-brand-400 to-brand-700 text-white shadow-lg shadow-brand-900/40">
			ॐ
		</div>
		{#if !collapsed || mobileOpen}
			<div class="ml-3 overflow-hidden">
				<div class="text-sm font-bold text-white leading-tight tracking-tight">Vaachaka Lekhini</div>
				<div class="text-[10px] text-slate-400 leading-tight font-medium uppercase tracking-widest">Admin Panel</div>
			</div>
		{/if}
		<button
			aria-label="Close menu"
			class="ml-auto md:hidden text-slate-400 hover:text-white transition-colors"
			onclick={onCloseMobile}
		>
			<X size={20} />
		</button>
	</div>

	<!-- Nav links -->
	<nav
		class="flex-1 overflow-y-auto py-4 px-2 space-y-0.5"
		data-sveltekit-preload-code="eager"
		data-sveltekit-preload-data="hover"
	>
		{#each grouped as g}
			{#if g.label && (!collapsed || mobileOpen)}
				<div class="px-3 pt-4 pb-1.5 text-[10px] font-bold uppercase tracking-widest text-slate-500 select-none">
					{g.label}
				</div>
			{:else if g.label && collapsed && !mobileOpen}
				<div class="my-3 border-t border-slate-700/50 mx-2"></div>
			{/if}

			{#each g.items as item (item.href)}
				{@const active = isActive(item.href)}
				{@const loading = isLoading(item.href)}
				<a
					href={item.href}
					onclick={(event) => {
						startNavigation(event, item.href);
						onCloseMobile();
					}}
					onpointerenter={() => preload(item.href)}
					onfocus={() => preload(item.href)}
					title={collapsed && !mobileOpen ? item.label : undefined}
					class="group flex items-center rounded-xl px-3 py-2.5 text-sm font-medium transition-all relative
						{active || loading
						? 'bg-brand-600/20 text-brand-300 shadow-sm'
						: 'text-slate-400 hover:bg-slate-800 hover:text-slate-100'}"
					aria-busy={loading}
				>
					{#if active || loading}
						<div class="absolute left-0 inset-y-2 w-0.5 rounded-r-full bg-brand-400"></div>
					{/if}
					<item.icon
						size={17}
						class="shrink-0 transition-colors {active || loading ? 'text-brand-400' : 'text-slate-500 group-hover:text-slate-300'}"
					/>
					{#if !collapsed || mobileOpen}
						<span class="ml-3 truncate">{item.label}</span>
						{#if loading}
							<span
								class="ml-auto size-3.5 rounded-full border-2 border-brand-400/30 border-t-brand-300 animate-spin"
								aria-hidden="true"
							></span>
						{/if}
					{/if}
				</a>
			{/each}
		{/each}
	</nav>

	<!-- Collapse toggle (desktop only) -->
	<div class="border-t border-slate-700/60 p-2 hidden md:block shrink-0">
		<button
			class="w-full flex items-center justify-center rounded-xl px-3 py-2 text-slate-500
				hover:bg-slate-800 hover:text-slate-300 transition-colors"
			onclick={onToggleCollapsed}
			aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
		>
			{#if collapsed}
				<ChevronsRight size={17} />
			{:else}
				<ChevronsLeft size={17} />
				<span class="ml-2 text-xs font-medium">Collapse</span>
			{/if}
		</button>
	</div>
</aside>
