<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { enhance } from '$app/forms';
	import ConfirmDialog from '$lib/components/ConfirmDialog.svelte';
	import SearchInput from '$lib/components/SearchInput.svelte';
	import Pagination from '$lib/components/Pagination.svelte';
	import { patchQuery } from '$lib/url';
	import { toasts } from '$lib/stores/toast';
	import { PlusCircle, Eye, EyeOff, Pencil, Trash2, Clock } from '@lucide/svelte';

	let { data, form } = $props();

	const deleteId = $derived(page.url.searchParams.get('delete'));
	const target = $derived(deleteId ? data.items.find((i: { id: string }) => i.id === deleteId) : null);
	let submitting = $state(false);
	const q = $derived(data.query.q);

	function close() {
		goto(patchQuery(page.url, { delete: null }), { keepFocus: true, noScroll: true, replaceState: true });
	}
</script>

{#if form?.error}
	<div class="fixed bottom-6 right-6 z-50 max-w-md rounded-lg bg-red-50 text-red-700 border border-red-200 px-4 py-3 text-sm shadow-lg">
		{form.error}
	</div>
{/if}

<form id="store-delete-form" method="POST" action="?/delete" use:enhance={() => {
	submitting = true;
	const name = target?.name ?? 'Item';
	return async ({ result, update }) => {
		if (result.type === 'redirect' || result.type === 'success') {
			toasts.show(`"${name}" deleted`);
			close();
			await update();
		} else {
			await update();
		}
		submitting = false;
	};
}}>
	<input type="hidden" name="id" value={deleteId ?? ''} />
</form>

<ConfirmDialog
	open={!!target}
	title="Delete store item?"
	message={`This permanently removes "${target?.name ?? ''}" from the store. Mark it inactive instead if you only want to hide it.`}
	confirmLabel="Delete"
	{submitting}
	onCancel={close}
	onConfirm={() => { const f = document.getElementById('store-delete-form') as HTMLFormElement | null; f?.requestSubmit(); }}
/>

<!-- Header -->
<div class="mb-6 flex items-center justify-between gap-4">
	<div>
		<h1 class="text-xl font-semibold text-slate-900">Store</h1>
		<p class="mt-1 text-sm text-slate-500">
			{q ? `${data.items.length} of ${data.total} items match "${q}"` : `${data.total} item${data.total === 1 ? '' : 's'}`} · Rewards items shown in the Flutter Store tab
		</p>
	</div>
	<a href="/store/new" class="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-700 transition-colors">
		<PlusCircle size={16} />
		New Item
	</a>
</div>

<div class="mb-4">
	<SearchInput placeholder="Search by name, slug or description…" />
</div>

<!-- Table -->
<div class="bg-white rounded-xl border border-slate-200 overflow-hidden">
	{#if data.items.length === 0}
		<div class="py-16 text-center text-slate-500 text-sm">
			{q ? `No items match "${q}"` : 'No store items yet — create one to show it in the app.'}
		</div>
	{:else}
		<div class="overflow-x-auto">
			<table class="w-full text-sm">
				<thead class="bg-slate-50 border-b border-slate-200">
					<tr>
						{#each ['Item', 'Cost', 'Stock', 'Status', 'Coming Soon', 'Order', ''] as h}
							<th class="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide whitespace-nowrap">{h}</th>
						{/each}
					</tr>
				</thead>
				<tbody class="divide-y divide-slate-100">
					{#each data.items as item (item.id)}
						<tr class="hover:bg-slate-50 transition-colors {!item.isActive ? 'opacity-60' : ''}">
							<!-- Item -->
							<td class="px-4 py-3">
								<div class="flex items-center gap-3">
									{#if item.imageUrl}
										<img src={item.imageUrl} alt="" class="h-10 w-10 rounded-lg object-cover border border-slate-200" onerror={(e) => { (e.target as HTMLImageElement).style.display = 'none'; }} />
									{:else}
										<div class="h-10 w-10 rounded-lg bg-slate-100 border border-slate-200"></div>
									{/if}
									<div>
										<p class="font-medium text-slate-900">{item.name}</p>
										<p class="text-xs text-slate-400 font-mono">{item.slug}</p>
									</div>
								</div>
							</td>
							<!-- Cost -->
							<td class="px-4 py-3 whitespace-nowrap text-slate-700 font-medium">
								{item.pointsCost.toLocaleString()}
							</td>
							<!-- Stock -->
							<td class="px-4 py-3 whitespace-nowrap text-slate-500">
								{item.stock == null ? '∞' : item.stock}
							</td>
							<!-- Active toggle -->
							<td class="px-4 py-3">
								<form method="POST" action="?/toggleActive" use:enhance={({ cancel: _c }) => {
									return async ({ update }) => update({ reset: false });
								}}>
									<input type="hidden" name="id" value={item.id} />
									<button type="submit" class="rounded-full p-1 transition-colors {item.isActive ? 'text-green-600 hover:bg-green-50' : 'text-slate-400 hover:bg-slate-100'}" title={item.isActive ? 'Active — click to deactivate' : 'Inactive — click to activate'}>
										{#if item.isActive}<Eye size={16} />{:else}<EyeOff size={16} />{/if}
									</button>
								</form>
							</td>
							<!-- Coming Soon toggle -->
							<td class="px-4 py-3">
								<form method="POST" action="?/toggleComingSoon" use:enhance={({ cancel: _c }) => {
									return async ({ update }) => update({ reset: false });
								}}>
									<input type="hidden" name="id" value={item.id} />
									<button type="submit" class="rounded-full p-1 transition-colors {item.comingSoon ? 'text-amber-500 hover:bg-amber-50' : 'text-slate-300 hover:bg-slate-100'}" title={item.comingSoon ? 'Coming Soon — click to remove badge' : 'Click to mark as Coming Soon'}>
										<Clock size={16} />
									</button>
								</form>
							</td>
							<!-- Order -->
							<td class="px-4 py-3 text-slate-400 text-xs">{item.sortOrder}</td>
							<!-- Actions -->
							<td class="px-4 py-3">
								<div class="flex items-center gap-1">
									<a href="/store/{item.id}/edit" class="rounded p-1.5 text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors" title="Edit">
										<Pencil size={15} />
									</a>
									<a href={patchQuery(page.url, { delete: item.id })} class="rounded p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 transition-colors" title="Delete">
										<Trash2 size={15} />
									</a>
								</div>
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
		<Pagination total={data.total} currentPage={data.query.page} pageSize={data.query.pageSize} />
	{/if}
</div>
