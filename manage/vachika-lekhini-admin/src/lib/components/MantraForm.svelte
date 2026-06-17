<script lang="ts">
	import { enhance } from '$app/forms';
	import FormField from './FormField.svelte';
	import MediaUploadField from './MediaUploadField.svelte';
	import TagMultiSelect from './TagMultiSelect.svelte';
	import { MANTRA_TAGS } from '$lib/constants';
	import { Save, Plus, Trash2, Image, Music } from '@lucide/svelte';

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
	}

	let {
		value,
		fieldErrors = {},
		generalError = null,
		submitLabel = 'Save',
		isEdit = false,
		onSuccess
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
	$effect.pre(() => {
		previewImageUrl = value.previewImageUrl ?? null;
		imageUrl = value.imageUrl ?? null;
	});

	let submitting = $state(false);
</script>

<form
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

	<!-- ══ 3-COLUMN — grows to fill available height ══════════════════════ -->
	<div class="flex-1 min-h-0 grid grid-cols-3 gap-3">

		<!-- ╔══ COL 1 ══════════════════════════════════════════════════════╗ -->
		<div class="flex flex-col gap-3 min-h-0">

			<!-- Identity -->
			<div class="rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden shrink-0">
				<div class="px-5 pt-4 pb-3 border-b border-slate-100">
					<span class="section-label">Identity</span>
				</div>
				<div class="p-4 grid grid-cols-2 gap-3">
					<div class="col-span-2">
						<FormField label="Slug *" name="slug" error={fieldErrors.slug}
							hint={isEdit ? 'Cannot change after release.' : 'Lowercase, digits, underscores.'}>
							<input id="slug" name="slug" class="input py-2 text-base" value={value.slug}
								readonly={isEdit} required autocomplete="off"
								class:opacity-60={isEdit} class:cursor-not-allowed={isEdit} />
						</FormField>
					</div>
					<div class="col-span-2">
						<FormField label="Sort order" name="sortOrder" hint="Lower = first." error={fieldErrors.sortOrder}>
							<input id="sortOrder" name="sortOrder" type="number" class="input py-2 text-base" value={value.sortOrder} />
						</FormField>
					</div>
				</div>
			</div>

			<!-- Names -->
			<div class="rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden shrink-0">
				<div class="px-5 pt-4 pb-3 border-b border-slate-100">
					<span class="section-label">Names</span>
				</div>
				<div class="p-4 grid grid-cols-2 gap-3">
					<FormField label="Devanagari *" name="nameDevanagari" error={fieldErrors.nameDevanagari}>
						<input id="nameDevanagari" name="nameDevanagari" class="input py-2 text-base font-devanagari"
							value={value.nameDevanagari} required />
					</FormField>
					<FormField label="Roman *" name="nameRoman" error={fieldErrors.nameRoman}>
						<input id="nameRoman" name="nameRoman" class="input py-2 text-base" value={value.nameRoman} required />
					</FormField>
					<FormField label="Telugu" name="nameTelugu" error={fieldErrors.nameTelugu}>
						<input id="nameTelugu" name="nameTelugu" class="input py-2 text-base" value={value.nameTelugu ?? ''} />
					</FormField>
					<FormField label="Kannada" name="nameKannada" error={fieldErrors.nameKannada}>
						<input id="nameKannada" name="nameKannada" class="input py-2 text-base" value={value.nameKannada ?? ''} />
					</FormField>
				</div>
			</div>

			<!-- Content — stretches to fill remaining space in col 1 -->
			<div class="flex-1 min-h-0 rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden flex flex-col">
				<div class="px-5 pt-4 pb-3 border-b border-slate-100 shrink-0">
					<span class="section-label">Content</span>
				</div>
				<div class="flex-1 p-4 flex flex-col gap-3 min-h-0">
					<FormField label="Description *" name="description" error={fieldErrors.description}>
						<textarea id="description" name="description"
							class="input resize-none leading-relaxed text-base py-2.5 w-full"
							style="min-height:120px;flex:1">{value.description}</textarea>
					</FormField>
					<FormField label="Deity" name="deity" error={fieldErrors.deity} hint="Drives hero image colour in app.">
						<input id="deity" name="deity" class="input py-2 text-base" value={value.deity ?? ''} />
					</FormField>
				</div>
			</div>

			<!-- Visibility — compact at bottom of col 1 -->
			<div class="shrink-0 rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden">
				<label class="flex items-center gap-3 px-5 py-4 cursor-pointer select-none">
					<input type="checkbox" name="isActive" bind:checked={isActive} class="sr-only" />
					<div class="relative shrink-0 w-12 h-[26px] rounded-full transition-all duration-300 cursor-pointer
						{isActive ? 'bg-emerald-500 shadow-emerald-200 shadow-md' : 'bg-slate-200'}">
						<span class="absolute top-0.5 w-5 h-5 rounded-full bg-white shadow-md transition-all duration-300
							{isActive ? 'left-[calc(100%-1.375rem)]' : 'left-0.5'}"></span>
					</div>
					<div>
						<p class="text-base font-semibold transition-colors {isActive ? 'text-emerald-700' : 'text-slate-500'}">
							{isActive ? 'Published' : 'Draft'}
						</p>
						<p class="text-sm mt-1 {isActive ? 'text-emerald-500' : 'text-slate-400'}">
							{isActive ? 'Live in Flutter app' : 'Hidden from users'}
						</p>
					</div>
				</label>
			</div>

		</div>

		<!-- ╔══ COL 2 ══════════════════════════════════════════════════════╗ -->
		<div class="flex flex-col gap-3 min-h-0">

			<!-- Preview Image -->
			<div class="rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden shrink-0">
				<div class="px-5 pt-4 pb-3 border-b border-slate-100 flex items-center gap-2">
					<Image size={14} class="text-amber-400" />
					<span class="section-label">Preview Image</span>
					<span class="ml-auto text-xs text-slate-400 normal-case tracking-normal">Selection list &amp; reminders</span>
				</div>
				<div class="p-4 space-y-3">
					<MediaUploadField
						category="mantra-preview"
						targetId="previewImageUrl"
						accept="image/*"
						buttonLabel={previewImageUrl ? 'Replace preview' : 'Upload preview'}
						currentUrl={previewImageUrl}
						onUrlChange={(url) => { previewImageUrl = url; }}
					/>
					<input type="hidden" id="previewImageUrl" name="previewImageUrl" value={previewImageUrl ?? ''} />
				</div>
			</div>

			<!-- Main Image -->
			<div class="rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden shrink-0">
				<div class="px-5 pt-4 pb-3 border-b border-slate-100 flex items-center gap-2">
					<Image size={14} class="text-slate-400" />
					<span class="section-label">Main Image</span>
					<span class="ml-auto text-xs text-slate-400 normal-case tracking-normal">Detail / chanting view</span>
				</div>
				<div class="p-4 space-y-3">
					<MediaUploadField
						category="mantra-image"
						targetId="imageUrl"
						accept="image/*"
						buttonLabel={imageUrl ? 'Replace image' : 'Upload image'}
						currentUrl={imageUrl}
						onUrlChange={(url) => { imageUrl = url; }}
					/>
					<input type="hidden" id="imageUrl" name="imageUrl" value={imageUrl ?? ''} />
				</div>
			</div>

		</div>

		<!-- ╔══ COL 3 ══════════════════════════════════════════════════════╗ -->
		<div class="flex flex-col gap-3 min-h-0">

			<!-- Tags -->
			<div class="rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden shrink-0">
				<div class="px-5 pt-4 pb-3 border-b border-slate-100">
					<span class="section-label">Tags</span>
					<span class="ml-2 text-xs text-slate-400 normal-case tracking-normal">Mantra-by-Need</span>
				</div>
				<div class="p-4">
					<TagMultiSelect name="tags" options={MANTRA_TAGS} bind:value={tags} />
				</div>
			</div>

			<!-- Practice Defaults -->
			<div class="rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden shrink-0">
				<div class="px-5 pt-4 pb-3 border-b border-slate-100">
					<span class="section-label">Practice Defaults</span>
				</div>
				<div class="p-4 grid grid-cols-2 gap-3">
					<FormField label="Rec. count" name="recommendedCount" hint="Per-day." error={fieldErrors.recommendedCount}>
						<input id="recommendedCount" name="recommendedCount" type="number" min="1"
							class="input py-2 text-base" value={value.recommendedCount ?? ''} />
					</FormField>
					<FormField label="Rec. days" name="recommendedDays" hint="Optional." error={fieldErrors.recommendedDays}>
						<input id="recommendedDays" name="recommendedDays" type="number" min="1"
							class="input py-2 text-base" value={value.recommendedDays ?? ''} />
					</FormField>
				</div>
			</div>

			<!-- Pronunciation Audio — stretches to fill -->
			<div class="flex-1 min-h-0 rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden flex flex-col">
				<div class="px-5 pt-4 pb-3 border-b border-slate-100 flex items-center gap-2 shrink-0">
					<Music size={14} class="text-slate-400" />
					<span class="section-label">Pronunciation Audio</span>
				</div>
				<div class="flex-1 min-h-0 p-4 flex flex-col gap-3">
					<FormField label="URL" name="pronunciationUrl" error={fieldErrors.pronunciationUrl}>
						<input id="pronunciationUrl" name="pronunciationUrl" type="url"
							class="input py-2 text-base" value={value.pronunciationUrl ?? ''} placeholder="https://…" />
					</FormField>
					<div class="flex-1 min-h-0">
						<MediaUploadField
							category="mantra-audio"
							targetId="pronunciationUrl"
							accept="audio/mpeg,audio/mp3,audio/wav,audio/x-wav"
							buttonLabel="Upload MP3 / WAV"
							currentUrl={value.pronunciationUrl}
						/>
					</div>
				</div>
			</div>

		</div>

	</div><!-- /3-col -->

	<!-- ══ MILESTONES ════════════════════════════════════════════════════════ -->
	<div class="shrink-0 rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden">
		<div class="px-5 pt-4 pb-3 border-b border-slate-100 flex items-center gap-3">
			<span class="flex-1 section-label">
				Program Milestones
				<span class="ml-2 normal-case font-normal text-slate-400 tracking-normal text-xs">
					Count presets + day options on Set Target screen
				</span>
			</span>
			<button type="button" onclick={addMilestone}
				class="flex items-center gap-2 rounded-xl border border-dashed border-slate-200 bg-slate-50
					px-4 py-1.5 text-sm font-semibold text-slate-500 hover:bg-slate-100 transition-colors">
				<Plus size={13} /> Add
			</button>
		</div>
		<div class="p-4">
			<div class="grid grid-cols-4 gap-3">
				{#each milestones as milestone, i (i)}
					<div class="relative rounded-2xl border border-slate-100 bg-slate-50 p-4 space-y-3
						hover:border-brand-200 hover:bg-brand-50/40 transition-colors">
						<button type="button" onclick={() => removeMilestone(i)}
							class="absolute top-2 right-2 rounded-lg p-1 text-slate-300 hover:text-red-400 transition-colors">
							<Trash2 size={12} />
						</button>
						<div>
							<p class="text-[11px] font-bold uppercase tracking-widest text-slate-400 mb-1.5">Count</p>
							<input type="number" min="1" value={milestone.count}
								oninput={(e) => updateMilestoneCount(i, parseInt((e.target as HTMLInputElement).value, 10))}
								class="input text-base font-bold w-full py-2" placeholder="108" />
						</div>
						<div>
							<p class="text-[11px] font-bold uppercase tracking-widest text-slate-400 mb-1.5">Days (comma-sep.)</p>
							<input type="text" value={milestone.dayOptions.join(', ')}
								oninput={(e) => updateDayOptions(i, (e.target as HTMLInputElement).value)}
								class="input text-sm font-mono w-full py-2" placeholder="1, 7, 21, 40" />
						</div>
						<div class="flex gap-1.5 flex-wrap">
							{#each milestone.dayOptions.slice(0, 5) as d, di}
								<span class="rounded-md px-2 py-0.5 text-xs font-bold
									{di === 0 ? 'bg-orange-100 text-orange-600 ring-1 ring-orange-200' : 'bg-slate-200 text-slate-500'}">
									{d}d
								</span>
							{/each}
						</div>
					</div>
				{/each}
				{#if milestones.length === 0}
					<div class="col-span-4 flex items-center justify-center py-8 text-slate-400 text-base">
						No milestones — click Add
					</div>
				{/if}
			</div>
			<input type="hidden" name="milestones" value={milestonesJson} />
		</div>
	</div>

	<!-- ══ ACTIONS ═══════════════════════════════════════════════════════════ -->
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

</form>
