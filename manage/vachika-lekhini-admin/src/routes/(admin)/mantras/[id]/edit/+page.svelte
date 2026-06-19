<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import Modal from '$lib/components/Modal.svelte';
	import MantraForm from '$lib/components/MantraForm.svelte';
	import { toasts } from '$lib/stores/toast';

	let { data, form } = $props();

	const m = $derived(data.mantra);
	const v = $derived(form?.values ?? {});
	const tags = $derived<string[]>(form?.tags ?? (m.tags as string[]));

	const value = $derived({
		id: m.id,
		slug: m.slug,
		nameDevanagari: String(v.nameDevanagari ?? m.nameDevanagari),
		nameRoman: String(v.nameRoman ?? m.nameRoman),
		nameTelugu:
			v.nameTelugu !== undefined ? (v.nameTelugu ? String(v.nameTelugu) : null) : m.nameTelugu,
		nameKannada:
			v.nameKannada !== undefined ? (v.nameKannada ? String(v.nameKannada) : null) : m.nameKannada,
		description: String(v.description ?? m.description),
		deity: v.deity !== undefined ? (v.deity ? String(v.deity) : null) : m.deity,
		tags,
		recommendedCount: v.recommendedCount ? Number(v.recommendedCount) : m.recommendedCount,
		recommendedDays: v.recommendedDays ? Number(v.recommendedDays) : m.recommendedDays,
		pronunciationUrl:
			v.pronunciationUrl !== undefined
				? v.pronunciationUrl
					? String(v.pronunciationUrl)
					: null
				: m.pronunciationUrl,
		previewImageUrl:
			v.previewImageUrl !== undefined
				? v.previewImageUrl
					? String(v.previewImageUrl)
					: null
				: (m as any).previewImageUrl ?? null,
		imageUrl:
			v.imageUrl !== undefined
				? v.imageUrl
					? String(v.imageUrl)
					: null
				: (m as any).imageUrl ?? null,
		isActive: v.isActive !== undefined ? v.isActive === 'on' || v.isActive === 'true' : m.isActive,
		sortOrder: v.sortOrder ? Number(v.sortOrder) : m.sortOrder,
		milestones: (m as any).milestones ?? null,
		shareImageUrl: (m as any).shareImageUrl ?? null,
		shareText: (m as any).shareText ?? null
	});

	function close() {
		const params = new URLSearchParams(page.url.searchParams);
		const qs = params.toString();
		goto(`/mantras${qs ? '?' + qs : ''}`, { keepFocus: true, noScroll: true });
	}

	function handleSuccess() {
		toasts.show('Mantra updated');
		close();
	}
</script>

<Modal open title={`Edit · ${m.nameRoman}`} subtitle={`Slug · ${m.slug}`} size="3xl" formId="mantra-form" saveLabel="Save changes" onClose={close}>
	<MantraForm {value} fieldErrors={form?.fieldErrors ?? {}} submitLabel="Save changes" isEdit onSuccess={handleSuccess} inModal />
</Modal>
