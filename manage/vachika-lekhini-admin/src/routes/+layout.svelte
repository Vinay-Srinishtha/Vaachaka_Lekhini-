<script lang="ts">
	import '../app.css';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" href="/favicon.svg" />
	<title>Vaachaka Lekhini Admin</title>
</svelte:head>

{@render children()}
