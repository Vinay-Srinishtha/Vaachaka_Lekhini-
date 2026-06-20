<script lang="ts">
	import { goto } from '$app/navigation';
	import Modal from '$lib/components/Modal.svelte';
	import ConfirmDialog from '$lib/components/ConfirmDialog.svelte';
	import MediaUploadField from '$lib/components/MediaUploadField.svelte';
	import { toasts } from '$lib/stores/toast';
	import { Trash2, Users, Mic, PenLine, Trophy } from '@lucide/svelte';

	let { data, form } = $props();
	const s = data.sadhana;
	const v = $derived(form?.values ?? {});
	let showDelete = $state(false);
	let deleting = $state(false);
	let selectedStatus = $state<string>(v.status ?? s.status);
	let imageUrl = $state<string | null>(s.imageUrl ?? null);

	function close() { goto('/global-sadhana', { keepFocus: true, noScroll: true }); }
	function handleSuccess() { toasts.show('Global Sadhana updated'); close(); }

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
				<label class="block text-sm font-medium text-slate-700 mb-1.5">Banner Image</label>
				<input id="sadhana-image-url" name="imageUrl" type="hidden" value={imageUrl ?? ''} />
				<MediaUploadField
					category="global-sadhana-image"
					targetId="sadhana-image-url"
					accept="image/*"
					buttonLabel="Upload Banner"
					currentUrl={imageUrl}
					onUrlChange={(url) => { imageUrl = url; }}
				/>
			</div>
			<!-- Status radio cards -->
			<div>
				<p class="block text-sm font-medium text-slate-700 mb-2">Visibility Status</p>
				<div class="grid grid-cols-3 gap-2">
					{#each [
						{ value: 'active',    icon: '🟢', label: 'Active',     desc: 'Live — users can join & contribute' },
						{ value: 'published', icon: '👁️', label: 'Published',  desc: 'Visible but enrollment not yet open' },
						{ value: 'draft',     icon: '📝', label: 'Draft',      desc: 'Hidden from users' },
						{ value: 'paused',    icon: '⏸️', label: 'Paused',     desc: 'Temporarily suspended' },
						{ value: 'completed', icon: '✅', label: 'Completed',  desc: 'Target reached or ended' },
						{ value: 'archived',  icon: '📦', label: 'Archived',   desc: 'Hidden and closed permanently' },
					] as opt}
						<label class="relative flex flex-col gap-1 rounded-xl border-2 cursor-pointer p-3 transition-all
							{selectedStatus === opt.value
								? 'border-brand-500 bg-brand-50/60'
								: 'border-slate-200 bg-white hover:border-slate-300'}">
							<input type="radio" name="status" value={opt.value}
								checked={selectedStatus === opt.value}
								onchange={() => selectedStatus = opt.value}
								class="sr-only" />
							<span class="text-base leading-none">{opt.icon}</span>
							<span class="text-xs font-semibold {selectedStatus === opt.value ? 'text-brand-700' : 'text-slate-700'}">{opt.label}</span>
							<span class="text-[10px] text-slate-400 leading-snug">{opt.desc}</span>
							{#if selectedStatus === opt.value}
								<span class="absolute top-2 right-2 w-4 h-4 rounded-full bg-brand-500 flex items-center justify-center">
									<svg class="w-2.5 h-2.5 text-white" fill="currentColor" viewBox="0 0 12 12"><path d="M10 3L5 8.5 2 5.5l-1 1 4 4 6-7z"/></svg>
								</span>
							{/if}
						</label>
					{/each}
				</div>
				{#if selectedStatus === 'active'}
					<p class="mt-2 text-xs text-emerald-600 font-medium">✓ Users can join and contribute right now</p>
				{:else if selectedStatus === 'draft'}
					<p class="mt-2 text-xs text-amber-600 font-medium">⚠ This sadhana is hidden — switch to Active to make it visible</p>
				{/if}
			</div>

			<label class="flex items-center gap-2.5 cursor-pointer">
				<input name="is_sponsored" type="checkbox" value="true" checked={(v.is_sponsored !== undefined ? v.is_sponsored === 'true' : s.isSponsored)} class="h-4 w-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500" />
				<span class="text-sm font-medium text-slate-700">⭐ Sponsored / Featured</span>
			</label>
		</section>

	</form>
</Modal>
