<script lang="ts">
	import { enhance } from '$app/forms';
	import FormField from './FormField.svelte';
	import MediaUploadField from './MediaUploadField.svelte';
	import TagMultiSelect from './TagMultiSelect.svelte';
	import { MANTRA_TAGS } from '$lib/constants';
	import { Save, Plus, Trash2, Image, Music, Share2 } from '@lucide/svelte';

	interface MantraMilestone {
		count: number;
		dayOptions: number[];
	}

	interface MantraValue {
		id?: string;
		slug: string;
		nameDevanagari: string;
		nameRoman: string;
		nameTelugu: string | null;
		nameKannada: string | null;
		description: string;
		deity: string | null;
		tags: string[];
		recommendedCount: number | null;
		recommendedDays: number | null;
		pronunciationUrl: string | null;
		previewImageUrl: string | null;
		imageUrl: string | null;
		shareImageUrl: string | null;
		shareText: string | null;
		milestones: MantraMilestone[] | null;
		isActive: boolean;
		sortOrder: number;
	}

	const DEFAULT_MILESTONES: MantraMilestone[] = [
		{ count: 108,   dayOptions: [1,  7,   21,  40]  },
		{ count: 1008,  dayOptions: [7,  21,  40,  108] },
		{ count: 5116,  dayOptions: [21, 40,  108, 180] },
		{ count: 10116, dayOptions: [40, 108, 180, 365] }
	];

	interface Props {
		value: MantraValue;
		fieldErrors?: Record<string, string>;
		generalError?: string | null;
		submitLabel?: string;
		isEdit?: boolean;
		onSuccess?: () => void;
		/** When true, the built-in bottom action bar is hidden (Modal topbar handles it). */
		inModal?: boolean;
	}

	let {
		value,
		fieldErrors = {},
		generalError = null,
		submitLabel = 'Save',
		isEdit = false,
		onSuccess,
		inModal = false
	}: Props = $props();

	let tags = $state<string[]>([]);
	$effect.pre(() => { tags = [...value.tags]; });

	let milestones = $state<MantraMilestone[]>([]);
	$effect.pre(() => {
		milestones = (value.milestones && value.milestones.length > 0)
			? value.milestones.map(m => ({ count: m.count, dayOptions: [...m.dayOptions] }))
			: DEFAULT_MILESTONES.map(m => ({ count: m.count, dayOptions: [...m.dayOptions] }));
	});

	const milestonesJson = $derived(JSON.stringify(milestones));

	function addMilestone() { milestones = [...milestones, { count: 0, dayOptions: [1] }]; }
	function removeMilestone(i: number) { milestones = milestones.filter((_, idx) => idx !== i); }
	function updateMilestoneCount(i: number, val: number) {
		milestones = milestones.map((m, idx) => idx === i ? { ...m, count: val } : m);
	}
	function updateDayOptions(i: number, raw: string) {
		const days = raw.split(',').map(s => parseInt(s.trim(), 10)).filter(n => !isNaN(n) && n > 0);
		milestones = milestones.map((m, idx) => idx === i ? { ...m, dayOptions: days } : m);
	}

	let isActive = $state(value.isActive);
	$effect.pre(() => { isActive = value.isActive; });

	// Local state for image URLs so MediaUploadField callbacks can update them
	// and the hidden inputs re-render with the correct value for form submission.
	let previewImageUrl = $state<string | null>(value.previewImageUrl ?? null);
	let imageUrl = $state<string | null>(value.imageUrl ?? null);
	let pronunciationUrl = $state<string | null>(value.pronunciationUrl ?? null);
	let shareImageUrl = $state<string | null>(value.shareImageUrl ?? null);
	$effect.pre(() => {
		previewImageUrl = value.previewImageUrl ?? null;
		imageUrl = value.imageUrl ?? null;
		pronunciationUrl = value.pronunciationUrl ?? null;
		shareImageUrl = value.shareImageUrl ?? null;
	});

	let submitting = $state(false);
</script>

<form
	id="mantra-form"
	method="POST"
	class="flex flex-col h-full gap-3"
	use:enhance={() => {
		submitting = true;
		return async ({ result, update }) => {
			if (result.type === 'redirect' || result.type === 'success') {
				onSuccess?.();
				if (result.type !== 'redirect') await update();
			} else {
				await update();
			}
			submitting = false;
		};
	}}
