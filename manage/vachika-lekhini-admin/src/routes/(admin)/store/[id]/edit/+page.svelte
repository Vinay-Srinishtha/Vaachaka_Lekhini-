<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import Modal from '$lib/components/Modal.svelte';
	import StoreItemForm from '$lib/components/StoreItemForm.svelte';

	let { data, form } = $props();

	const it = $derived(data.item);
	const v = $derived(form?.values ?? {});

	const value = $derived({
		id: it.id,
		slug: it.slug,
		name: String(v.name ?? it.name),
		description: String(v.description ?? it.description),
		pointsCost: v.pointsCost ? Number(v.pointsCost) : it.pointsCost,
		imageUrl: v.imageUrl !== undefined ? (v.imageUrl ? String(v.imageUrl) : null) : it.imageUrl,
		stock: v.stock !== undefined ? (v.stock ? Number(v.stock) : null) : it.stock,
		isActive: v.isActive !== undefined ? v.isActive === 'on' || v.isActive === 'true' : it.isActive,
		sortOrder: v.sortOrder ? Number(v.sortOrder) : it.sortOrder
	});

	function close() {
		const params = new URLSearchParams(page.url.searchParams);
		const qs = params.toString();
		goto(`/store${qs ? '?' + qs : ''}`, { keepFocus: true, noScroll: true });
	}
</script>

<Modal open title={`Edit · ${it.name}`} subtitle={`Slug · ${it.slug}`} size="lg" onClose={close}>
	<StoreItemForm {value} fieldErrors={form?.fieldErrors ?? {}} submitLabel="Save changes" isEdit />
</Modal>
