<script lang="ts">
	import { goto } from '$app/navigation';
	import Modal from '$lib/components/Modal.svelte';
	import ConfirmDialog from '$lib/components/ConfirmDialog.svelte';
	import { toasts } from '$lib/stores/toast';
	import { Upload, Trash2, X } from '@lucide/svelte';

	let { data, form } = $props();
	const v = $derived(form?.values ?? {});

	const q = data.quote;
	let showDelete = $state(false);
	let deleting = $state(false);

	let imagePreview = $state<string | null>(null);
	let imageKey = $state<string | null>(q.imageUrl ?? null);
	let uploading = $state(false);
	let uploadError = $state('');

	function close() { goto('/quotes', { keepFocus: true, noScroll: true }); }
	function handleSuccess() { toasts.show('Quote updated'); close(); }

	async function uploadImage(event: Event) {
		const input = event.target as HTMLInputElement;
		const file = input.files?.[0];
		if (!file) return;
		uploadError = '';
		uploading = true;
		try {
			const slug = `quote-${q.id}`;
			const res = await fetch('/api/admin/upload', {
				method: 'POST',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify({ category: 'quote-image', slug, fileName: file.name, contentType: file.type, size: file.size })
			});
			if (!res.ok) { uploadError = 'Failed to get upload URL'; return; }
			const { uploadUrl, url, headers } = await res.json();
			const put = await fetch(uploadUrl, { method: 'PUT', headers, body: file });
			if (!put.ok) { uploadError = 'Upload to S3 quarantine failed'; return; }
			imageKey = url;
			imagePreview = URL.createObjectURL(file);
		} catch {
			uploadError = 'Upload error — please try again.';
		} finally {
			uploading = false;
			input.value = '';
		}
	}

	function clearImage() { imageKey = null; imagePreview = null; }
</script>

<ConfirmDialog
	open={showDelete}
	title="Delete Quote?"
	message={`Permanently remove "${q.text.slice(0, 60)}${q.text.length > 60 ? '…' : ''}"?`}
	confirmLabel="Delete"
	{deleting}
	onCancel={() => showDelete = false}
	onConfirm={async () => {
		deleting = true;
		const fd = new FormData();
		const res = await fetch(`?/delete`, { method: 'POST', body: fd });
		if (res.ok || res.redirected) { toasts.show('Quote deleted'); close(); }
		deleting = false;
	}}
/>

<Modal open title="Edit Quote" subtitle="Update quote · image saved to S3 quarantine" size="lg" onClose={close}>
	{#if form?.error}
		<p class="mb-4 text-sm text-red-600 bg-red-50 rounded-lg px-4 py-2">{form.error}</p>
	{/if}
	<form method="POST" action="?/save" onsubmit={() => handleSuccess()} class="space-y-5">
		<!-- Quote content -->
		<section class="card p-5 space-y-4">
			<p class="section-label">Quote Content</p>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="text">Quote Text <span class="text-red-500">*</span></label>
				<textarea id="text" name="text" rows="4" required class="input resize-y">{String(v.text ?? q.text)}</textarea>
				<p class="mt-1 text-xs text-slate-400">Supports Unicode — Telugu, Devanagari, Sanskrit, etc.</p>
			</div>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="source">Source / Attribution</label>
				<input id="source" name="source" type="text" value={String(v.source ?? q.source ?? '')} class="input" placeholder="— మహాభారతం" />
			</div>
		</section>

		<!-- Image -->
		<section class="card p-5 space-y-3">
			<p class="section-label">Image <span class="text-xs font-normal text-slate-400 ml-1">(saved to S3 quarantine)</span></p>
			{#if imagePreview || imageKey}
				<div class="relative inline-block">
					<img src={imagePreview ?? imageKey ?? ''} alt="" class="h-40 rounded-lg object-cover border border-slate-200" />
					<button type="button" onclick={clearImage} class="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-0.5 hover:bg-red-600">
						<X size={14} />
					</button>
				</div>
				<input type="hidden" name="image_url" value={imageKey ?? ''} />
			{:else}
				<label class="flex flex-col items-center justify-center h-32 border-2 border-dashed border-slate-300 rounded-lg cursor-pointer hover:border-brand-400 hover:bg-brand-50 transition-colors {uploading ? 'opacity-60 pointer-events-none' : ''}">
					<Upload size={24} class="text-slate-400 mb-2" />
					<span class="text-sm text-slate-500">{uploading ? 'Uploading to quarantine…' : 'Click to upload image'}</span>
					<span class="text-xs text-slate-400 mt-0.5">JPG, PNG, WEBP — max 5 MB</span>
					<input type="file" accept="image/*" class="sr-only" onchange={uploadImage} />
				</label>
				<input type="hidden" name="image_url" value="" />
			{/if}
			{#if uploadError}
				<p class="text-xs text-red-600">{uploadError}</p>
			{/if}
		</section>

		<!-- Mantra mapping -->
		<section class="card p-5">
			<p class="section-label mb-3">Mantra Mapping</p>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="mantra_id">Target Mantra</label>
				<select id="mantra_id" name="mantra_id" class="input">
					<option value="">— Universal (shown to all users) —</option>
					{#each data.mantras as m}
						<option value={m.id} selected={(v.mantra_id ?? q.mantraId) === m.id}>
							{m.nameRoman}{m.nameTelugu ? ` · ${m.nameTelugu}` : ''}
						</option>
					{/each}
				</select>
				<p class="mt-1 text-xs text-slate-400">Only members with an active program for this mantra will see this quote.</p>
			</div>
		</section>

		<!-- Settings -->
		<section class="card p-5">
			<p class="section-label mb-3">Settings</p>
			<div class="flex items-center gap-6">
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="sort_order">Sort Order</label>
					<input id="sort_order" name="sort_order" type="number" value={String(v.sort_order ?? q.sortOrder)} min="0" class="input w-28" />
				</div>
				<label class="flex items-center gap-2.5 cursor-pointer pt-6">
					<input id="is_active" name="is_active" type="checkbox"
						checked={(v.is_active !== undefined ? v.is_active !== 'false' : q.isActive)}
						class="h-4 w-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500" />
					<span class="text-sm font-medium text-slate-700">Active (show in app)</span>
				</label>
			</div>
		</section>

		<div class="flex justify-between gap-3">
			<button type="button" onclick={() => showDelete = true} class="inline-flex items-center gap-2 text-sm text-red-600 hover:text-red-700 font-medium">
				<Trash2 size={15} /> Delete Quote
			</button>
			<div class="flex gap-3">
				<button type="button" onclick={close} class="btn-secondary">Cancel</button>
				<button type="submit" class="btn-primary">Save Changes</button>
			</div>
		</div>
	</form>
</Modal>
