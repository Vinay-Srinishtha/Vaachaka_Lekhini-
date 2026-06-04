<script lang="ts">
	import { enhance } from '$app/forms';
	import FormField from './FormField.svelte';
	import TagMultiSelect from './TagMultiSelect.svelte';
	import { MANTRA_TAGS, THUMB_PALETTES } from '$lib/constants';
	import { Save } from '@lucide/svelte';

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
		isActive: boolean;
		sortOrder: number;
	}

	interface Props {
		value: MantraValue;
		fieldErrors?: Record<string, string>;
		generalError?: string | null;
		submitLabel?: string;
		isEdit?: boolean;
	}

	let {
		value,
		fieldErrors = {},
		generalError = null,
		submitLabel = 'Save',
		isEdit = false
	}: Props = $props();

	// Local working copies for two-way binding (tags need mutation).
	// Reset whenever the upstream `value` changes (modal reopens with new record).
	let tags = $state<string[]>([]);
	$effect.pre(() => {
		tags = [...value.tags];
	});
	let submitting = $state(false);
</script>

<form
	method="POST"
	use:enhance={() => {
		submitting = true;
		return async ({ update }) => {
			await update();
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
			</FormField>
		</div>
		<label class="inline-flex items-center gap-2 mt-2">
			<input type="checkbox" name="isActive" checked={value.isActive} class="rounded border-gray-300 text-brand-600 focus:ring-brand-500" />
			<span class="text-sm text-gray-700">Visible in Flutter app</span>
		</label>
	</section>

	<div class="flex justify-end gap-2">
		<a href="/mantras" class="btn-secondary">Cancel</a>
		<button type="submit" class="btn-primary" disabled={submitting}>
			<Save size={16} />
			{submitting ? 'Saving…' : submitLabel}
		</button>
	</div>
</form>
