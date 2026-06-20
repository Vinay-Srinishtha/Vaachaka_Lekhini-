<script lang="ts">
	import { goto } from '$app/navigation';
	import Modal from '$lib/components/Modal.svelte';
	import ConfirmDialog from '$lib/components/ConfirmDialog.svelte';
	import { toasts } from '$lib/stores/toast';
	import { Trash2, Users, Mic, PenLine, Trophy } from '@lucide/svelte';

	let { data, form } = $props();
	const s = data.sadhana;
	const v = $derived(form?.values ?? {});
	let showDelete = $state(false);
	let deleting = $state(false);
	let saving = $state(false);
	let imagePreview = $state<string | null>(null);
	let imageFileName = $state<string | null>(null);

	function close() { goto('/global-sadhana', { keepFocus: true, noScroll: true }); }
	function handleSuccess() { toasts.show('Global Sadhana updated'); close(); }

	function onImageChange(e: Event) {
		const file = (e.target as HTMLInputElement).files?.[0];
		if (!file) { imagePreview = null; imageFileName = null; return; }
		imageFileName = file.name;
		const reader = new FileReader();
		reader.onload = (ev) => { imagePreview = ev.target?.result as string; };
		reader.readAsDataURL(file);
	}

	const pct = s.targetCount > 0 ? Math.min(100, Math.round((s.currentCount / s.targetCount) * 100)) : 0;
	const fmt = (n: number) => n.toLocaleString('en-IN');

	// Convert stored DateTime to datetime-local string for the input
	function toDatetimeLocal(d: string | Date | null | undefined): string {
		if (!d) return '';
		const dt = new Date(d);
		return dt.toISOString().slice(0, 16);
	}
</script>

<ConfirmDialog
	open={showDelete}
	title="Delete Global Sadhana?"
	message={`Permanently remove "${s.title}" and all enrollments & contributions?`}
	confirmLabel="Delete"
	submitting={deleting}
	onCancel={() => showDelete = false}
	onConfirm={async () => {
		deleting = true;
		const fd = new FormData();
		const res = await fetch('?/delete', { method: 'POST', body: fd });
		if (res.ok || res.redirected) { toasts.show('Sadhana deleted'); close(); }
		deleting = false;
	}}
/>

