<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { enhance } from '$app/forms';
	import ConfirmDialog from '$lib/components/ConfirmDialog.svelte';
	import { patchQuery } from '$lib/url';

	let { data, form } = $props();

	const deleteKey = $derived(page.url.searchParams.get('delete'));
	const target = $derived(deleteKey ? data.flags.find((f) => f.key === deleteKey) : null);
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
	id="flag-delete-form"
	method="POST"
	action="?/delete"
	use:enhance={() => {
		submitting = true;
		return async ({ result, update }) => {
			if (result.type === 'redirect' || result.type === 'success') {
				await update();
				close();
			} else {
				await update();
			}
			submitting = false;
		};
	}}
>
	<input type="hidden" name="key" value={deleteKey ?? ''} />
</form>

<ConfirmDialog
	open={!!target}
	title="Delete flag?"
	message={`This removes "${target?.key ?? ''}" from /api/v1/config. The Flutter app will fall back to its built-in default the next time it polls.`}
	confirmLabel="Delete"
	{submitting}
	onCancel={close}
	onConfirm={() => {
		const f = document.getElementById('flag-delete-form') as HTMLFormElement | null;
		f?.requestSubmit();
	}}
/>
