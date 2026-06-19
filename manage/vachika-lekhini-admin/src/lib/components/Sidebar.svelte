<script lang="ts">
	import { navigating, page } from '$app/state';
	import { NAV_ITEMS } from '$lib/nav';
	import { canAccessSection, type AdminRole } from '$lib/roles';
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

	const items = $derived(NAV_ITEMS.filter((i) => canAccessSection(role, i.section)));
	const grouped = $derived(buildGroups(items));

	// Color accent per group for visual differentiation
	const groupAccent: Record<string, string> = {
		Content:  'text-violet-400',
		Practice: 'text-sky-400',
		Rewards:  'text-amber-400',
		Support:  'text-rose-400',
		Audit:    'text-slate-400',
	};

	const groupDot: Record<string, string> = {
		Content:  'bg-violet-400',
		Practice: 'bg-sky-400',
		Rewards:  'bg-amber-400',
		Support:  'bg-rose-400',
		Audit:    'bg-slate-400',
	};

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
		class="fixed inset-0 z-30 bg-black/60 backdrop-blur-sm md:hidden"
		onclick={onCloseMobile}
	></button>
{/if}

<aside
	class="fixed inset-y-0 left-0 z-40 flex flex-col transition-all duration-300 ease-out
		{collapsed ? 'md:w-[68px]' : 'md:w-64'}
		{mobileOpen ? 'w-64 translate-x-0' : 'w-64 -translate-x-full md:translate-x-0'}"
	style="background: linear-gradient(180deg, #0f1623 0%, #111827 60%, #0d1520 100%);"
>
	<!-- Brand header -->
	<div class="h-[68px] flex items-center px-3 shrink-0 border-b border-white/[0.06]">
		<!-- App logo -->
		<div class="w-10 h-10 rounded-2xl shrink-0 overflow-hidden shadow-lg shadow-black/40 border border-white/10">
			<img src="/app_icon.png" alt="Vaachaka Lekhini" class="w-full h-full object-cover" />
		</div>

		{#if !collapsed || mobileOpen}
			<div class="ml-3 overflow-hidden min-w-0">
				<div class="text-[13px] font-bold text-white leading-tight tracking-tight truncate">Vaachaka Lekhini</div>
				<div class="flex items-center gap-1.5 mt-0.5">
					<span class="inline-block w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
					<span class="text-[10px] text-slate-400 leading-none font-semibold uppercase tracking-widest">Admin Panel</span>
				</div>
			</div>
		{/if}

		<button
			aria-label="Close menu"
			class="ml-auto md:hidden text-slate-500 hover:text-white transition-colors p-1"
			onclick={onCloseMobile}
		>
			<X size={18} />
		</button>
	</div>

	<!-- Nav links -->
	<nav
		class="flex-1 overflow-y-auto py-3 space-y-0.5 scrollbar-thin"
		style="scrollbar-color: #334155 transparent;"
		data-sveltekit-preload-code="hover"
		data-sveltekit-preload-data="tap"
	>
		{#each grouped as g, gi}
			{#if g.label}
				{#if !collapsed || mobileOpen}
					<!-- Section header with colored dot -->
					<div class="px-4 pb-1.5 flex items-center gap-2 select-none" style="padding-top: {gi === 0 ? '8px' : '20px'}">
						<span class="w-1.5 h-1.5 rounded-full shrink-0 {groupDot[g.label] ?? 'bg-slate-500'}"></span>
						<span class="text-[10px] font-bold uppercase tracking-widest {groupAccent[g.label] ?? 'text-slate-500'}">
							{g.label}
						</span>
					</div>
				{:else}
					<!-- Collapsed: just a thin divider -->
					<div class="my-2 mx-3 border-t border-white/[0.06]"></div>
				{/if}
			{/if}

			<div class="px-2 space-y-0.5">
				{#each g.items as item (item.href)}
					{@const active = isActive(item.href)}
					{@const loading = isLoading(item.href)}
					<a
						href={item.href}
						onclick={(event) => {
							startNavigation(event, item.href);
							onCloseMobile();
						}}
						title={collapsed && !mobileOpen ? item.label : undefined}
						aria-busy={loading}
						class="group relative flex items-center rounded-xl px-2.5 py-2 text-sm font-medium transition-all duration-150
							{active
								? 'bg-brand-600/15 text-brand-300'
								: loading
								? 'bg-slate-800/60 text-slate-200'
								: 'text-slate-400 hover:bg-white/[0.05] hover:text-slate-100'}"
					>
						<!-- Active left bar -->
						{#if active}
							<span class="absolute left-0 top-2 bottom-2 w-[3px] rounded-r-full bg-brand-400"></span>
						{/if}

						<!-- Icon container -->
						<span class="flex items-center justify-center w-7 h-7 rounded-lg shrink-0 transition-colors
							{active
								? 'bg-brand-500/20 text-brand-300'
								: loading
								? 'text-slate-300'
								: 'text-slate-500 group-hover:text-slate-300'}">
							<item.icon size={16} />
						</span>

						{#if !collapsed || mobileOpen}
							<span class="ml-2.5 truncate text-[13px]">{item.label}</span>
							{#if loading}
								<span
									class="ml-auto size-3.5 rounded-full border-[1.5px] border-brand-400/30 border-t-brand-300 animate-spin"
									aria-hidden="true"
								></span>
							{/if}
						{/if}
					</a>
				{/each}
			</div>
		{/each}
	</nav>

	<!-- Collapse toggle (desktop only) -->
	<div class="border-t border-white/[0.06] p-2 hidden md:block shrink-0">
		<button
			class="w-full flex items-center justify-center rounded-xl px-3 py-2 text-slate-600
				hover:bg-white/[0.05] hover:text-slate-300 transition-colors text-xs font-medium gap-2"
			onclick={onToggleCollapsed}
			aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
		>
			{#if collapsed}
				<ChevronsRight size={16} />
			{:else}
				<ChevronsLeft size={16} />
				<span>Collapse</span>
			{/if}
		</button>
	</div>
</aside>
