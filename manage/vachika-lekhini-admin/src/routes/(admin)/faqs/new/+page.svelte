<script lang="ts">
	import { goto } from '$app/navigation';
	import Modal from '$lib/components/Modal.svelte';
	import { toasts } from '$lib/stores/toast';

	let { form } = $props();
	const v = $derived(form?.values ?? {});

	function close() { goto('/faqs', { keepFocus: true, noScroll: true }); }
	function handleSuccess() { toasts.show('FAQ created'); close(); }
</script>

<Modal open title="New FAQ" subtitle="Add a question and answer shown in the Flutter app" onClose={close}>
	{#if form?.error}
		<p class="mb-4 text-sm text-red-600 bg-red-50 rounded-lg px-4 py-2">{form.error}</p>
	{/if}
	<form method="POST" onsubmit={() => handleSuccess()} class="space-y-4">
		<div>
			<label class="block text-sm font-medium text-slate-700 mb-1" for="question">Question</label>
			<input id="question" name="question" type="text" value={String(v.question ?? '')}
				class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500"
				placeholder="How do I start a new mantra program?" required />
		</div>
		<div>
			<label class="block text-sm font-medium text-slate-700 mb-1" for="answer">Answer</label>
			<textarea id="answer" name="answer" rows="5"
				class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 resize-y"
				placeholder="Go to Programs → tap Create New Program → ..." required>{String(v.answer ?? '')}</textarea>
		</div>
		<div class="flex items-center gap-4">
			<div class="flex-1">
				<label class="block text-sm font-medium text-slate-700 mb-1" for="sort_order">Sort order</label>
				<input id="sort_order" name="sort_order" type="number" value={String(v.sort_order ?? '0')} min="0"
					class="w-24 rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500" />
			</div>
			<div class="flex items-center gap-2 pt-5">
				<input id="is_active" name="is_active" type="checkbox" checked={v.is_active !== 'false'}
					class="h-4 w-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500" />
				<label for="is_active" class="text-sm text-slate-700">Active (show in app)</label>
			</div>
		</div>
		<div class="flex justify-end gap-3 pt-2">
			<button type="button" onclick={close} class="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 transition-colors">Cancel</button>
			<button type="submit" class="rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-700 transition-colors">Create FAQ</button>
		</div>
	</form>
</Modal>
