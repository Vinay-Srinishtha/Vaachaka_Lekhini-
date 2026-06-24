<script lang="ts">
	import { PlusCircle, Pencil, Trash2, CheckCircle2, CircleDashed } from '@lucide/svelte';

	let { data } = $props();

	type TncItem = {
		id: string;
		version: string;
		title: string;
		content: string;
		isActive: boolean;
		effectiveAt: string;
		createdAt: string;
		_count: { acceptances: number };
	};

	let list = $state<TncItem[]>(data.list as TncItem[]);

	// Modal state
	let showModal = $state(false);
	let editingId = $state<string | null>(null);
	let saving = $state(false);
	let deleting = $state<string | null>(null);
	let activating = $state<string | null>(null);
	let errorMsg = $state<string | null>(null);

	// Form fields
	let fVersion = $state('');
	let fTitle = $state('');
	let fContent = $state('');
	let fEffectiveAt = $state('');

	function openCreate() {
		editingId = null;
		fVersion = '';
		fTitle = '';
		fContent = '';
		fEffectiveAt = '';
		errorMsg = null;
		showModal = true;
	}

	function openEdit(item: TncItem) {
		editingId = item.id;
		fVersion = item.version;
		fTitle = item.title;
		fContent = item.content;
		fEffectiveAt = item.effectiveAt ? item.effectiveAt.substring(0, 10) : '';
		errorMsg = null;
		showModal = true;
	}

	function closeModal() {
		showModal = false;
		errorMsg = null;
	}

	async function refreshList() {
		const res = await fetch('/api/v1/tnc');
		if (res.ok) list = await res.json() as TncItem[];
	}

	async function save() {
		if (!fVersion.trim() || !fTitle.trim() || !fContent.trim()) {
			errorMsg = 'Version, title and content are required.';
			return;
		}
		saving = true;
		errorMsg = null;
		try {
			const body: Record<string, string> = {
				version: fVersion.trim(),
				title: fTitle.trim(),
				content: fContent.trim()
			};
			if (fEffectiveAt) body.effective_at = new Date(fEffectiveAt).toISOString();

			const res = editingId
				? await fetch(`/api/v1/tnc/${editingId}`, {
						method: 'PUT',
						headers: { 'content-type': 'application/json' },
						body: JSON.stringify(body)
					})
				: await fetch('/api/v1/tnc', {
						method: 'POST',
						headers: { 'content-type': 'application/json' },
						body: JSON.stringify(body)
					});

			if (!res.ok) {
				const err = await res.json().catch(() => ({}));
				errorMsg = (err as { message?: string }).message ?? 'Failed to save.';
				return;
			}
			closeModal();
			await refreshList();
		} finally {
			saving = false;
		}
	}

	async function activate(id: string) {
		activating = id;
		try {
			const res = await fetch(`/api/v1/tnc/${id}/activate`, { method: 'POST' });
			if (!res.ok) {
				const err = await res.json().catch(() => ({}));
				alert((err as { message?: string }).message ?? 'Failed to activate.');
				return;
			}
			await refreshList();
		} finally {
			activating = null;
		}
	}

	async function deleteItem(id: string) {
		if (!confirm('Delete this T&C version? This cannot be undone.')) return;
		deleting = id;
		try {
			const res = await fetch(`/api/v1/tnc/${id}`, { method: 'DELETE' });
			if (!res.ok) {
				const err = await res.json().catch(() => ({}));
				alert((err as { message?: string }).message ?? 'Failed to delete.');
				return;
			}
			await refreshList();
		} finally {
			deleting = null;
		}
	}

	function formatDate(dt: string) {
		return new Date(dt).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
	}
</script>

