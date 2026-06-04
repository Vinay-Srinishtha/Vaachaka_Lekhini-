<script lang="ts">
	import { page } from '$app/state';
	import { NAV_ITEMS } from '$lib/nav';
	import { hasRole, type AdminRole } from '$lib/roles';
	import { ChevronsLeft, ChevronsRight, X } from '@lucide/svelte';

	interface Props {
		role: AdminRole;
		collapsed: boolean;
		mobileOpen: boolean;
		onToggleCollapsed: () => void;
		onCloseMobile: () => void;
	}

	let { role, collapsed, mobileOpen, onToggleCollapsed, onCloseMobile }: Props = $props();

	const items = $derived(NAV_ITEMS.filter((i) => !i.minRole || hasRole(role, i.minRole)));

	function isActive(href: string): boolean {
		const path = page.url.pathname;
		if (href === '/') return path === '/';
		return path === href || path.startsWith(href + '/');
	}
</script>

<!-- Mobile backdrop -->
{#if mobileOpen}
	<button
		aria-label="Close menu"
		class="fixed inset-0 z-30 bg-black/40 md:hidden"
		onclick={onCloseMobile}
	></button>
{/if}

<aside
	class="fixed inset-y-0 left-0 z-40 bg-white border-r border-gray-200 flex flex-col transition-all duration-200 ease-out
		{collapsed ? 'md:w-16' : 'md:w-64'}
		{mobileOpen ? 'w-64 translate-x-0' : 'w-64 -translate-x-full md:translate-x-0'}"
>
	<!-- Brand -->
	<div class="h-16 flex items-center px-4 border-b border-gray-200 shrink-0">
		<div class="w-9 h-9 rounded-lg bg-brand-600 text-white grid place-items-center font-bold shrink-0">
			ॐ
		</div>
		{#if !collapsed || mobileOpen}
			<div class="ml-3 overflow-hidden">
				<div class="text-sm font-semibold text-gray-900 leading-tight">KVL Admin</div>
				<div class="text-[11px] text-gray-500 leading-tight">Vachika Lekhini</div>
			</div>
		{/if}
		<button
			aria-label="Close menu"
			class="ml-auto md:hidden text-gray-400 hover:text-gray-700"
			onclick={onCloseMobile}
		>
			<X size={20} />
		</button>
	</div>

	<!-- Nav links -->
	<nav class="flex-1 overflow-y-auto py-3 px-2 space-y-1">
		{#each items as item (item.href)}
			{@const active = isActive(item.href)}
			<a
				href={item.href}
				onclick={onCloseMobile}
				class="group flex items-center rounded-lg px-3 py-2 text-sm font-medium transition
					{active
					? 'bg-brand-50 text-brand-700'
					: 'text-gray-700 hover:bg-gray-100 hover:text-gray-900'}"
				title={collapsed && !mobileOpen ? item.label : undefined}
			>
				<item.icon size={18} class={active ? 'text-brand-600' : 'text-gray-500'} />
				{#if !collapsed || mobileOpen}
					<span class="ml-3">{item.label}</span>
				{/if}
			</a>
		{/each}
	</nav>

	<!-- Collapse toggle (desktop only) -->
	<div class="border-t border-gray-200 p-2 hidden md:block shrink-0">
		<button
			class="w-full flex items-center justify-center rounded-lg px-3 py-2 text-gray-500 hover:bg-gray-100"
			onclick={onToggleCollapsed}
			aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
		>
			{#if collapsed}
				<ChevronsRight size={18} />
			{:else}
				<ChevronsLeft size={18} />
				<span class="ml-2 text-sm font-medium">Collapse</span>
			{/if}
		</button>
	</div>
</aside>
