<script lang="ts">
	import { enhance } from '$app/forms';
	import { invalidateAll } from '$app/navigation';
	import PageHeader from '$lib/components/PageHeader.svelte';
	import Modal from '$lib/components/Modal.svelte';
	import { toasts } from '$lib/stores/toast';
	import { ROLE_LABELS } from '$lib/constants';
	import { PERMISSION_GROUPS } from '$lib/permissions';
	import { Pencil, ShieldCheck, Users, Plus, Trash2 } from '@lucide/svelte';

	interface RoleEntry {
		role: string;
		label: string;
		permissions: string[];
		updatedAt: Date | null;
		isCustom: boolean;
	}

	interface PageData {
		roles: RoleEntry[];
		adminCounts: Record<string, number>;
		allPermissions: string[];
	}

	let { data, form }: { data: PageData; form: { error?: string } | null } = $props();

	// ── Edit modal state ────────────────────────────────────────────────────
	let editingRole: string | null = $state(null);
	let editPerms = $state<Set<string>>(new Set());
	let submitting = $state(false);

	// ── Create modal state ──────────────────────────────────────────────────
	let creating = $state(false);
	let newKey = $state('');
	let newLabel = $state('');
	let newPerms = $state<Set<string>>(new Set());
	let createSubmitting = $state(false);

	// ── Delete confirm state ────────────────────────────────────────────────
	let deletingRole: string | null = $state(null);
	let deleteSubmitting = $state(false);

	const roleTone: Record<string, string> = {
		super_admin:      'bg-purple-100 text-purple-700 border-purple-200',
		main_admin:       'bg-blue-100 text-blue-700 border-blue-200',
		assets_admin:     'bg-amber-100 text-amber-700 border-amber-200',
		marketplace_admin:'bg-emerald-100 text-emerald-700 border-emerald-200'
	};

	function openEdit(role: string) {
		const r = data.roles.find((r) => r.role === role);
		editPerms = new Set(r?.permissions ?? []);
		editingRole = role;
	}

	function closeEdit() { editingRole = null; }

	function togglePerm(key: string, set: Set<string>): Set<string> {
		const s = new Set(set);
		if (s.has(key)) s.delete(key); else s.add(key);
		return s;
	}

	function groupChecked(group: typeof PERMISSION_GROUPS[number], perms: Set<string>): 'all' | 'some' | 'none' {
		const keys = group.permissions.map((p) => p.key);
		const count = keys.filter((k) => perms.has(k)).length;
		if (count === keys.length) return 'all';
		if (count > 0) return 'some';
		return 'none';
	}

	function toggleGroup(group: typeof PERMISSION_GROUPS[number], perms: Set<string>): Set<string> {
		const keys = group.permissions.map((p) => p.key);
		const s = new Set(perms);
		const allOn = keys.every((k) => s.has(k));
		if (allOn) keys.forEach((k) => s.delete(k));
		else keys.forEach((k) => s.add(k));
		return s;
	}

	function fmtDate(d: Date | null) {
		if (!d) return 'Default';
		return new Date(d).toLocaleDateString(undefined, { dateStyle: 'medium' });
	}

	const editingLabel = $derived(
		editingRole ? (ROLE_LABELS as Record<string, string>)[editingRole] ?? data.roles.find(r => r.role === editingRole)?.label ?? editingRole : ''
	);

	// Auto-generate key from label
	$effect(() => {
		newKey = newLabel.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '').slice(0, 40);
	});
</script>

