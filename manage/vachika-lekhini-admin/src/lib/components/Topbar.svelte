<script lang="ts">
	import { Menu, LogOut } from '@lucide/svelte';
	import { enhance } from '$app/forms';
	import { page } from '$app/state';
	import { NAV_ITEMS } from '$lib/nav';
	import type { AdminRole } from '$lib/roles';

	interface Props {
		admin: { username: string; role: AdminRole };
		onOpenMobile: () => void;
	}

	let { admin, onOpenMobile }: Props = $props();

	const currentLabel = $derived(
		NAV_ITEMS.find((i) =>
			i.href === '/'
				? page.url.pathname === '/'
				: page.url.pathname === i.href || page.url.pathname.startsWith(i.href + '/')
		)?.label ?? 'Admin'
	);

	const roleColour: Record<AdminRole, string> = {
		super_admin: 'bg-purple-100 text-purple-700',
		editor: 'bg-blue-100 text-blue-700',
		viewer: 'bg-gray-100 text-gray-700'
	};
</script>

<header class="h-16 sticky top-0 z-20 bg-white border-b border-gray-200 flex items-center px-4 md:px-6 gap-3">
	<button
		aria-label="Open menu"
		class="md:hidden p-2 rounded-lg hover:bg-gray-100 text-gray-600"
		onclick={onOpenMobile}
	>
		<Menu size={20} />
	</button>

	<h1 class="text-base md:text-lg font-semibold text-gray-900 truncate">{currentLabel}</h1>

	<div class="ml-auto flex items-center gap-3">
		<div class="hidden sm:flex items-center gap-2">
			<div class="text-right leading-tight">
				<div class="text-sm font-medium text-gray-900">{admin.username}</div>
				<div class="text-[11px] text-gray-500">{admin.role.replace('_', ' ')}</div>
			</div>
			<span class="chip {roleColour[admin.role]}">{admin.role.replace('_', ' ')}</span>
		</div>
		<form method="POST" action="/logout" use:enhance>
			<button class="btn-secondary !px-3 !py-2" title="Log out">
				<LogOut size={16} />
				<span class="hidden sm:inline">Logout</span>
			</button>
		</form>
	</div>
</header>
