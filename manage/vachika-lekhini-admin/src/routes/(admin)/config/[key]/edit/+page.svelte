<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import Modal from '$lib/components/Modal.svelte';
	import FeatureFlagForm from '$lib/components/FeatureFlagForm.svelte';
	import { encodeFlagValue, type FlagType } from '$lib/constants';
	import { toasts } from '$lib/stores/toast';

	let { data, form } = $props();

	const f = $derived(data.flag);
	const v = $derived(form?.values ?? {});

	// Note: encodeFlagValue is server-pure (no Prisma import) — safe in client.
	const value = $derived({
		key: f.key,
		valueType: (String(v.valueType ?? f.valueType) as FlagType),
		rawValue:
			v.rawValue !== undefined
				? String(v.rawValue)
				: encodeFlagValue(f.valueType as FlagType, f.value),
		description:
			v.description !== undefined ? (v.description ? String(v.description) : null) : f.description
	});

	function close() {
		const params = new URLSearchParams(page.url.searchParams);
		const qs = params.toString();
		goto(`/config${qs ? '?' + qs : ''}`, { keepFocus: true, noScroll: true });
	}

	function handleSuccess() {
		toasts.show('Flag updated');
		close();
	}
</script>

<Modal open title={`Edit · ${f.key}`} size="md" onClose={close}>
	<FeatureFlagForm {value} fieldErrors={form?.fieldErrors ?? {}} submitLabel="Save changes" isEdit onSuccess={handleSuccess} />
</Modal>
