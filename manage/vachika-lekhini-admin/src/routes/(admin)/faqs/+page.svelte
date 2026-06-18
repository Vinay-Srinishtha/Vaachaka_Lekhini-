<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { enhance } from '$app/forms';
	import ConfirmDialog from '$lib/components/ConfirmDialog.svelte';
	import SearchInput from '$lib/components/SearchInput.svelte';
	import { patchQuery } from '$lib/url';
	import { toasts } from '$lib/stores/toast';
	import { PlusCircle, ArrowUp, ArrowDown, Pencil, Trash2 } from '@lucide/svelte';

	let { data, form } = $props();

	const deleteId = $derived(page.url.searchParams.get('delete'));
	const target = $derived(deleteId ? data.faqs.find((f: { id: string }) => f.id === deleteId) : null);
	let submitting = $state(false);

	const q = $derived((page.url.searchParams.get('q') ?? '').toLowerCase().trim());
	const visibleFaqs = $derived(
		q
			? data.faqs.filter(
					(f: { question: string; answer: string }) =>
						f.question.toLowerCase().includes(q) || f.answer.toLowerCase().includes(q)
				)
			: data.faqs
	);

	function close() {
		goto(patchQuery(page.url, { delete: null }), { keepFocus: true, noScroll: true, replaceState: true });
	}
</script>

{#if form?.error}
	<div class="fixed bottom-6 right-6 z-50 max-w-md rounded-lg bg-red-50 text-red-700 border border-red-200 px-4 py-3 text-sm shadow-lg">
		{form.error}
	</div>
{/if}

<form id="faq-delete-form" method="POST" action="?/delete" use:enhance={() => {
	submitting = true;
	const q = target?.question ?? 'FAQ';
	return async ({ result, update }) => {
		await update();
		submitting = false;
		if (result.type === 'redirect' || result.type === 'success') toasts.show(`"${q}" deleted`);
	};
}}>
	<input type="hidden" name="id" value={deleteId ?? ''} />
</form>

<ConfirmDialog
	open={!!target}
	title="Delete FAQ?"
	message={`This permanently removes "${target?.question ?? ''}".`}
	confirmLabel="Delete"
	{submitting}
	onCancel={close}
	onConfirm={() => { const f = document.getElementById('faq-delete-form') as HTMLFormElement | null; f?.requestSubmit(); }}
/>

<div class="mb-6 flex items-center justify-between">
	<div>
		<h1 class="text-xl font-semibold text-slate-900">FAQs</h1>
		<p class="mt-1 text-sm text-slate-500">{visibleFaqs.length}{q ? ` of ${data.faqs.length}` : ''} questions · served to the Flutter app at /api/v1/faqs</p>
	</div>
	<a href="/faqs/new" class="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-700 transition-colors">
		<PlusCircle size={16} />
		New FAQ
	</a>
</div>

<div class="mb-4">
	<SearchInput placeholder="Search by question or answer…" />
</div>

<div class="bg-white rounded-xl border border-slate-200 overflow-hidden">
	{#if visibleFaqs.length === 0}
		<div class="py-16 text-center text-slate-500 text-sm">{q ? `No FAQs match "${q}"` : 'No FAQs yet — create one to show it in the app.'}</div>
	{:else}
		<table class="w-full text-sm">
			<thead class="bg-slate-50 border-b border-slate-200">
				<tr>
					<th class="px-4 py-3 text-left font-medium text-slate-600">Question</th>
					<th class="px-4 py-3 text-left font-medium text-slate-600 w-20">Status</th>
					<th class="px-4 py-3 text-left font-medium text-slate-600 w-24">Order</th>
					<th class="px-4 py-3 w-24"></th>
				</tr>
			</thead>
			<tbody class="divide-y divide-slate-100">
				{#each visibleFaqs as faq, i (faq.id)}
					<tr class="hover:bg-slate-50 {!faq.isActive ? 'opacity-50' : ''}">
						<td class="px-4 py-3">
							<div class="font-medium text-slate-800 truncate max-w-md">{faq.question}</div>
							<div class="text-xs text-slate-400 mt-0.5 line-clamp-1">{faq.answer}</div>
						</td>
						<td class="px-4 py-3">
							<form method="POST" action="?/toggleActive" use:enhance>
								<input type="hidden" name="id" value={faq.id} />
								<button type="submit" class="text-xs font-medium px-2 py-1 rounded-full border cursor-pointer transition-colors
									{faq.isActive ? 'bg-green-50 text-green-700 border-green-200 hover:bg-green-100' : 'bg-slate-100 text-slate-500 border-slate-200 hover:bg-slate-200'}">
									{faq.isActive ? 'Active' : 'Hidden'}
								</button>
							</form>
						</td>
						<td class="px-4 py-3">
							<div class="flex items-center gap-1">
								<form method="POST" action="?/reorder" use:enhance>
									<input type="hidden" name="id" value={faq.id} />
									<input type="hidden" name="dir" value="up" />
									<button type="submit" disabled={i === 0} class="p-1 rounded hover:bg-slate-100 disabled:opacity-30 disabled:cursor-not-allowed transition-colors" aria-label="Move up">
										<ArrowUp size={14} />
									</button>
								</form>
								<form method="POST" action="?/reorder" use:enhance>
									<input type="hidden" name="id" value={faq.id} />
									<input type="hidden" name="dir" value="down" />
									<button type="submit" disabled={i === data.faqs.length - 1} class="p-1 rounded hover:bg-slate-100 disabled:opacity-30 disabled:cursor-not-allowed transition-colors" aria-label="Move down">
										<ArrowDown size={14} />
									</button>
								</form>
							</div>
						</td>
						<td class="px-4 py-3">
							<div class="flex items-center justify-end gap-2">
								<a href="/faqs/{faq.id}" class="p-1.5 rounded hover:bg-slate-100 text-slate-500 hover:text-slate-700 transition-colors" aria-label="Edit">
									<Pencil size={15} />
								</a>
								<a href={patchQuery(page.url, { delete: faq.id })} class="p-1.5 rounded hover:bg-red-50 text-slate-400 hover:text-red-600 transition-colors" aria-label="Delete">
									<Trash2 size={15} />
								</a>
							</div>
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	{/if}
</div>
