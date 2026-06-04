<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import Modal from '$lib/components/Modal.svelte';
	import StoreItemForm from '$lib/components/StoreItemForm.svelte';

	let { form } = $props();

	const v = $derived(form?.values ?? {});

	const value = $derived({
		slug: String(v.slug ?? ''),
		name: String(v.name ?? ''),
		description: String(v.description ?? ''),
		pointsCost: v.pointsCost ? Number(v.pointsCost) : 0,
		imageUrl: v.imageUrl ? String(v.imageUrl) : null,
		stock: v.stock ? Number(v.stock) : null,
		isActive: v.isActive !== undefined ? v.isActive === 'on' || v.isActive === 'true' : true,
		sortOrder: v.sortOrder ? Number(v.sortOrder) : 0
	});

	function close() {
		const params = new URLSearchParams(page.url.searchParams);
		const qs = params.toString();
		goto(`/store${qs ? '?' + qs : ''}`, { keepFocus: true, noScroll: true });
	}
</script>

<Modal open title="New store item" size="lg" onClose={close}>
	<StoreItemForm {value} fieldErrors={form?.fieldErrors ?? {}} submitLabel="Create item" />
</Modal>
