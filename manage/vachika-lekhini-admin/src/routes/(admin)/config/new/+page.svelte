<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import Modal from '$lib/components/Modal.svelte';
	import FeatureFlagForm from '$lib/components/FeatureFlagForm.svelte';
	import type { FlagType } from '$lib/constants';
	import { toasts } from '$lib/stores/toast';

	let { form } = $props();

	const v = $derived(form?.values ?? {});

	const value = $derived({
		key: String(v.key ?? ''),
		valueType: (String(v.valueType ?? 'bool') as FlagType),
		rawValue: String(v.rawValue ?? 'false'),
		description: v.description ? String(v.description) : null
	});

	function close() {
		const params = new URLSearchParams(page.url.searchParams);
		const qs = params.toString();
		goto(`/config${qs ? '?' + qs : ''}`, { keepFocus: true, noScroll: true });
	}

	function handleSuccess() {
		toasts.show('Flag created');
		close();
	}
</script>

<Modal open title="New flag" size="lg" onClose={close}>
	<FeatureFlagForm {value} fieldErrors={form?.fieldErrors ?? {}} submitLabel="Create flag" onSuccess={handleSuccess} />
</Modal>
