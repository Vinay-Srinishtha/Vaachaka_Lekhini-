<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { enhance } from '$app/forms';
	import ConfirmDialog from '$lib/components/ConfirmDialog.svelte';
	import { patchQuery } from '$lib/url';

	let { data, form } = $props();

	const deleteId = $derived(page.url.searchParams.get('delete'));
	const target = $derived(deleteId ? data.items.find((i) => i.id === deleteId) : null);
	let submitting = $state(false);

	function close() {
		goto(patchQuery(page.url, { delete: null }), {
			keepFocus: true,
			noScroll: true,
			replaceState: true
		});
	}
</script>

{#if form?.error}
	<div class="fixed bottom-6 right-6 z-50 max-w-md rounded-lg bg-red-50 text-red-700 border border-red-200 px-4 py-3 text-sm shadow-lg">
		{form.error}
	</div>
{/if}

<form
	id="store-delete-form"
	method="POST"
	action="?/delete"
	use:enhance={() => {
		submitting = true;
		return async ({ update }) => {
			await update();
			submitting = false;
		};
	}}
>
	<input type="hidden" name="id" value={deleteId ?? ''} />
</form>

<ConfirmDialog
	open={!!target}
	title="Delete store item?"
	message={`This permanently removes "${target?.name ?? ''}" from the store. Mark it inactive instead if you only want to hide it.`}
	confirmLabel="Delete"
	{submitting}
	onCancel={close}
	onConfirm={() => {
		const f = document.getElementById('store-delete-form') as HTMLFormElement | null;
		f?.requestSubmit();
	}}
/>
