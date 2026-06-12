<script lang="ts">
	import { enhance } from '$app/forms';
	import FormField from './FormField.svelte';
	import { FLAG_TYPES, type FlagType } from '$lib/constants';
	import { Save } from '@lucide/svelte';

	interface FlagValue {
		key: string;
		valueType: FlagType;
		rawValue: string;
		description: string | null;
	}

	interface Props {
		value: FlagValue;
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

	// Track type + raw value locally so the input control swaps as type changes.
	let valueType = $state<FlagType>(value.valueType);
	let rawValue = $state<string>(value.rawValue);
	let submitting = $state(false);

	// Reset raw value to a sensible default when type changes during create.
	function onTypeChange(e: Event) {
		const next = (e.target as HTMLSelectElement).value as FlagType;
		valueType = next;
		if (!isEdit) {
			rawValue =
				next === 'bool' ? 'false' : next === 'int' ? '0' : next === 'json' ? '{}' : '';
		}
	}
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
			<FormField
				label="Key"
				name="key"
				required
				error={fieldErrors.key}
				hint="e.g. feature.voice_counting · dot-separated namespaces allowed"
			>
				<input
					id="key"
					name="key"
					class="input"
					value={value.key}
					readonly={isEdit}
					required
					placeholder="feature.example"
				/>
			</FormField>
			<FormField label="Value type" name="valueType" required error={fieldErrors.valueType}>
				<select id="valueType" name="valueType" class="input" value={valueType} onchange={onTypeChange}>
					{#each FLAG_TYPES as t}
						<option value={t}>{t}</option>
					{/each}
				</select>
			</FormField>
		</div>

		<FormField
			label="Value"
			name="rawValue"
			required
			error={fieldErrors.rawValue}
			hint={valueType === 'json'
				? 'Any valid JSON (string, number, object, array, …)'
				: valueType === 'bool'
					? 'true or false'
					: valueType === 'int'
						? 'Integer.'
						: 'Plain text.'}
		>
			{#if valueType === 'bool'}
				<select id="rawValue" name="rawValue" class="input" value={rawValue} onchange={(e) => (rawValue = (e.target as HTMLSelectElement).value)}>
					<option value="true">true</option>
					<option value="false">false</option>
				</select>
			{:else if valueType === 'json'}
				<textarea
					id="rawValue"
					name="rawValue"
					rows="6"
					class="input font-mono text-xs"
					oninput={(e) => (rawValue = (e.target as HTMLTextAreaElement).value)}>{rawValue}</textarea>
			{:else}
				<input
					id="rawValue"
					name="rawValue"
					type={valueType === 'int' ? 'number' : 'text'}
					step={valueType === 'int' ? '1' : undefined}
					class="input"
					value={rawValue}
					oninput={(e) => (rawValue = (e.target as HTMLInputElement).value)}
				/>
			{/if}
		</FormField>

		<FormField label="Description" name="description" error={fieldErrors.description}>
			<textarea id="description" name="description" rows="2" class="input">{value.description ?? ''}</textarea>
		</FormField>
	</section>

	<div class="flex justify-end gap-2">
		<a href="/config" class="btn-secondary">Cancel</a>
		<button type="submit" class="btn-primary" disabled={submitting}>
			<Save size={16} />
			{submitting ? 'Saving…' : submitLabel}
		</button>
	</div>
</form>