<!-- Modal overlay -->
{#if showModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
		<div class="w-full max-w-2xl rounded-2xl bg-white shadow-2xl flex flex-col max-h-[90vh]">
			<div class="flex items-center justify-between px-6 py-4 border-b border-slate-200">
				<h2 class="text-base font-semibold text-slate-800">{editingId ? 'Edit T&C' : 'New Terms & Conditions'}</h2>
				<button onclick={closeModal} class="text-slate-400 hover:text-slate-600 transition-colors text-xl leading-none">&times;</button>
			</div>
			<div class="overflow-y-auto px-6 py-5 flex flex-col gap-4">
				<div>
					<label class="block text-xs font-medium text-slate-600 mb-1">Version <span class="text-red-500">*</span></label>
					<input
						bind:value={fVersion}
						placeholder="e.g. v1.0"
						class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
					/>
				</div>
				<div>
					<label class="block text-xs font-medium text-slate-600 mb-1">Title <span class="text-red-500">*</span></label>
					<input
						bind:value={fTitle}
						placeholder="Terms & Conditions"
						class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
					/>
				</div>
				<div>
					<label class="block text-xs font-medium text-slate-600 mb-1">Content <span class="text-red-500">*</span></label>
					<textarea
						bind:value={fContent}
						rows={10}
						placeholder="Full text of the terms and conditions…"
						class="w-full rounded-lg border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500 resize-y"
					></textarea>
				</div>
				<div>
					<label class="block text-xs font-medium text-slate-600 mb-1">Effective Date</label>
					<input
						type="date"
						bind:value={fEffectiveAt}
						class="rounded-lg border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
					/>
				</div>
				{#if errorMsg}
					<div class="rounded-lg bg-red-50 border border-red-200 px-4 py-2 text-sm text-red-700">{errorMsg}</div>
				{/if}
			</div>
			<div class="flex items-center justify-end gap-3 px-6 py-4 border-t border-slate-100">
				<button onclick={closeModal} class="rounded-lg px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 transition-colors">Cancel</button>
				<button
					onclick={save}
					disabled={saving}
					class="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-700 disabled:opacity-60 transition-colors"
				>
					{saving ? 'Saving…' : editingId ? 'Save Changes' : 'Create'}
				</button>
			</div>
		</div>
	</div>
{/if}

<div class="mb-6 flex items-center justify-between">
	<div>
		<h1 class="text-xl font-semibold text-slate-900">Terms & Conditions</h1>
		<p class="mt-1 text-sm text-slate-500">{list.length} version{list.length !== 1 ? 's' : ''} · served at /api/v1/tnc/current</p>
	</div>
	<button
		onclick={openCreate}
		class="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-700 transition-colors"
	>
		<PlusCircle size={16} />
		New T&C
	</button>
</div>

<div class="bg-white rounded-xl border border-slate-200 overflow-hidden">
	{#if list.length === 0}
		<div class="py-16 text-center text-slate-500 text-sm">No T&C versions yet — create one to activate it in the app.</div>
	{:else}
		<table class="w-full text-sm">
			<thead class="bg-slate-50 border-b border-slate-200">
				<tr>
					<th class="px-4 py-3 text-left font-medium text-slate-600">Version</th>
					<th class="px-4 py-3 text-left font-medium text-slate-600">Title</th>
					<th class="px-4 py-3 text-left font-medium text-slate-600 w-28">Status</th>
					<th class="px-4 py-3 text-left font-medium text-slate-600 w-32">Effective Date</th>
					<th class="px-4 py-3 text-left font-medium text-slate-600 w-28">Acceptances</th>
					<th class="px-4 py-3 w-36"></th>
				</tr>
			</thead>
			<tbody class="divide-y divide-slate-100">
				{#each list as item (item.id)}
					<tr class="hover:bg-slate-50 {item.isActive ? 'border-l-4 border-l-green-500' : ''}">
						<td class="px-4 py-3">
							<span class="font-mono text-sm font-medium text-slate-700">{item.version}</span>
						</td>
						<td class="px-4 py-3">
							<div class="font-medium text-slate-800 truncate max-w-xs">{item.title}</div>
							<div class="text-xs text-slate-400 mt-0.5 line-clamp-1">{item.content.substring(0, 80)}…</div>
						</td>
						<td class="px-4 py-3">
							{#if item.isActive}
								<span class="inline-flex items-center gap-1 text-xs font-medium px-2 py-1 rounded-full bg-green-50 text-green-700 border border-green-200">
									<CheckCircle2 size={11} /> Active
								</span>
							{:else}
								<span class="inline-flex items-center gap-1 text-xs font-medium px-2 py-1 rounded-full bg-slate-100 text-slate-500 border border-slate-200">
									<CircleDashed size={11} /> Draft
								</span>
							{/if}
						</td>
						<td class="px-4 py-3 text-slate-600 text-xs">{formatDate(item.effectiveAt)}</td>
						<td class="px-4 py-3 text-slate-600 text-xs">{item._count.acceptances.toLocaleString()}</td>
						<td class="px-4 py-3">
							<div class="flex items-center justify-end gap-1">
								<button
									onclick={() => openEdit(item)}
									class="p-1.5 rounded hover:bg-slate-100 text-slate-500 hover:text-slate-700 transition-colors"
									title="Edit"
								>
									<Pencil size={14} />
								</button>
								<button
									onclick={() => activate(item.id)}
									disabled={item.isActive || activating === item.id}
									class="px-2 py-1 rounded text-xs font-medium transition-colors
										{item.isActive
											? 'bg-green-50 text-green-600 border border-green-200 cursor-default opacity-60'
											: 'bg-brand-50 text-brand-700 border border-brand-200 hover:bg-brand-100 disabled:opacity-40'}"
									title={item.isActive ? 'Already active' : 'Activate this version'}
								>
									{activating === item.id ? '…' : 'Activate'}
								</button>
								<button
									onclick={() => deleteItem(item.id)}
									disabled={item.isActive || deleting === item.id}
									class="p-1.5 rounded transition-colors
										{item.isActive
											? 'text-slate-300 cursor-not-allowed'
											: 'hover:bg-red-50 text-slate-400 hover:text-red-600'}"
									title={item.isActive ? 'Cannot delete active version' : 'Delete'}
								>
									<Trash2 size={14} />
								</button>
							</div>
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	{/if}
</div>
