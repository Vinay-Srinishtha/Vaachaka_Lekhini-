<script lang="ts">
	import { enhance } from '$app/forms';
	import { invalidateAll } from '$app/navigation';
	import PageHeader from '$lib/components/PageHeader.svelte';
	import Modal from '$lib/components/Modal.svelte';
	import { toasts } from '$lib/stores/toast';
	import { ROLE_LABELS } from '$lib/constants';
	import { PERMISSION_GROUPS } from '$lib/permissions';
	import { Pencil, ShieldCheck, Users } from '@lucide/svelte';

	interface RoleEntry {
		role: string;
		label: string;
		permissions: string[];
		updatedAt: Date | null;
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

	function closeEdit() {
		editingRole = null;
	}

	function togglePerm(key: string) {
		if (editPerms.has(key)) editPerms.delete(key);
		else editPerms.add(key);
		editPerms = new Set(editPerms); // trigger reactivity
	}

	function groupChecked(group: typeof PERMISSION_GROUPS[number]): 'all' | 'some' | 'none' {
		const keys = group.permissions.map((p) => p.key);
		const count = keys.filter((k) => editPerms.has(k)).length;
		if (count === keys.length) return 'all';
		if (count > 0) return 'some';
		return 'none';
	}

	function toggleGroup(group: typeof PERMISSION_GROUPS[number]) {
		const keys = group.permissions.map((p) => p.key);
		const allOn = keys.every((k) => editPerms.has(k));
		if (allOn) keys.forEach((k) => editPerms.delete(k));
		else keys.forEach((k) => editPerms.add(k));
		editPerms = new Set(editPerms);
	}

	function fmtDate(d: Date | null) {
		if (!d) return 'Default';
		return new Date(d).toLocaleDateString(undefined, { dateStyle: 'medium' });
	}

	const editingLabel = $derived(
		editingRole ? (ROLE_LABELS as Record<string, string>)[editingRole] ?? editingRole : ''
	);
</script>

<PageHeader title="Roles" subtitle="Configure which permissions each admin role has access to" />

{#if form?.error}
	<div class="mb-4 text-sm rounded-lg bg-red-50 text-red-700 border border-red-200 px-3 py-2">
		{form.error}
	</div>
{/if}

<!-- Role cards grid -->
<div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
	{#each data.roles as r (r.role)}
		{@const tone = roleTone[r.role] ?? 'bg-gray-100 text-gray-700 border-gray-200'}
		<div class="bg-white rounded-2xl border border-gray-200 shadow-sm p-5 flex flex-col gap-4">
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
				<button
					onclick={() => openEdit(r.role)}
					class="btn-secondary !px-2 !py-1.5 shrink-0"
					title="Edit permissions"
				>
					<Pencil size={14} />
					<span class="hidden sm:inline">Edit</span>
				</button>
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

<!-- Edit Modal -->
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

			<!-- Progress bar -->
			<div class="mb-4 flex items-center gap-3">
				<div class="flex-1 bg-gray-100 rounded-full h-2 overflow-hidden">
					<div
						class="h-full rounded-full bg-brand-500 transition-all duration-300"
						style="width: {Math.round((editPerms.size / data.allPermissions.length) * 100)}%"
					></div>
				</div>
				<span class="text-xs font-semibold text-gray-600 tabular-nums whitespace-nowrap">
					{editPerms.size} / {data.allPermissions.length}
				</span>
			</div>

			<div class="space-y-3 max-h-[58vh] overflow-y-auto pr-0.5 -mr-1">
				{#each PERMISSION_GROUPS as group}
					{@const state = groupChecked(group)}
					{@const grantedCount = group.permissions.filter((p) => editPerms.has(p.key)).length}
					<div class="rounded-xl border overflow-hidden
						{state === 'all' ? 'border-brand-200' : state === 'some' ? 'border-amber-200' : 'border-gray-200'}">
						<!-- Group header -->
						<button
							type="button"
							onclick={() => toggleGroup(group)}
							class="w-full flex items-center gap-3 px-4 py-2.5 text-left transition-colors
								{state === 'all'
									? 'bg-brand-50 hover:bg-brand-100'
									: state === 'some'
										? 'bg-amber-50 hover:bg-amber-100'
										: 'bg-gray-50 hover:bg-gray-100'}"
						>
							<span
								class="w-4 h-4 rounded border-2 flex items-center justify-center shrink-0 transition-colors
									{state === 'all'
										? 'bg-brand-600 border-brand-600'
										: state === 'some'
											? 'bg-amber-400 border-amber-400'
											: 'border-gray-300 bg-white'}"
							>
								{#if state === 'all'}
									<svg class="w-2.5 h-2.5 text-white" fill="none" viewBox="0 0 10 8">
										<path d="M1 4l3 3 5-6" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
									</svg>
								{:else if state === 'some'}
									<span class="w-1.5 h-0.5 bg-white rounded-full"></span>
								{/if}
							</span>
							<span class="text-sm font-semibold
								{state === 'all' ? 'text-brand-800' : state === 'some' ? 'text-amber-800' : 'text-gray-700'}">
								{group.label}
							</span>
							<span class="ml-auto text-xs font-medium tabular-nums
								{state === 'all' ? 'text-brand-600' : state === 'some' ? 'text-amber-600' : 'text-gray-400'}">
								{grantedCount}/{group.permissions.length}
							</span>
						</button>

						<!-- Permission pills -->
						<div class="flex flex-wrap gap-1.5 px-4 py-3 bg-white">
							{#each group.permissions as perm}
								{@const active = editPerms.has(perm.key)}
								<button
									type="button"
									onclick={() => togglePerm(perm.key)}
									class="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-medium border transition-all
										{active
											? 'bg-brand-600 text-white border-brand-600 shadow-sm'
											: 'bg-gray-50 text-gray-500 border-gray-200 hover:border-brand-300 hover:text-brand-700 hover:bg-brand-50'}"
								>
									{#if active}
										<svg class="w-2.5 h-2.5 shrink-0" fill="none" viewBox="0 0 10 8">
											<path d="M1 4l3 3 5-6" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
										</svg>
									{/if}
									{perm.label}
								</button>
							{/each}
						</div>
					</div>
				{/each}
			</div>

			<!-- Footer -->
			<div class="mt-4 pt-4 border-t border-gray-100">
				<p class="text-sm text-gray-400">
					<span class="font-semibold text-gray-700">{editPerms.size}</span> of {data.allPermissions.length} permissions selected
				</p>
			</div>
		</form>
	{/if}
</Modal>
