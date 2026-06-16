<script lang="ts">
	import { enhance } from '$app/forms';
	import FormField from './FormField.svelte';
	import MediaUploadField from './MediaUploadField.svelte';
	import TagMultiSelect from './TagMultiSelect.svelte';
	import { MANTRA_TAGS, THUMB_PALETTES } from '$lib/constants';
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
		thumbPalette: string;
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

	// Local working copies for two-way binding (tags need mutation).
	// Reset whenever the upstream `value` changes (modal reopens with new record).
	let tags = $state<string[]>([]);
	$effect.pre(() => {
		tags = [...value.tags];
	});

	// Milestones editor state — seed from value or use defaults.
	let milestones = $state<MantraMilestone[]>([]);
	$effect.pre(() => {
		milestones = (value.milestones && value.milestones.length > 0)
			? value.milestones.map(m => ({ count: m.count, dayOptions: [...m.dayOptions] }))
			: DEFAULT_MILESTONES.map(m => ({ count: m.count, dayOptions: [...m.dayOptions] }));
	});

	const milestonesJson = $derived(JSON.stringify(milestones));

	function addMilestone() {
		milestones = [...milestones, { count: 0, dayOptions: [1] }];
	}

	function removeMilestone(i: number) {
		milestones = milestones.filter((_, idx) => idx !== i);
	}

	function updateMilestoneCount(i: number, val: number) {
		milestones = milestones.map((m, idx) => idx === i ? { ...m, count: val } : m);
	}

	function updateDayOptions(i: number, raw: string) {
		const days = raw.split(',')
			.map(s => parseInt(s.trim(), 10))
			.filter(n => !isNaN(n) && n > 0);
		milestones = milestones.map((m, idx) => idx === i ? { ...m, dayOptions: days } : m);
	}

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
	class="space-y-6"