>
	{#if generalError}
		<div class="text-base rounded-xl bg-red-50 text-red-700 border border-red-200 px-5 py-4 shrink-0">
			{generalError}
		</div>
	{/if}

	<!-- ══ 4-COLUMN GRID — zero wasted space ══════════════════════════════ -->
	<!--
		Col 1 (narrow): Identity + Names — both compact, stack naturally
		Col 2 (wide):   Description (flex-1) + Deity inline row
		Col 3:          Preview Image (flex-1) + Main Image (flex-1)
		Col 4:          Tags + Defaults + Audio (flex-1) + Published
	-->
	<div class="flex-1 min-h-0 grid gap-2" style="grid-template-columns: 1fr 1.4fr 1fr 1fr">

		<!-- ╔══ COL 1: Identity + Names ════════════════════════════════════╗ -->
		<div class="flex flex-col gap-2 min-h-0">

			<!-- Identity -->
			<div class="rounded-xl border border-indigo-100 bg-white shadow-sm overflow-hidden shrink-0">
				<div class="px-3 pt-3 pb-2 border-b border-indigo-50 bg-indigo-50/40">
					<span class="section-label text-indigo-800">Identity</span>
				</div>
				<div class="p-3 flex flex-col gap-2">
					<FormField label="Slug *" name="slug" error={fieldErrors.slug}
						hint={isEdit ? 'Cannot change after release.' : 'Lowercase + underscores'}>
						<input id="slug" name="slug" class="input py-1.5 text-sm" value={value.slug}
							readonly={isEdit} required autocomplete="off"
							class:opacity-60={isEdit} class:cursor-not-allowed={isEdit} />
					</FormField>
					<FormField label="Sort order" name="sortOrder" hint="Lower = first." error={fieldErrors.sortOrder}>
						<input id="sortOrder" name="sortOrder" type="number" class="input py-1.5 text-sm" value={value.sortOrder} />
					</FormField>
				</div>
			</div>

			<!-- Names -->
			<div class="rounded-xl border border-violet-100 bg-white shadow-sm overflow-hidden shrink-0">
				<div class="px-3 pt-3 pb-2 border-b border-violet-50 bg-violet-50/40">
					<span class="section-label text-violet-800">Names</span>
				</div>
				<div class="p-3 grid grid-cols-2 gap-2">
					<FormField label="Devanagari *" name="nameDevanagari" error={fieldErrors.nameDevanagari}>
						<input id="nameDevanagari" name="nameDevanagari" class="input py-1.5 text-sm font-devanagari"
							value={value.nameDevanagari} required />
					</FormField>
					<FormField label="Roman *" name="nameRoman" error={fieldErrors.nameRoman}>
						<input id="nameRoman" name="nameRoman" class="input py-1.5 text-sm" value={value.nameRoman} required />
					</FormField>
					<FormField label="Telugu" name="nameTelugu" error={fieldErrors.nameTelugu}>
						<input id="nameTelugu" name="nameTelugu" class="input py-1.5 text-sm" value={value.nameTelugu ?? ''} />
					</FormField>
					<FormField label="Kannada" name="nameKannada" error={fieldErrors.nameKannada}>
						<input id="nameKannada" name="nameKannada" class="input py-1.5 text-sm" value={value.nameKannada ?? ''} />
					</FormField>
				</div>
			</div>

			<!-- Milestones (moved here — compact 2×2 grid in col 1 bottom) -->
			<div class="flex-1 min-h-0 rounded-xl border border-amber-100 bg-white shadow-sm overflow-hidden flex flex-col">
				<div class="px-3 pt-3 pb-2 border-b border-amber-50 bg-amber-50/40 flex items-center gap-2 shrink-0">
					<span class="flex-1 section-label text-amber-800">Preset Goals</span>
					<button type="button" onclick={addMilestone}
						class="flex items-center gap-1 rounded-lg border border-dashed border-slate-200 bg-slate-50
							px-2.5 py-1 text-xs font-semibold text-slate-500 hover:bg-slate-100 transition-colors">
						<Plus size={11} /> Add
					</button>
				</div>
				<div class="flex-1 min-h-0 overflow-y-auto p-2">
					<div class="grid grid-cols-2 gap-2">
						{#each milestones as milestone, i (i)}
							<div class="relative rounded-xl border border-slate-100 bg-slate-50 p-2.5 space-y-2
								hover:border-brand-200 hover:bg-brand-50/40 transition-colors">
								<button type="button" onclick={() => removeMilestone(i)}
									class="absolute top-1.5 right-1.5 rounded p-0.5 text-slate-300 hover:text-red-400 transition-colors">
									<Trash2 size={11} />
								</button>
								<div>
									<p class="text-[10px] font-bold uppercase tracking-widest text-slate-400 mb-1">Count</p>
									<input type="number" min="1" value={milestone.count}
										oninput={(e) => updateMilestoneCount(i, parseInt((e.target as HTMLInputElement).value, 10))}
										class="input text-sm font-bold w-full py-1.5" placeholder="108" />
								</div>
								<div>
									<p class="text-[10px] font-bold uppercase tracking-widest text-slate-400 mb-1">Days</p>
									<input type="text" value={milestone.dayOptions.join(', ')}
										oninput={(e) => updateDayOptions(i, (e.target as HTMLInputElement).value)}
										class="input text-xs font-mono w-full py-1.5" placeholder="1, 7, 21" />
								</div>
								<div class="flex gap-1 flex-wrap">
									{#each milestone.dayOptions.slice(0, 4) as d, di}
										<span class="rounded px-1.5 py-0.5 text-[10px] font-bold
											{di === 0 ? 'bg-indigo-100 text-indigo-700 ring-1 ring-indigo-200' : 'bg-slate-200 text-slate-500'}">
											{d}d
										</span>
									{/each}
								</div>
							</div>
						{/each}
						{#if milestones.length === 0}
							<div class="col-span-2 flex items-center justify-center py-6 text-slate-400 text-sm">
								No milestones — click Add
							</div>
						{/if}
					</div>
					<input type="hidden" name="milestones" value={milestonesJson} />
				</div>
			</div>

		</div>

		<!-- ╔══ COL 2: Content (fills height) ═════════════════════════════╗ -->
		<div class="flex flex-col gap-2 min-h-0">
			<div class="flex-1 min-h-0 rounded-xl border border-emerald-100 bg-white shadow-sm overflow-hidden flex flex-col">
				<div class="px-3 pt-3 pb-2 border-b border-emerald-50 bg-emerald-50/40 shrink-0">
					<span class="section-label text-emerald-800">Content</span>
				</div>
				<div class="flex-1 p-3 flex flex-col gap-2 min-h-0">
					<div class="flex-1 min-h-0 flex flex-col">
						<label class="mb-1 block text-xs font-medium text-slate-600" for="description">Description *</label>
						<textarea id="description" name="description"
							class="input resize-none leading-relaxed text-sm py-2 w-full flex-1 min-h-0"
							style="min-height:80px"
							required>{value.description}</textarea>
						{#if fieldErrors.description}<p class="mt-1 text-xs text-red-600">{fieldErrors.description}</p>{/if}
					</div>
					<FormField label="Deity" name="deity" error={fieldErrors.deity} hint="Drives hero colour in app.">
						<input id="deity" name="deity" class="input py-1.5 text-sm" value={value.deity ?? ''} />
					</FormField>
				</div>
			</div>
		</div>

		<!-- ╔══ COL 3: Images ═══════════════════════════════════════════════╗ -->
		<div class="flex flex-col gap-2 min-h-0">

			<!-- Preview Image -->
			<div class="flex-1 min-h-0 rounded-xl border border-amber-100 bg-white shadow-sm overflow-hidden flex flex-col">
				<div class="px-3 pt-3 pb-2 border-b border-amber-50 bg-amber-50/40 flex items-center gap-1.5 shrink-0">
					<Image size={12} class="text-amber-500" />
					<span class="section-label text-amber-800">Preview Image</span>
					<span class="ml-auto text-[10px] text-slate-400 normal-case tracking-normal">List &amp; reminders</span>
				</div>
				<div class="flex-1 min-h-0 p-3 overflow-y-auto">
					<MediaUploadField
						category="mantra-preview"
						targetId="previewImageUrl"
						accept="image/*"
						buttonLabel={previewImageUrl ? 'Replace' : 'Upload preview'}
						currentUrl={previewImageUrl}
						onUrlChange={(url) => { previewImageUrl = url; }}
					/>
					<input type="hidden" id="previewImageUrl" name="previewImageUrl" value={previewImageUrl ?? ''} />
				</div>
			</div>

			<!-- Main Image -->
			<div class="flex-1 min-h-0 rounded-xl border border-sky-100 bg-white shadow-sm overflow-hidden flex flex-col">
				<div class="px-3 pt-3 pb-2 border-b border-sky-50 bg-sky-50/40 flex items-center gap-1.5 shrink-0">
					<Image size={12} class="text-sky-500" />
					<span class="section-label text-sky-800">Main Image</span>
					<span class="ml-auto text-[10px] text-slate-400 normal-case tracking-normal">Detail view</span>
				</div>
				<div class="flex-1 min-h-0 p-3 overflow-y-auto">
					<MediaUploadField
						category="mantra-image"
						targetId="imageUrl"
						accept="image/*"
						buttonLabel={imageUrl ? 'Replace' : 'Upload image'}
						currentUrl={imageUrl}
						onUrlChange={(url) => { imageUrl = url; }}
					/>
					<input type="hidden" id="imageUrl" name="imageUrl" value={imageUrl ?? ''} />
				</div>
			</div>

		</div>

		<!-- ╔══ COL 4: Tags + Defaults + Audio + Published ═════════════════╗ -->
		<div class="flex flex-col gap-2 min-h-0">

			<!-- Tags -->
			<div class="rounded-xl border border-rose-100 bg-white shadow-sm overflow-hidden shrink-0">
				<div class="px-3 pt-3 pb-2 border-b border-rose-50 bg-rose-50/40">
					<span class="section-label text-rose-800">Tags</span>
					<span class="ml-1.5 text-[10px] text-slate-400 normal-case tracking-normal">Mantra-by-Need</span>
				</div>
				<div class="p-3">
					<TagMultiSelect name="tags" options={MANTRA_TAGS} bind:value={tags} />
				</div>
			</div>

			<!-- Practice Defaults -->
			<div class="rounded-xl border border-teal-100 bg-white shadow-sm overflow-hidden shrink-0">
				<div class="px-3 pt-3 pb-2 border-b border-teal-50 bg-teal-50/40">
					<span class="section-label text-teal-800">Practice Defaults</span>
				</div>
				<div class="p-3 grid grid-cols-2 gap-2">
					<FormField label="Rec. count" name="recommendedCount" hint="Per-day." error={fieldErrors.recommendedCount}>
						<input id="recommendedCount" name="recommendedCount" type="number" min="1"
							class="input py-1.5 text-sm" value={value.recommendedCount ?? ''} />
					</FormField>
					<FormField label="Rec. days" name="recommendedDays" hint="Optional." error={fieldErrors.recommendedDays}>
						<input id="recommendedDays" name="recommendedDays" type="number" min="1"
							class="input py-1.5 text-sm" value={value.recommendedDays ?? ''} />
					</FormField>
				</div>
			</div>

			<!-- Pronunciation Audio -->
			<div class="flex-1 min-h-0 rounded-xl border border-purple-100 bg-white shadow-sm overflow-hidden flex flex-col">
				<div class="px-3 pt-3 pb-2 border-b border-purple-50 bg-purple-50/40 flex items-center gap-1.5 shrink-0">
					<Music size={12} class="text-purple-500" />
					<span class="section-label text-purple-800">Pronunciation Audio</span>
				</div>
				<div class="flex-1 min-h-0 p-3 overflow-y-auto">
					<MediaUploadField
						category="mantra-audio"
						targetId="pronunciationUrl"
						accept="audio/mpeg,audio/mp3,audio/wav,audio/x-wav"
						buttonLabel="Upload MP3 / WAV"
						currentUrl={pronunciationUrl}
						onUrlChange={(url) => { pronunciationUrl = url; }}
					/>
					<input type="hidden" id="pronunciationUrl" name="pronunciationUrl" value={pronunciationUrl ?? ''} />
				</div>
			</div>

			<!-- Share / WhatsApp -->
			<div class="flex-1 min-h-0 rounded-xl border border-green-100 bg-white shadow-sm overflow-hidden flex flex-col">
				<div class="px-3 pt-3 pb-2 border-b border-green-50 bg-green-50/40 flex items-center gap-1.5 shrink-0">
					<Share2 size={12} class="text-green-600" />
					<span class="section-label text-green-800">Share / WhatsApp</span>
				</div>
				<div class="flex-1 min-h-0 p-3 overflow-y-auto space-y-3">
					<!-- Share image -->
					<div>
						<p class="text-[10px] font-semibold text-slate-500 uppercase tracking-wider mb-1.5">Share Image</p>
						<MediaUploadField
							category="mantra-share"
							targetId="shareImageUrl"
							accept="image/*"
							buttonLabel={shareImageUrl ? 'Replace' : 'Upload share image'}
							currentUrl={shareImageUrl}
							onUrlChange={(url) => { shareImageUrl = url; }}
						/>
						<input type="hidden" id="shareImageUrl" name="shareImageUrl" value={shareImageUrl ?? ''} />
					</div>
					<!-- Share text template -->
					<div>
						<p class="text-[10px] font-semibold text-slate-500 uppercase tracking-wider mb-1">Message Template</p>
						<textarea
							name="shareText"
							rows="4"
							placeholder="🙏 I am chanting {mantra_name}!&#10;Count: {chant_count}&#10;&#10;Join me: {app_link}"
							class="w-full rounded-lg border border-slate-200 px-2.5 py-2 text-xs font-mono focus:border-green-400 focus:outline-none focus:ring-1 focus:ring-green-400 resize-none"
						>{value.shareText ?? ''}</textarea>
						<p class="mt-1 text-[10px] text-slate-400">
							Placeholders: <code class="bg-slate-100 px-1 rounded">{'{mantra_name}'}</code>
							<code class="bg-slate-100 px-1 rounded">{'{chant_count}'}</code>
							<code class="bg-slate-100 px-1 rounded">{'{app_link}'}</code>
						</p>
					</div>
				</div>
			</div>

			<!-- Published -->
			<div class="shrink-0 rounded-xl border border-slate-100 bg-white shadow-sm overflow-hidden">
				<label class="flex items-center gap-3 px-3 py-3 cursor-pointer select-none">
					<input type="checkbox" name="isActive" bind:checked={isActive} class="sr-only" />
					<div class="relative shrink-0 w-10 h-[22px] rounded-full transition-all duration-300 cursor-pointer
						{isActive ? 'bg-emerald-500 shadow-emerald-200 shadow-md' : 'bg-slate-200'}">
						<span class="absolute top-0.5 w-4 h-4 rounded-full bg-white shadow-md transition-all duration-300
							{isActive ? 'left-[calc(100%-1.125rem)]' : 'left-0.5'}"></span>
					</div>
					<div>
						<p class="text-sm font-semibold transition-colors {isActive ? 'text-emerald-700' : 'text-slate-500'}">
							{isActive ? 'Published' : 'Draft'}
						</p>
						<p class="text-xs {isActive ? 'text-emerald-500' : 'text-slate-400'}">
							{isActive ? 'Live in Flutter app' : 'Hidden from users'}
						</p>
					</div>
				</label>
			</div>

		</div>

	</div><!-- /4-col -->

	<!-- ══ ACTIONS ═══════════════════════════════════════════════════════════ -->
	{#if !inModal}
	<div class="shrink-0 flex items-center justify-between">
		<a href="/mantras" class="btn-secondary">Cancel</a>
		<button type="submit"
			class="flex items-center gap-2.5 px-6 py-2.5 rounded-xl font-semibold text-base
				bg-brand-600 text-white shadow-md shadow-brand-200
				hover:bg-brand-700 hover:shadow-lg hover:shadow-brand-200
				disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-150"
			disabled={submitting}>
			<Save size={16} />
			{submitting ? 'Saving…' : submitLabel}
		</button>
	</div>
	{/if}

</form>
