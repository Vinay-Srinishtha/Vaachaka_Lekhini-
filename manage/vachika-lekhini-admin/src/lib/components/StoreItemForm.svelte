<script lang="ts">
	import { enhance } from '$app/forms';
	import FormField from './FormField.svelte';
	import { Save } from '@lucide/svelte';

	interface StoreValue {
		id?: string;
		slug: string;
		name: string;
		description: string;
		pointsCost: number;
		imageUrl: string | null;
		stock: number | null;
		isActive: boolean;
		sortOrder: number;
	}

	interface Props {
		value: StoreValue;
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
		<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
			<FormField label="Slug" name="slug" required error={fieldErrors.slug} hint="Stable id used by Flutter.">
				<input
					id="slug"
					name="slug"
					class="input"
					value={value.slug}
					readonly={isEdit}
					required
				/>
			</FormField>
			<FormField label="Name" name="name" required error={fieldErrors.name}>
				<input id="name" name="name" class="input" value={value.name} required />
			</FormField>
		</div>
		<FormField label="Description" name="description" required error={fieldErrors.description}>
			<textarea id="description" name="description" rows="3" class="input">{value.description}</textarea>
		</FormField>
	</section>

	<section class="card p-5 space-y-4">
		<div class="grid grid-cols-1 md:grid-cols-3 gap-4">
			<FormField label="Points cost" name="pointsCost" required error={fieldErrors.pointsCost}>
				<input id="pointsCost" name="pointsCost" type="number" min="0" class="input" value={value.pointsCost} required />
			</FormField>
			<FormField label="Stock" name="stock" hint="Leave empty for unlimited." error={fieldErrors.stock}>
				<input id="stock" name="stock" type="number" min="0" class="input" value={value.stock ?? ''} />
			</FormField>
			<FormField label="Sort order" name="sortOrder" error={fieldErrors.sortOrder}>
				<input id="sortOrder" name="sortOrder" type="number" class="input" value={value.sortOrder} />
			</FormField>
		</div>
		<FormField label="Image URL" name="imageUrl" error={fieldErrors.imageUrl}>
			<input id="imageUrl" name="imageUrl" type="url" class="input" value={value.imageUrl ?? ''} placeholder="https://…" />
		</FormField>
		<label class="flex items-center justify-between gap-4 mt-2 p-3 rounded-lg border cursor-pointer select-none
			{value.isActive ? 'border-green-200 bg-green-50' : 'border-gray-200 bg-gray-50'}">
			<div>
				<p class="text-sm font-semibold {value.isActive ? 'text-green-800' : 'text-gray-700'}">
					{value.isActive ? 'Live in app — users can see & buy this item' : 'Hidden — users cannot see this item'}
				</p>
				<p class="text-xs mt-0.5 {value.isActive ? 'text-green-600' : 'text-gray-500'}">
					Toggle to show or hide this item in the Flutter Store tab
				</p>
			</div>
			<input type="checkbox" name="isActive" checked={value.isActive} class="sr-only" />
			<div class="relative shrink-0 w-11 h-6 rounded-full transition-colors {value.isActive ? 'bg-green-500' : 'bg-gray-300'}">
				<span class="absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white shadow transition-transform {value.isActive ? 'translate-x-5' : 'translate-x-0'}"></span>
			</div>
		</label>
	</section>

	<div class="flex justify-end gap-2">
		<a href="/store" class="btn-secondary">Cancel</a>
		<button type="submit" class="btn-primary" disabled={submitting}>
			<Save size={16} />
			{submitting ? 'Saving…' : submitLabel}
		</button>
	</div>
</form>
