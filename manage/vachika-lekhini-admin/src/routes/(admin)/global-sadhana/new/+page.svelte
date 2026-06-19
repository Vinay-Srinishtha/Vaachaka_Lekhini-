<script lang="ts">
	import { goto } from '$app/navigation';
	import Modal from '$lib/components/Modal.svelte';

	let { data, form } = $props();
	const v = $derived(form?.values ?? {});

	let imagePreview = $state<string | null>(null);
	let imageFileName = $state<string | null>(null);

	function close() { goto('/global-sadhana', { keepFocus: true, noScroll: true }); }

	function onImageChange(e: Event) {
		const file = (e.target as HTMLInputElement).files?.[0];
		if (!file) { imagePreview = null; imageFileName = null; return; }
		imageFileName = file.name;
		const reader = new FileReader();
		reader.onload = (ev) => { imagePreview = ev.target?.result as string; };
		reader.readAsDataURL(file);
	}
</script>

<Modal open title="New Global Sadhana" subtitle="Create a community spiritual initiative" size="lg" onClose={close}>
	{#if form?.error}
		<p class="mb-4 text-sm text-red-600 bg-red-50 rounded-lg px-4 py-2">{form.error}</p>
	{/if}
	<form method="POST" enctype="multipart/form-data" class="space-y-5">
		<!-- Basics -->
		<section class="card p-5 space-y-4">
			<p class="section-label">Program Details</p>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="title">Title <span class="text-red-500">*</span></label>
				<input id="title" name="title" type="text" required value={v.title ?? ''} class="input" placeholder="e.g. 108 Lakh Rama Nama Japa" />
			</div>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="description">Description</label>
				<textarea id="description" name="description" rows="3" class="input resize-y">{v.description ?? ''}</textarea>
			</div>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="instructions">Instructions for participants</label>
				<textarea id="instructions" name="instructions" rows="3" class="input resize-y" placeholder="What should participants do? Rules, guidelines…">{v.instructions ?? ''}</textarea>
			</div>
		</section>

		<!-- Mantra -->
		<section class="card p-5 space-y-4">
			<p class="section-label">Mantra</p>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="mantra_id">Mantra <span class="text-red-500">*</span></label>
				<select id="mantra_id" name="mantra_id" required class="input">
					<option value="">— Select a mantra —</option>
					{#each data.mantras as m}
						<option value={m.id} selected={(v.mantra_id) === m.id}>{m.nameRoman}{m.nameTelugu ? ` · ${m.nameTelugu}` : ''}</option>
					{/each}
				</select>
			</div>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="mantra_text">Mantra text (optional override)</label>
				<input id="mantra_text" name="mantra_text" type="text" value={v.mantra_text ?? ''} class="input" placeholder="e.g. ॐ नमः शिवाय" />
			</div>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="mantra_language">Mantra script</label>
				<select id="mantra_language" name="mantra_language" class="input">
					{#each [['hi','Devanagari (Hindi)'],['te','Telugu'],['kn','Kannada'],['en','Roman (English)']] as [val, label]}
						<option value={val} selected={(v.mantra_language ?? 'hi') === val}>{label}</option>
					{/each}
				</select>
			</div>
		</section>

		<!-- Target & Schedule -->
		<section class="card p-5 space-y-4">
			<p class="section-label">Target & Schedule</p>
			<div class="grid grid-cols-2 gap-4">
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="target_count">Global Target Count <span class="text-red-500">*</span></label>
					<input id="target_count" name="target_count" type="number" required min="1" value={v.target_count ?? '10800000'} class="input" />
					<p class="mt-1 text-xs text-slate-400">e.g. 10800000 = 1 crore 8 lakh</p>
				</div>
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="participation_mode">Participation Mode</label>
					<select id="participation_mode" name="participation_mode" class="input">
						<option value="both" selected={(v.participation_mode ?? 'both') === 'both'}>Voice & Handwriting</option>
						<option value="voice" selected={v.participation_mode === 'voice'}>Voice chanting only</option>
						<option value="handwriting" selected={v.participation_mode === 'handwriting'}>Handwriting only</option>
					</select>
				</div>
			</div>
			<div class="grid grid-cols-2 gap-4">
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="start_at">Start Date & Time <span class="text-red-500">*</span></label>
					<input id="start_at" name="start_at" type="datetime-local" required value={v.start_at ?? ''} class="input" />
				</div>
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="end_at">End Date & Time (optional)</label>
					<input id="end_at" name="end_at" type="datetime-local" value={v.end_at ?? ''} class="input" />
					<p class="mt-1 text-xs text-slate-400">Leave blank for target-based auto-close</p>
				</div>
			</div>
		</section>

		<!-- Program Image & Settings -->
		<section class="card p-5 space-y-4">
			<p class="section-label">Program Image</p>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="image">Banner Image</label>
				<label for="image" class="flex flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed border-slate-300 bg-slate-50 hover:bg-slate-100 transition-colors cursor-pointer p-6 text-center">
					{#if imagePreview}
						<img src={imagePreview} alt="Preview" class="max-h-48 rounded-lg object-contain" />
						<span class="text-xs text-slate-500 mt-1">{imageFileName}</span>
						<span class="text-xs text-brand-600 font-medium">Click to change</span>
					{:else}
						<svg class="w-10 h-10 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
						<span class="text-sm text-slate-600 font-medium">Click or drag to upload an image</span>
						<span class="text-xs text-slate-400">PNG, JPG, WebP up to 10MB</span>
					{/if}
				</label>
				<input id="image" name="image" type="file" accept="image/*" class="sr-only" onchange={onImageChange} />
			</div>
			<div class="flex items-center gap-6">
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="status">Initial Status</label>
					<select id="status" name="status" class="input w-40">
						<option value="draft" selected={(v.status ?? 'draft') === 'draft'}>Draft</option>
						<option value="published" selected={v.status === 'published'}>Published</option>
						<option value="active" selected={v.status === 'active'}>Active (live)</option>
					</select>
				</div>
				<label class="flex items-center gap-2.5 cursor-pointer pt-6">
					<input name="is_sponsored" type="checkbox" checked={v.is_sponsored === 'true'} value="true" class="h-4 w-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500" />
					<span class="text-sm font-medium text-slate-700">⭐ Sponsored / Featured</span>
				</label>
			</div>
		</section>

		<div class="flex justify-end gap-3">
			<button type="button" onclick={close} class="btn-secondary">Cancel</button>
			<button type="submit" class="btn-primary">Create Global Sadhana</button>
		</div>
	</form>
</Modal>
