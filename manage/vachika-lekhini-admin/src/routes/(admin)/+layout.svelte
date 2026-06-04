<script lang="ts">
	import Sidebar from '$lib/components/Sidebar.svelte';
	import Topbar from '$lib/components/Topbar.svelte';
	import { onMount } from 'svelte';

	let { data, children } = $props();
	const admin = $derived(data.admin!);

	// Persist desktop-collapsed preference; default expanded.
	let collapsed = $state(false);
	let mobileOpen = $state(false);

	onMount(() => {
		const saved = localStorage.getItem('sidebar:collapsed');
		if (saved === '1') collapsed = true;
	});

	function toggleCollapsed() {
		collapsed = !collapsed;
		localStorage.setItem('sidebar:collapsed', collapsed ? '1' : '0');
	}
</script>

<div class="min-h-screen">
	<Sidebar
		role={admin.role}
		{collapsed}
		{mobileOpen}
		onToggleCollapsed={toggleCollapsed}
		onCloseMobile={() => (mobileOpen = false)}
	/>

	<div class="transition-[padding] duration-200 {collapsed ? 'md:pl-16' : 'md:pl-64'}">
		<Topbar {admin} onOpenMobile={() => (mobileOpen = true)} />
		<main class="px-4 md:px-6 lg:px-8 py-6">
			{@render children()}
		</main>
	</div>
</div>