<PageHeader title="Roles" subtitle="Configure which permissions each admin role has access to">
	{#snippet actions()}
		<button onclick={() => { creating = true; newLabel = ''; newKey = ''; newPerms = new Set(); }} class="btn-primary flex items-center gap-1.5">
			<Plus size={15} />
			New Role
		</button>
	{/snippet}
</PageHeader>

{#if form?.error}
	<div class="mb-4 text-sm rounded-lg bg-red-50 text-red-700 border border-red-200 px-3 py-2">
		{form.error}
	</div>
{/if}

<!-- Role cards grid -->
<div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
	{#each data.roles as r (r.role)}
		{@const tone = roleTone[r.role] ?? 'bg-gray-100 text-gray-700 border-gray-200'}
		<div class="bg-white rounded-2xl border border-gray-200 shadow-sm p-5 flex flex-col gap-4 relative">
			<!-- Custom badge -->
			{#if r.isCustom}
				<span class="absolute top-3 right-3 text-[9px] font-bold uppercase tracking-wider bg-indigo-50 text-indigo-600 border border-indigo-200 rounded-full px-2 py-0.5">Custom</span>
			{/if}

			<!-- Header -->
			<div class="flex items-start justify-between gap-2">
				<div>
					<span class="inline-block text-xs font-semibold rounded-full px-2.5 py-1 border {tone}">
						{r.label}
					</span>
					<div class="mt-2 flex items-center gap-1.5 text-sm text-gray-500">
						<Users size={13} />
						<span>{data.adminCounts[r.role] ?? 0} admin{(data.adminCounts[r.role] ?? 0) !== 1 ? 's' : ''}</span>
					</div>
				</div>
				<div class="flex items-center gap-1 shrink-0">
					<button
						onclick={() => openEdit(r.role)}
						class="btn-secondary !px-2 !py-1.5"
						title="Edit permissions"
					>
						<Pencil size={14} />
						<span class="hidden sm:inline">Edit</span>
					</button>
					{#if r.isCustom}
						<button
							onclick={() => { deletingRole = r.role; }}
							class="btn-danger !px-2 !py-1.5"
							title="Delete role"
						>
							<Trash2 size={14} />
						</button>
					{/if}
				</div>
			</div>

			<!-- Permission count summary -->
			<div class="flex items-center gap-2">
				<div class="flex-1 bg-gray-100 rounded-full h-1.5 overflow-hidden">
					<div
						class="h-full rounded-full bg-brand-500 transition-all"
						style="width: {Math.round((r.permissions.length / data.allPermissions.length) * 100)}%"
					></div>
				</div>
				<span class="text-xs text-gray-500 shrink-0 tabular-nums">
					{r.permissions.length} / {data.allPermissions.length}
				</span>
			</div>

			<!-- Permission group pills -->
			<div class="flex flex-wrap gap-1.5">
				{#each PERMISSION_GROUPS as g}
					{@const groupKeys = g.permissions.map((p) => p.key)}
					{@const granted = groupKeys.filter((k) => r.permissions.includes(k)).length}
					{#if granted > 0}
						<span
							class="text-[10px] font-medium rounded-full px-2 py-0.5 border
								{granted === groupKeys.length
									? 'bg-brand-50 text-brand-700 border-brand-200'
									: 'bg-yellow-50 text-yellow-700 border-yellow-200'}"
							title="{granted}/{groupKeys.length} permissions"
						>
							{g.label}
							{#if granted < groupKeys.length}
								<span class="opacity-60">({granted}/{groupKeys.length})</span>
							{/if}
						</span>
					{/if}
				{/each}
			</div>

			<p class="text-[10px] text-gray-400 mt-auto">Last updated: {fmtDate(r.updatedAt)}</p>
		</div>
	{/each}
</div>

<!-- ── Edit Modal ── -->
<Modal
	open={editingRole !== null}
	title="Edit Role — {editingLabel}"
	subtitle="Toggle permissions for this role. Changes take effect immediately on save."
	size="xl"
	formId="role-form"
	saveLabel="Save Changes"
	onClose={closeEdit}
>
	{#if editingRole}
		<form
			id="role-form"
			method="POST"
			action="?/save"
			use:enhance={() => {
				submitting = true;
				return async ({ result, update }) => {
					submitting = false;
					if (result.type === 'success') {
						toasts.show(`Permissions saved for ${editingLabel}`);
						closeEdit();
						await invalidateAll();
					} else {
						await update();
					}
				};
			}}
		>
			<input type="hidden" name="role" value={editingRole} />
			{#each [...editPerms] as p}
				<input type="hidden" name="permissions" value={p} />
			{/each}

			<div class="mb-4 flex items-center gap-3">
				<div class="flex-1 bg-gray-100 rounded-full h-2 overflow-hidden">
					<div class="h-full rounded-full bg-brand-500 transition-all duration-300"
						style="width: {Math.round((editPerms.size / data.allPermissions.length) * 100)}%"></div>
				</div>
				<span class="text-xs font-semibold text-gray-600 tabular-nums whitespace-nowrap">
					{editPerms.size} / {data.allPermissions.length}
				</span>
			</div>

			<div class="space-y-3 max-h-[58vh] overflow-y-auto pr-0.5 -mr-1">
				{#each PERMISSION_GROUPS as group}
					{@const state = groupChecked(group, editPerms)}
					{@const grantedCount = group.permissions.filter((p) => editPerms.has(p.key)).length}
					<div class="rounded-xl border overflow-hidden
						{state === 'all' ? 'border-brand-200' : state === 'some' ? 'border-amber-200' : 'border-gray-200'}">
						<button type="button" onclick={() => { editPerms = toggleGroup(group, editPerms); }}
							class="w-full flex items-center gap-3 px-4 py-2.5 text-left transition-colors
								{state === 'all' ? 'bg-brand-50 hover:bg-brand-100' : state === 'some' ? 'bg-amber-50 hover:bg-amber-100' : 'bg-gray-50 hover:bg-gray-100'}">
							<span class="w-4 h-4 rounded border-2 flex items-center justify-center shrink-0 transition-colors
								{state === 'all' ? 'bg-brand-600 border-brand-600' : state === 'some' ? 'bg-amber-400 border-amber-400' : 'border-gray-300 bg-white'}">
								{#if state === 'all'}
									<svg class="w-2.5 h-2.5 text-white" fill="none" viewBox="0 0 10 8"><path d="M1 4l3 3 5-6" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
								{:else if state === 'some'}
									<span class="w-1.5 h-0.5 bg-white rounded-full"></span>
								{/if}
							</span>
							<span class="text-sm font-semibold {state === 'all' ? 'text-brand-800' : state === 'some' ? 'text-amber-800' : 'text-gray-700'}">{group.label}</span>
							<span class="ml-auto text-xs font-medium tabular-nums {state === 'all' ? 'text-brand-600' : state === 'some' ? 'text-amber-600' : 'text-gray-400'}">{grantedCount}/{group.permissions.length}</span>
						</button>
						<div class="flex flex-wrap gap-1.5 px-4 py-3 bg-white">
							{#each group.permissions as perm}
								{@const active = editPerms.has(perm.key)}
								<button type="button" onclick={() => { editPerms = togglePerm(perm.key, editPerms); }}
									class="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-medium border transition-all
										{active ? 'bg-brand-600 text-white border-brand-600 shadow-sm' : 'bg-gray-50 text-gray-500 border-gray-200 hover:border-brand-300 hover:text-brand-700 hover:bg-brand-50'}">
									{#if active}
										<svg class="w-2.5 h-2.5 shrink-0" fill="none" viewBox="0 0 10 8"><path d="M1 4l3 3 5-6" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
									{/if}
									{perm.label}
								</button>
							{/each}
						</div>
					</div>
				{/each}
			</div>

			<div class="mt-4 pt-4 border-t border-gray-100">
				<p class="text-sm text-gray-400">
					<span class="font-semibold text-gray-700">{editPerms.size}</span> of {data.allPermissions.length} permissions selected
				</p>
			</div>
		</form>
	{/if}
</Modal>

<!-- ── Create Role Modal ── -->
<Modal
	open={creating}
	title="Create New Role"
	subtitle="Define a custom role with a unique key, display name, and permissions."
	size="xl"
	formId="create-role-form"
	saveLabel="Create Role"
	onClose={() => { creating = false; }}
>
	<form
		id="create-role-form"
		method="POST"
		action="?/create"
		use:enhance={() => {
			createSubmitting = true;
			return async ({ result, update }) => {
				createSubmitting = false;
				if (result.type === 'success') {
					toasts.show(`Role "${newLabel}" created`);
					creating = false;
					await invalidateAll();
				} else {
					await update();
				}
			};
		}}
	>
		{#each [...newPerms] as p}
			<input type="hidden" name="permissions" value={p} />
		{/each}

		<div class="space-y-4 mb-5">
			<div>
				<label class="block text-sm font-medium text-gray-700 mb-1" for="new-label">Display Name</label>
				<input
					id="new-label"
					name="label"
					type="text"
					bind:value={newLabel}
					placeholder="e.g. Content Editor"
					class="input w-full"
					required
				/>
			</div>
			<div>
				<label class="block text-sm font-medium text-gray-700 mb-1" for="new-key">
					Role Key <span class="text-gray-400 font-normal">(auto-generated, editable)</span>
				</label>
				<input
					id="new-key"
					name="key"
					type="text"
					bind:value={newKey}
					placeholder="e.g. content_editor"
					class="input w-full font-mono text-sm"
					pattern="[a-z][a-z0-9_]*"
					required
				/>
				<p class="mt-1 text-xs text-gray-400">Lowercase letters, digits and underscores only. Cannot be changed later.</p>
			</div>
		</div>

		<p class="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">Permissions</p>

		<div class="mb-4 flex items-center gap-3">
			<div class="flex-1 bg-gray-100 rounded-full h-2 overflow-hidden">
				<div class="h-full rounded-full bg-brand-500 transition-all duration-300"
					style="width: {Math.round((newPerms.size / data.allPermissions.length) * 100)}%"></div>
			</div>
			<span class="text-xs font-semibold text-gray-600 tabular-nums whitespace-nowrap">
				{newPerms.size} / {data.allPermissions.length}
			</span>
		</div>

		<div class="space-y-3 max-h-[40vh] overflow-y-auto pr-0.5 -mr-1">
			{#each PERMISSION_GROUPS as group}
				{@const state = groupChecked(group, newPerms)}
				{@const grantedCount = group.permissions.filter((p) => newPerms.has(p.key)).length}
				<div class="rounded-xl border overflow-hidden
					{state === 'all' ? 'border-brand-200' : state === 'some' ? 'border-amber-200' : 'border-gray-200'}">
					<button type="button" onclick={() => { newPerms = toggleGroup(group, newPerms); }}
						class="w-full flex items-center gap-3 px-4 py-2.5 text-left transition-colors
							{state === 'all' ? 'bg-brand-50 hover:bg-brand-100' : state === 'some' ? 'bg-amber-50 hover:bg-amber-100' : 'bg-gray-50 hover:bg-gray-100'}">
						<span class="w-4 h-4 rounded border-2 flex items-center justify-center shrink-0 transition-colors
							{state === 'all' ? 'bg-brand-600 border-brand-600' : state === 'some' ? 'bg-amber-400 border-amber-400' : 'border-gray-300 bg-white'}">
							{#if state === 'all'}
								<svg class="w-2.5 h-2.5 text-white" fill="none" viewBox="0 0 10 8"><path d="M1 4l3 3 5-6" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
							{:else if state === 'some'}
								<span class="w-1.5 h-0.5 bg-white rounded-full"></span>
							{/if}
						</span>
						<span class="text-sm font-semibold {state === 'all' ? 'text-brand-800' : state === 'some' ? 'text-amber-800' : 'text-gray-700'}">{group.label}</span>
						<span class="ml-auto text-xs font-medium tabular-nums {state === 'all' ? 'text-brand-600' : state === 'some' ? 'text-amber-600' : 'text-gray-400'}">{grantedCount}/{group.permissions.length}</span>
					</button>
					<div class="flex flex-wrap gap-1.5 px-4 py-3 bg-white">
						{#each group.permissions as perm}
							{@const active = newPerms.has(perm.key)}
							<button type="button" onclick={() => { newPerms = togglePerm(perm.key, newPerms); }}
								class="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-medium border transition-all
									{active ? 'bg-brand-600 text-white border-brand-600 shadow-sm' : 'bg-gray-50 text-gray-500 border-gray-200 hover:border-brand-300 hover:text-brand-700 hover:bg-brand-50'}">
								{#if active}
									<svg class="w-2.5 h-2.5 shrink-0" fill="none" viewBox="0 0 10 8"><path d="M1 4l3 3 5-6" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>
								{/if}
								{perm.label}
							</button>
						{/each}
					</div>
				</div>
			{/each}
		</div>
	</form>
</Modal>

<!-- ── Delete Confirm Modal ── -->
{#if deletingRole}
	{@const roleEntry = data.roles.find(r => r.role === deletingRole)}
	<Modal
		open={deletingRole !== null}
		title="Delete Role"
		subtitle="This cannot be undone. The role will be permanently removed."
		size="sm"
		formId="delete-role-form"
		saveLabel="Delete"
		onClose={() => { deletingRole = null; }}
	>
		<form
			id="delete-role-form"
			method="POST"
			action="?/delete"
			use:enhance={() => {
				deleteSubmitting = true;
				return async ({ result, update }) => {
					deleteSubmitting = false;
					if (result.type === 'success') {
						toasts.show(`Role "${roleEntry?.label}" deleted`);
						deletingRole = null;
						await invalidateAll();
					} else {
						await update();
					}
				};
			}}
		>
			<input type="hidden" name="key" value={deletingRole} />
			<p class="text-sm text-gray-600">
				Are you sure you want to delete the <span class="font-semibold">{roleEntry?.label}</span> role?
				Any admins assigned this role will need to be reassigned.
			</p>
		</form>
	</Modal>
{/if}
