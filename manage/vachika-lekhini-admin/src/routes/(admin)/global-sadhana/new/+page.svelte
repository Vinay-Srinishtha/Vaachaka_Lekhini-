<script lang="ts">
	import { goto } from '$app/navigation';
	import Modal from '$lib/components/Modal.svelte';
	import MediaUploadField from '$lib/components/MediaUploadField.svelte';
	import { toasts } from '$lib/stores/toast';

	let { data, form } = $props();
	const v = $derived(form?.values ?? {});

	let selectedStatus = $state<string>(v.status ?? 'active');
	let imageUrl = $state<string | null>(null);

	// Default start time = now (in datetime-local format: YYYY-MM-DDTHH:mm)
	function nowLocal() {
		const d = new Date();
		d.setSeconds(0, 0);
		return d.toISOString().slice(0, 16);
	}

	function close() { goto('/global-sadhana', { keepFocus: true, noScroll: true }); }
	function handleSuccess() { toasts.show('Global Sadhana created'); close(); }
</script>

<Modal open title="New Global Sadhana" subtitle="Create a community spiritual initiative" size="lg" formId="sadhana-form" saveLabel="Create Global Sadhana" onClose={close}>
	{#if form?.error}
		<p class="mb-4 text-sm text-red-600 bg-red-50 rounded-lg px-4 py-2">{form.error}</p>
	{/if}
	<form id="sadhana-form" method="POST" enctype="multipart/form-data" onsubmit={() => handleSuccess()} class="space-y-5">
		<!-- Basics -->
		<section class="card p-4 space-y-4">
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
		<section class="card p-4 space-y-4">
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
		<section class="card p-4 space-y-4">
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
					<input id="start_at" name="start_at" type="datetime-local" required value={v.start_at ?? nowLocal()} class="input" />
					<p class="mt-1 text-xs text-slate-400">Defaults to now — users can join immediately</p>
				</div>
				<div>
					<label class="block text-sm font-medium text-slate-700 mb-1.5" for="end_at">End Date & Time (optional)</label>
					<input id="end_at" name="end_at" type="datetime-local" value={v.end_at ?? ''} class="input" />
					<p class="mt-1 text-xs text-slate-400">Leave blank for target-based auto-close</p>
				</div>
			</div>
		</section>

		<!-- Program Image & Settings -->
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
						{ value: 'active',    icon: '🟢', label: 'Active',    desc: 'Live now — users can see and join immediately' },
						{ value: 'published', icon: '👁️', label: 'Published', desc: 'Visible in app but enrollment not yet open' },
						{ value: 'draft',     icon: '📝', label: 'Draft',     desc: 'Hidden from app — save for later' },
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
							<span class="text-sm font-semibold {selectedStatus === opt.value ? 'text-brand-700' : 'text-slate-700'}">{opt.label}</span>
							<span class="text-[11px] text-slate-400 leading-snug">{opt.desc}</span>
							{#if selectedStatus === opt.value}
								<span class="absolute top-2 right-2 w-4 h-4 rounded-full bg-brand-500 flex items-center justify-center">
									<svg class="w-2.5 h-2.5 text-white" fill="currentColor" viewBox="0 0 12 12"><path d="M10 3L5 8.5 2 5.5l-1 1 4 4 6-7z"/></svg>
								</span>
							{/if}
						</label>
					{/each}
				</div>
				{#if selectedStatus === 'active'}
					<p class="mt-2 text-xs text-emerald-600 font-medium">✓ Sadhana will go live immediately after saving</p>
				{/if}
			</div>

			<label class="flex items-center gap-2.5 cursor-pointer">
				<input name="is_sponsored" type="checkbox" checked={v.is_sponsored === 'true'} value="true" class="h-4 w-4 rounded border-slate-300 text-brand-600 focus:ring-brand-500" />
				<span class="text-sm font-medium text-slate-700">⭐ Sponsored / Featured</span>
			</label>
		</section>

	</form>
</Modal>