<Modal open title="Edit Global Sadhana" subtitle={s.title} size="xl" formId="sadhana-form" saveLabel="Save Changes" onClose={close}>
	{#snippet headerLeft()}
		<button type="button" onclick={() => showDelete = true} class="inline-flex items-center gap-1.5 text-sm text-red-400 hover:text-red-300 font-medium transition-colors">
			<Trash2 size={14} /> Delete
		</button>
	{/snippet}
	{#if form?.error}
		<p class="mb-4 text-sm text-red-600 bg-red-50 rounded-lg px-4 py-2">{form.error}</p>
	{/if}

	<!-- Analytics panel -->
	<div class="mb-6 grid grid-cols-2 sm:grid-cols-4 gap-3">
		<div class="card p-4 text-center">
			<p class="text-2xl font-bold text-slate-900">{fmt(s.currentCount)}</p>
			<p class="text-xs text-slate-500 mt-0.5">Current Count</p>
		</div>
		<div class="card p-4 text-center">
			<p class="text-2xl font-bold text-slate-900">{fmt(s.targetCount)}</p>
			<p class="text-xs text-slate-500 mt-0.5">Target</p>
		</div>
		<div class="card p-4 text-center">
			<p class="text-2xl font-bold text-slate-900">{s._count.enrollments}</p>
			<p class="text-xs text-slate-500 mt-0.5 flex items-center justify-center gap-1"><Users size={11} /> Enrolled</p>
		</div>
		<div class="card p-4 text-center">
			<p class="text-2xl font-bold text-slate-900">{pct}%</p>
			<p class="text-xs text-slate-500 mt-0.5">Progress</p>
		</div>
	</div>

	<!-- Progress bar -->
	<div class="mb-6">
		<div class="h-3 rounded-full bg-slate-100 overflow-hidden">
			<div class="h-full rounded-full bg-brand-500 transition-all" style="width: {pct}%"></div>
		</div>
		<div class="mt-2 flex justify-between text-xs text-slate-400">
			<span>Voice: {fmt(data.stats.byVoice)}</span>
			<span>Handwriting: {fmt(data.stats.byHandwriting)}</span>
		</div>
	</div>

	<!-- Top Contributors -->
	{#if data.topContributors.length > 0}
		<details class="mb-6 rounded-lg border border-slate-200 bg-slate-50">
			<summary class="cursor-pointer px-4 py-2.5 font-medium text-sm text-slate-700 select-none flex items-center gap-2">
				<Trophy size={14} /> Top Contributors
			</summary>
			<div class="px-4 pb-3">
				<table class="w-full text-xs mt-2">
					<tbody class="divide-y divide-slate-100">
						{#each data.topContributors as c, i}
							<tr>
								<td class="py-1.5 pr-3 text-slate-400 font-mono">{i + 1}</td>
								<td class="py-1.5 flex-1">{c.name}</td>
								<td class="py-1.5 text-right font-semibold text-slate-700">{fmt(c.count)}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</details>
	{/if}

	<form id="sadhana-form" method="POST" action="?/save" enctype="multipart/form-data" onsubmit={() => handleSuccess()} class="space-y-5">
		<section class="card p-4 space-y-4">
			<p class="section-label">Program Details</p>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="title">Title <span class="text-red-500">*</span></label>
				<input id="title" name="title" type="text" required value={String(v.title ?? s.title)} class="input" />
			</div>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="description">Description</label>
				<textarea id="description" name="description" rows="3" class="input resize-y">{String(v.description ?? s.description)}</textarea>
			</div>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="instructions">Instructions</label>
				<textarea id="instructions" name="instructions" rows="3" class="input resize-y">{String(v.instructions ?? s.instructions ?? '')}</textarea>
			</div>
		</section>

		<section class="card p-4 space-y-4">
			<p class="section-label">Mantra</p>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="mantra_id">Mantra</label>
				<select id="mantra_id" name="mantra_id" required class="input">
					{#each data.mantras as m}
						<option value={m.id} selected={(v.mantra_id ?? s.mantraId) === m.id}>{m.nameRoman}{m.nameTelugu ? ` · ${m.nameTelugu}` : ''}</option>
					{/each}
				</select>
			</div>
			<div class="grid grid-cols-2 gap-4">
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="mantra_text">Mantra text override</label>
					<input id="mantra_text" name="mantra_text" type="text" value={String(v.mantra_text ?? s.mantraText ?? '')} class="input" />
				</div>
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="mantra_language">Script</label>
					<select id="mantra_language" name="mantra_language" class="input">
						{#each [['hi','Devanagari'],['te','Telugu'],['kn','Kannada'],['en','Roman']] as [val, label]}
							<option value={val} selected={(v.mantra_language ?? s.mantraLanguage) === val}>{label}</option>
						{/each}
					</select>
				</div>
			</div>
		</section>

		<section class="card p-4 space-y-4">
			<p class="section-label">Target & Schedule</p>
			<div class="grid grid-cols-2 gap-4">
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="target_count">Target Count</label>
					<input id="target_count" name="target_count" type="number" min="1" required value={String(v.target_count ?? s.targetCount)} class="input" />
				</div>
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="participation_mode">Participation Mode</label>
					<select id="participation_mode" name="participation_mode" class="input">
						<option value="both" selected={(v.participation_mode ?? s.participationMode) === 'both'}>Voice & Handwriting</option>
						<option value="voice" selected={(v.participation_mode ?? s.participationMode) === 'voice'}>Voice only</option>
						<option value="handwriting" selected={(v.participation_mode ?? s.participationMode) === 'handwriting'}>Handwriting only</option>
					</select>
				</div>
			</div>
			<div class="grid grid-cols-2 gap-4">
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="start_at">Start</label>
					<input id="start_at" name="start_at" type="datetime-local" required value={toDatetimeLocal(typeof v.start_at === 'string' ? v.start_at : s.startAt)} class="input" />
				</div>
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="end_at">End (optional)</label>
					<input id="end_at" name="end_at" type="datetime-local" value={toDatetimeLocal(typeof v.end_at === 'string' ? v.end_at : s.endAt)} class="input" />
				</div>
			</div>
		</section>

		<section class="card p-4 space-y-4">
			<p class="section-label">Program Image</p>
			<div>
				<label class="block text-sm font-medium text-slate-700 mb-1.5" for="image">Banner Image</label>
				<label for="image" class="flex flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed border-slate-300 bg-slate-50 hover:bg-slate-100 transition-colors cursor-pointer p-6 text-center">
					{#if imagePreview}
						<img src={imagePreview} alt="Preview" class="max-h-48 rounded-lg object-contain" />
						<span class="text-xs text-slate-500 mt-1">{imageFileName}</span>
						<span class="text-xs text-brand-600 font-medium">Click to change</span>
					{:else if s.imageUrl}
						<img src={s.imageUrl} alt="Current image" class="max-h-48 rounded-lg object-contain" />
						<span class="text-xs text-slate-500 mt-1">Current image · click to replace</span>
					{:else}
						<svg class="w-10 h-10 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>
						<span class="text-sm text-slate-600 font-medium">Click or drag to upload an image</span>
						<span class="text-xs text-slate-400">PNG, JPG, WebP up to 10MB</span>
					{/if}
				</label>
				<input id="image" name="image" type="file" accept="image/*" class="sr-only" onchange={onImageChange} />
			</div>
			<div class="flex items-center gap-6 flex-wrap">
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="status">Status</label>
					<select id="status" name="status" class="input w-40">
						{#each ['draft','published','active','paused','completed','archived'] as st}
							<option value={st} selected={(v.status ?? s.status) === st}>{st.charAt(0).toUpperCase() + st.slice(1)}</option>
						{/each}
					</select>
				</div>
				<label class="flex items-center gap-2.5 cursor-pointer pt-6">
					<input name="is_sponsored" type="checkbox" value="true" checked={(v.is_sponsored !== undefined ? v.is_sponsored === 'true' : s.isSponsored)} class="h-4 w-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500" />
					<span class="text-sm font-medium text-slate-700">⭐ Sponsored / Featured</span>
				</label>
			</div>
		</section>

	</form>
</Modal>
