<script lang="ts">
	import { enhance } from '$app/forms';
	import FormField from './FormField.svelte';
	import MediaUploadField from './MediaUploadField.svelte';
	import TagMultiSelect from './TagMultiSelect.svelte';
	import { MANTRA_TAGS } from '$lib/constants';
	import { Save, Plus, Trash2 } from '@lucide/svelte';

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

	let submitting = $state(false);
</script>

<form
	method="POST"
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
		<div class="mb-5 text-sm rounded-xl bg-red-50 text-red-700 border border-red-200 px-4 py-3">
			{generalError}
		</div>
	{/if}

	<div class="grid grid-cols-1 lg:grid-cols-2 gap-4">

		<!-- ══ LEFT COLUMN ══════════════════════════════════════════════════ -->
		<div class="flex flex-col gap-4">

			<!-- Identity -->
			<div class="rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden">
				<div class="px-5 pt-4 pb-3 flex items-center gap-2 border-b border-slate-100">
					<span class="flex-1 section-label">Identity</span>
				</div>
				<div class="p-4 grid grid-cols-2 gap-3">
					<div class="col-span-2 sm:col-span-1">
						<FormField label="Slug" name="slug" required error={fieldErrors.slug}
							hint={isEdit ? 'Cannot change after release.' : 'Lowercase letters, digits, underscores.'}>
							<input id="slug" name="slug" class="input" value={value.slug}
								readonly={isEdit} required autocomplete="off"
								class:opacity-60={isEdit} class:cursor-not-allowed={isEdit} />
						</FormField>
					</div>
					<div class="col-span-2 sm:col-span-1">
						<FormField label="Sort order" name="sortOrder" hint="Lower = first." error={fieldErrors.sortOrder}>
							<input id="sortOrder" name="sortOrder" type="number" class="input" value={value.sortOrder} />
						</FormField>
					</div>
				</div>
			</div>

			<!-- Names -->
			<div class="rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden">
				<div class="px-5 pt-4 pb-3 border-b border-slate-100">
					<span class="section-label">Names</span>
				</div>
				<div class="p-4 grid grid-cols-2 gap-3">
					<FormField label="Devanagari *" name="nameDevanagari" error={fieldErrors.nameDevanagari}>
						<input id="nameDevanagari" name="nameDevanagari" class="input font-devanagari"
							value={value.nameDevanagari} required />
					</FormField>
					<FormField label="Roman *" name="nameRoman" error={fieldErrors.nameRoman}>
						<input id="nameRoman" name="nameRoman" class="input" value={value.nameRoman} required />
					</FormField>
					<FormField label="Telugu" name="nameTelugu" error={fieldErrors.nameTelugu}>
						<input id="nameTelugu" name="nameTelugu" class="input" value={value.nameTelugu ?? ''} />
					</FormField>
					<FormField label="Kannada" name="nameKannada" error={fieldErrors.nameKannada}>
						<input id="nameKannada" name="nameKannada" class="input" value={value.nameKannada ?? ''} />
					</FormField>
				</div>
			</div>

			<!-- Visibility -->
			<div class="rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden">
				<div class="px-5 pt-4 pb-3 border-b border-slate-100">
					<span class="section-label">Visibility</span>
				</div>
				<label class="flex items-center justify-between gap-4 px-5 py-4 cursor-pointer select-none group">
					<div>
						<p class="text-sm font-semibold transition-colors {isActive ? 'text-emerald-700' : 'text-slate-500'}">
							{isActive ? 'Published — live in Flutter app' : 'Draft — hidden from users'}
						</p>
						<p class="text-xs mt-0.5 {isActive ? 'text-emerald-500' : 'text-slate-400'}">
							{isActive ? 'Users can see and chant this mantra' : 'Tap to publish this mantra'}
						</p>
					</div>
					<input type="checkbox" name="isActive" bind:checked={isActive} class="sr-only" />
					<div class="relative shrink-0 w-12 h-6 rounded-full transition-all duration-300 cursor-pointer
							{isActive ? 'bg-emerald-500 shadow-emerald-200 shadow-md' : 'bg-slate-200'}">
						<span class="absolute top-0.5 w-5 h-5 rounded-full bg-white shadow-md transition-all duration-300
							{isActive ? 'left-[calc(100%-1.375rem)]' : 'left-0.5'}"></span>
					</div>
				</label>
			</div>

		</div><!-- end left col -->

		<!-- ══ RIGHT COLUMN ═════════════════════════════════════════════════ -->
		<div class="flex flex-col gap-4">

			<!-- Content -->
			<div class="rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden">
				<div class="px-5 pt-4 pb-3 border-b border-slate-100">
					<span class="section-label">Content</span>
				</div>
				<div class="p-4 space-y-3">
					<FormField label="Description *" name="description" error={fieldErrors.description}>
						<textarea id="description" name="description" rows="3"
							class="input resize-none leading-relaxed">{value.description}</textarea>
					</FormField>
					<FormField label="Deity" name="deity" error={fieldErrors.deity}
						hint="Drives hero image colour in app.">
						<input id="deity" name="deity" class="input" value={value.deity ?? ''} />
					</FormField>
					<FormField label="Tags" hint="Mantra-by-Need recommender." error={fieldErrors.tags}>
						<TagMultiSelect name="tags" options={MANTRA_TAGS} bind:value={tags} />
					</FormField>
				</div>
			</div>

			<!-- Practice Defaults -->
			<div class="rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden">
				<div class="px-5 pt-4 pb-3 border-b border-slate-100">
					<span class="section-label">Practice Defaults</span>
				</div>
				<div class="p-4 space-y-3">
					<div class="grid grid-cols-2 gap-3">
						<FormField label="Recommended count" name="recommendedCount"
							hint="Per-day target." error={fieldErrors.recommendedCount}>
							<input id="recommendedCount" name="recommendedCount" type="number" min="1"
								class="input" value={value.recommendedCount ?? ''} />
						</FormField>
						<FormField label="Recommended days" name="recommendedDays"
							hint="Optional." error={fieldErrors.recommendedDays}>
							<input id="recommendedDays" name="recommendedDays" type="number" min="1"
								class="input" value={value.recommendedDays ?? ''} />
						</FormField>
					</div>
					<FormField label="Pronunciation URL" name="pronunciationUrl"
						hint="Audio asset for detail screen." error={fieldErrors.pronunciationUrl}>
						<input id="pronunciationUrl" name="pronunciationUrl" type="url"
							class="input" value={value.pronunciationUrl ?? ''} placeholder="https://…" />
						<MediaUploadField
							category="mantra-audio"
							targetId="pronunciationUrl"
							accept="audio/mpeg,audio/mp3,audio/wav"
							buttonLabel="Upload MP3"
							currentUrl={value.pronunciationUrl}
						/>
					</FormField>
				</div>
			</div>

		</div><!-- end right col -->

		<!-- ══ FULL-WIDTH: Milestones ════════════════════════════════════════ -->
		<div class="lg:col-span-2 rounded-2xl border border-slate-100 bg-white shadow-sm overflow-hidden">
			<div class="px-5 pt-4 pb-3 border-b border-slate-100 flex items-center gap-3">
				<span class="flex-1 section-label">
					Program Milestones
					<span class="ml-2 normal-case font-normal text-slate-400 tracking-normal">
						Count presets + day options shown on Set Target screen
					</span>
				</span>
				<button type="button" onclick={addMilestone}
					class="flex items-center gap-1.5 rounded-lg border border-dashed border-slate-200 bg-slate-50
						px-3 py-1 text-[11px] font-semibold text-slate-500 hover:bg-slate-100 transition-colors">
					<Plus size={12} /> Add
				</button>
			</div>
			<div class="p-4">
				<div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
					{#each milestones as milestone, i (i)}
						<div class="relative rounded-xl border border-slate-100 bg-slate-50 p-3 space-y-2.5
							hover:border-brand-200 hover:bg-brand-50/40 transition-colors">
							<button type="button" onclick={() => removeMilestone(i)}
								class="absolute top-2 right-2 rounded-md p-0.5 text-slate-300 hover:text-red-400 transition-colors">
								<Trash2 size={11} />
							</button>
							<div>
								<p class="text-[9px] font-bold uppercase tracking-widest text-slate-400 mb-1">Count</p>
								<input type="number" min="1" value={milestone.count}
									oninput={(e) => updateMilestoneCount(i, parseInt((e.target as HTMLInputElement).value, 10))}
									class="input text-sm font-bold w-full py-1.5" placeholder="108" />
							</div>
							<div>
								<p class="text-[9px] font-bold uppercase tracking-widest text-slate-400 mb-1">Days (comma-sep.)</p>
								<input type="text" value={milestone.dayOptions.join(', ')}
									oninput={(e) => updateDayOptions(i, (e.target as HTMLInputElement).value)}
									class="input text-xs font-mono w-full py-1.5" placeholder="1, 7, 21, 40" />
							</div>
							<div class="flex gap-1 flex-wrap">
								{#each milestone.dayOptions.slice(0, 5) as d, di}
									<span class="rounded px-1.5 py-0.5 text-[10px] font-bold
										{di === 0
											? 'bg-orange-100 text-orange-600 ring-1 ring-orange-200'
											: 'bg-slate-200 text-slate-500'}">
										{d}d
									</span>
								{/each}
							</div>
						</div>
					{/each}
					{#if milestones.length === 0}
						<div class="col-span-full flex flex-col items-center justify-center py-8 text-slate-400">
							<p class="text-sm">No milestones yet</p>
							<p class="text-xs mt-0.5">Click Add to create count presets</p>
						</div>
					{/if}
				</div>
				<input type="hidden" name="milestones" value={milestonesJson} />
			</div>
		</div>

		<!-- ══ FULL-WIDTH: Actions ════════════════════════════════════════════ -->
		<div class="lg:col-span-2 flex items-center justify-between pt-1">
			<a href="/mantras" class="btn-secondary">
				Cancel
			</a>
			<button type="submit"
				class="flex items-center gap-2 px-5 py-2.5 rounded-xl font-semibold text-sm
					bg-brand-600 text-white shadow-md shadow-brand-200
					hover:bg-brand-700 hover:shadow-lg hover:shadow-brand-200
					disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-150"
				disabled={submitting}>
				<Save size={14} />
				{submitting ? 'Saving…' : submitLabel}
			</button>
		</div>

	</div>
</form>