>
	{#if generalError}
		<div class="text-sm rounded-lg bg-red-50 text-red-700 border border-red-200 px-3 py-2">
			{generalError}
		</div>
	{/if}

	<section class="card p-5 space-y-4">
		<h2 class="text-sm font-semibold text-gray-900 uppercase tracking-wide">Identity</h2>
		<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
			<FormField label="Slug" name="slug" required error={fieldErrors.slug} hint="Stable id used by Flutter (e.g. sri_rama). Don't change after release.">
				<input
					id="slug"
					name="slug"
					class="input"
					value={value.slug}
					readonly={isEdit}
					required
					autocomplete="off"
				/>
			</FormField>
			<FormField label="Sort order" name="sortOrder" hint="Lower numbers appear first." error={fieldErrors.sortOrder}>
				<input id="sortOrder" name="sortOrder" type="number" class="input" value={value.sortOrder} />
			</FormField>
		</div>
	</section>

	<section class="card p-5 space-y-4">
		<h2 class="text-sm font-semibold text-gray-900 uppercase tracking-wide">Names</h2>
		<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
			<FormField label="Devanagari" name="nameDevanagari" required error={fieldErrors.nameDevanagari}>
				<input id="nameDevanagari" name="nameDevanagari" class="input" value={value.nameDevanagari} required />
			</FormField>
			<FormField label="Roman" name="nameRoman" required error={fieldErrors.nameRoman}>
				<input id="nameRoman" name="nameRoman" class="input" value={value.nameRoman} required />
			</FormField>
			<FormField label="Telugu" name="nameTelugu" error={fieldErrors.nameTelugu}>
				<input id="nameTelugu" name="nameTelugu" class="input" value={value.nameTelugu ?? ''} />
			</FormField>
			<FormField label="Kannada" name="nameKannada" error={fieldErrors.nameKannada}>
				<input id="nameKannada" name="nameKannada" class="input" value={value.nameKannada ?? ''} />
			</FormField>
		</div>
	</section>

	<section class="card p-5 space-y-4">
		<h2 class="text-sm font-semibold text-gray-900 uppercase tracking-wide">Content</h2>
		<FormField label="Description" name="description" required error={fieldErrors.description}>
			<textarea id="description" name="description" rows="5" class="input">{value.description}</textarea>
		</FormField>
		<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
			<FormField label="Deity" name="deity" error={fieldErrors.deity} hint="Optional. Drives the hero image colour in app.">
				<input id="deity" name="deity" class="input" value={value.deity ?? ''} />
			</FormField>
			<FormField label="Thumbnail palette" name="thumbPalette" required error={fieldErrors.thumbPalette}>
				<select id="thumbPalette" name="thumbPalette" class="input" value={value.thumbPalette}>
					{#each THUMB_PALETTES as p}
						<option value={p}>{p}</option>
					{/each}
				</select>
			</FormField>
		</div>
		<FormField label="Tags" hint="Used by the Mantra-by-Need recommender." error={fieldErrors.tags}>
			<TagMultiSelect name="tags" options={MANTRA_TAGS} bind:value={tags} />
		</FormField>
	</section>

	<section class="card p-5 space-y-4">
		<h2 class="text-sm font-semibold text-gray-900 uppercase tracking-wide">Practice defaults</h2>
		<div class="grid grid-cols-1 md:grid-cols-3 gap-4">
			<FormField label="Recommended count" name="recommendedCount" hint="Per-day target shown on mantra detail." error={fieldErrors.recommendedCount}>
				<input id="recommendedCount" name="recommendedCount" type="number" min="1" class="input" value={value.recommendedCount ?? ''} />
			</FormField>
			<FormField label="Recommended days" name="recommendedDays" hint="Days of practice. Optional." error={fieldErrors.recommendedDays}>
				<input id="recommendedDays" name="recommendedDays" type="number" min="1" class="input" value={value.recommendedDays ?? ''} />
			</FormField>
			<FormField label="Pronunciation URL" name="pronunciationUrl" hint="Optional audio asset for the detail screen." error={fieldErrors.pronunciationUrl}>
				<input id="pronunciationUrl" name="pronunciationUrl" type="url" class="input" value={value.pronunciationUrl ?? ''} placeholder="https://…" />
				<MediaUploadField
					category="mantra-audio"
					targetId="pronunciationUrl"
					accept="audio/mpeg,audio/mp3,audio/wav"
					buttonLabel="Upload MP3"
					currentUrl={value.pronunciationUrl}
				/>
			</FormField>
		</div>
		<label class="flex items-center justify-between gap-4 mt-2 p-3 rounded-lg border cursor-pointer select-none
			{value.isActive ? 'border-green-200 bg-green-50' : 'border-gray-200 bg-gray-50'}">
			<div>
				<p class="text-sm font-semibold {value.isActive ? 'text-green-800' : 'text-gray-700'}">
					{value.isActive ? 'Published — mantra is live for all users' : 'Unpublished — mantra is hidden from users'}
				</p>
				<p class="text-xs mt-0.5 {value.isActive ? 'text-green-600' : 'text-gray-500'}">
					Toggle to show or hide this mantra in the Flutter app
				</p>
			</div>
			<input type="checkbox" name="isActive" checked={value.isActive} class="sr-only" />
			<div class="relative shrink-0 w-11 h-6 rounded-full transition-colors {value.isActive ? 'bg-green-500' : 'bg-gray-300'}">
				<span class="absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white shadow transition-transform {value.isActive ? 'translate-x-5' : 'translate-x-0'}"></span>
			</div>
		</label>
	</section>

	<!-- ── Program Milestones ─────────────────────────────────────────────────── -->
	<section class="card p-5 space-y-4">
		<div class="flex items-center justify-between">
			<div>
				<h2 class="text-sm font-semibold text-gray-900 uppercase tracking-wide">Program Milestones</h2>
				<p class="text-xs text-gray-500 mt-0.5">Count presets and day options shown on the Set Target screen in the Flutter app.</p>
			</div>
			<button type="button" onclick={addMilestone}
				class="flex items-center gap-1.5 rounded-lg border border-dashed border-indigo-300 bg-indigo-50
					px-3 py-1.5 text-xs font-semibold text-indigo-700 hover:bg-indigo-100 transition-colors">
				<Plus size={13} /> Add Milestone
			</button>
		</div>

		<div class="space-y-3">
			{#each milestones as milestone, i (i)}
				<div class="flex items-start gap-3 rounded-xl border border-gray-200 bg-gray-50 p-3">
					<!-- Count -->
					<div class="w-28 shrink-0">
						<label class="block text-[10px] font-semibold uppercase tracking-wide text-gray-500 mb-1">Count</label>
						<input
							type="number"
							min="1"
							value={milestone.count}
							oninput={(e) => updateMilestoneCount(i, parseInt((e.target as HTMLInputElement).value, 10))}
							class="input w-full text-sm font-semibold"
							placeholder="108"
						/>
					</div>

					<!-- Day options -->
					<div class="flex-1">
						<label class="block text-[10px] font-semibold uppercase tracking-wide text-gray-500 mb-1">
							Day options <span class="font-normal normal-case">(comma-separated, first is auto-selected)</span>
						</label>
						<input
							type="text"
							value={milestone.dayOptions.join(', ')}
							oninput={(e) => updateDayOptions(i, (e.target as HTMLInputElement).value)}
							class="input w-full text-sm font-mono"
							placeholder="1, 7, 21, 40"
						/>
					</div>

					<!-- Preview pills -->
					<div class="shrink-0 pt-5 flex gap-1 flex-wrap max-w-[140px]">
						{#each milestone.dayOptions.slice(0, 4) as d, di}
							<span class="rounded-md px-1.5 py-0.5 text-[10px] font-semibold
								{di === 0 ? 'bg-orange-100 text-orange-700 ring-1 ring-orange-300' : 'bg-gray-200 text-gray-600'}">
								{d}d
							</span>
						{/each}
					</div>

					<!-- Remove -->
					<button type="button" onclick={() => removeMilestone(i)}
						class="mt-5 rounded-lg p-1.5 text-gray-400 hover:bg-red-50 hover:text-red-500 transition-colors shrink-0"
						title="Remove milestone">
						<Trash2 size={14} />
					</button>
				</div>
			{/each}

			{#if milestones.length === 0}
				<p class="text-sm text-gray-400 text-center py-4">No milestones — add one above.</p>
			{/if}
		</div>

		<!-- Hidden input carries the JSON to the server -->
		<input type="hidden" name="milestones" value={milestonesJson} />
	</section>

	<div class="flex justify-end gap-2">
		<a href="/mantras" class="btn-secondary">Cancel</a>
		<button type="submit" class="btn-primary" disabled={submitting}>
			<Save size={16} />
			{submitting ? 'Saving…' : submitLabel}
		</button>
	</div>
</form>
