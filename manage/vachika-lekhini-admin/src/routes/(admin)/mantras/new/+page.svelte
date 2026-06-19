<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import Modal from '$lib/components/Modal.svelte';
	import MantraForm from '$lib/components/MantraForm.svelte';
	import { toasts } from '$lib/stores/toast';

	let { form } = $props();

	const v = $derived(form?.values ?? {});

	const value = $derived({
		slug: String(v.slug ?? ''),
		nameDevanagari: String(v.nameDevanagari ?? ''),
		nameRoman: String(v.nameRoman ?? ''),
		nameTelugu: v.nameTelugu ? String(v.nameTelugu) : null,
		nameKannada: v.nameKannada ? String(v.nameKannada) : null,
		description: String(v.description ?? ''),
		deity: v.deity ? String(v.deity) : null,
		tags: (form?.tags ?? []) as string[],
		recommendedCount: v.recommendedCount ? Number(v.recommendedCount) : null,
		recommendedDays: v.recommendedDays ? Number(v.recommendedDays) : null,
		pronunciationUrl: v.pronunciationUrl ? String(v.pronunciationUrl) : null,
		previewImageUrl: v.previewImageUrl ? String(v.previewImageUrl) : null,
		imageUrl: v.imageUrl ? String(v.imageUrl) : null,
		isActive: v.isActive !== undefined ? v.isActive === 'on' || v.isActive === 'true' : true,
		sortOrder: v.sortOrder ? Number(v.sortOrder) : 0,
		milestones: null,
		shareImageUrl: null,
		shareText: null
	});

	function close() {
		const params = new URLSearchParams(page.url.searchParams);
		const qs = params.toString();
		goto(`/mantras${qs ? '?' + qs : ''}`, { keepFocus: true, noScroll: true });
	}

	function handleSuccess() {
		toasts.show('Mantra created successfully');
		close();
	}
</script>

<Modal open title="New mantra" subtitle="Add a mantra to the catalog served to Flutter" size="3xl" formId="mantra-form" saveLabel="Create mantra" onClose={close}>
	<MantraForm {value} fieldErrors={form?.fieldErrors ?? {}} submitLabel="Create mantra" onSuccess={handleSuccess} inModal />
</Modal>
