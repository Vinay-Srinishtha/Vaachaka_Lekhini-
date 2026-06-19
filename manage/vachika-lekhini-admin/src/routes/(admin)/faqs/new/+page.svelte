<script lang="ts">
	import { goto, invalidateAll } from '$app/navigation';
	import { enhance } from '$app/forms';
	import Modal from '$lib/components/Modal.svelte';
	import { toasts } from '$lib/stores/toast';

	let { form } = $props();
	const v = $derived(form?.values ?? {});

	function close() { goto('/faqs', { keepFocus: true, noScroll: true }); }
	function handleSuccess() { toasts.show('FAQ created'); close(); }
</script>

<Modal open title="New FAQ" subtitle="Add a question and answer shown in the Flutter app" size="lg" formId="faq-form" saveLabel="Create FAQ" onClose={close}>
	{#if form?.error}
		<p class="mb-4 text-sm text-red-600 bg-red-50 rounded-lg px-4 py-2">{form.error}</p>
	{/if}
	<form id="faq-form" method="POST" use:enhance={() => async ({ result, update }) => {
		if (result.type === 'redirect' || result.type === 'success') {
			handleSuccess();
			await invalidateAll();
		} else {
			await update();
		}
	}} class="space-y-5">
		<section class="card p-5 space-y-4">
			<p class="section-label">Content</p>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="question">Question</label>
				<input id="question" name="question" type="text" value={String(v.question ?? '')}
					class="input"
					placeholder="How do I start a new mantra program?" required />
			</div>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="answer">Answer</label>
				<textarea id="answer" name="answer" rows="7"
					class="input resize-y"
					placeholder="Go to Programs → tap Create New Program → ..." required>{String(v.answer ?? '')}</textarea>
			</div>
		</section>
		<section class="card p-5">
			<p class="section-label mb-3">Settings</p>
			<div class="flex items-center gap-6">
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="sort_order">Sort order</label>
					<input id="sort_order" name="sort_order" type="number" value={String(v.sort_order ?? '0')} min="0"
						class="input w-28" />
				</div>
				<label class="flex items-center gap-2.5 cursor-pointer pt-6">
					<input id="is_active" name="is_active" type="checkbox" checked={v.is_active !== 'false'}
						class="h-4 w-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500" />
					<span class="text-sm font-medium text-slate-700">Active (show in app)</span>
				</label>
			</div>
		</section>
	</form>
</Modal>
