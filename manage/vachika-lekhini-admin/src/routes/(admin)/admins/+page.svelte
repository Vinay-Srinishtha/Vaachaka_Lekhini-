<script lang="ts">
	import { Plus, UserX, UserCheck } from '@lucide/svelte';
	import PageHeader from '$lib/components/PageHeader.svelte';
	import DataTable from '$lib/components/DataTable.svelte';
	import type { Column } from '$lib/components/DataTable.types';
	import Modal from '$lib/components/Modal.svelte';
	import FormField from '$lib/components/FormField.svelte';
	import { ADMIN_ROLES, ROLE_LABELS } from '$lib/constants';
	import { enhance } from '$app/forms';
	import { goto, invalidateAll } from '$app/navigation';
	import { page } from '$app/state';
	import { patchQuery } from '$lib/url';
	import { toasts } from '$lib/stores/toast';

	let { data, form } = $props();

	const columns: Column[] = [
		{ key: 'username', label: 'Username', sortable: true },
		{ key: 'email', label: 'Email', hidden: 'md' },
		{ key: 'role', label: 'Role', sortable: true },
		{ key: 'isActive', label: 'Status', sortable: true },
		{ key: 'createdAt', label: 'Created', sortable: true, hidden: 'lg' },
		{ key: 'lastLoginAt', label: 'Last login', sortable: true, hidden: 'lg' },
		{ key: 'actions', label: '', align: 'right' }
	];

	const newOpen = $derived(page.url.searchParams.get('new') === '1');
	let submitting = $state(false);

	function fmt(d: Date | string | null) {
		if (!d) return '—';
		return new Date(d).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });
	}

	function closeNew() {
		goto(patchQuery(page.url, { new: null }), {
			keepFocus: true,
			noScroll: true,
			replaceState: true
		});
	}

	const me = $derived(data.admin!);
	const fe = $derived((form?.fieldErrors ?? {}) as Record<string, string>);
	const roleTone: Record<string, string> = {
		super_admin: 'bg-purple-100 text-purple-700',
		main_admin: 'bg-blue-100 text-blue-700',
		assets_admin: 'bg-amber-100 text-amber-700',
		marketplace_admin: 'bg-emerald-100 text-emerald-700'
	};
</script>

<PageHeader title="Admins" subtitle="Manage who can sign in to this dashboard">
	{#snippet actions()}
		<a
			href={patchQuery(page.url, { new: 1 })}
			class="btn-primary"
			data-sveltekit-noscroll
			data-sveltekit-replacestate
		>
			<Plus size={16} /> New admin
		</a>
	{/snippet}
</PageHeader>

{#if form?.error}
	<div class="mb-4 text-sm rounded-lg bg-red-50 text-red-700 border border-red-200 px-3 py-2">
		{form.error}
	</div>
{/if}

<DataTable
	{columns}
	rows={data.admins}
	total={data.total}
	currentPage={data.query.page}
	pageSize={data.query.pageSize}
	defaultSort={{ col: 'createdAt', dir: 'desc' }}
	searchPlaceholder="Search admins…"
	emptyTitle="No admins"
>
	{#snippet row(a)}
		<tr class="hover:bg-gray-50">
			<td class="px-4 py-3">
				<div class="font-medium text-gray-900">{a.username}</div>
				{#if a.id === me.id}
					<div class="text-[10px] text-brand-700 font-medium uppercase tracking-wide mt-0.5">you</div>
				{/if}
			</td>
			<td class="px-4 py-3 hidden md:table-cell text-gray-600 text-xs">{a.email ?? '—'}</td>
			<td class="px-4 py-3">
				<form method="POST" action="?/setRole" use:enhance={() => {
					const name = a.username;
					return async ({ result, update }) => {
						await update();
						if (result.type === 'success') toasts.show(`Role updated for ${name}`);
					};
				}} class="flex">
					<input type="hidden" name="id" value={a.id} />
					<select
						name="role"
						class="text-xs rounded-full px-2.5 py-1 border-none font-medium {roleTone[a.role]}"
						disabled={a.id === me.id}
						onchange={(e) => {
							const f = (e.currentTarget as HTMLSelectElement).form;
							f?.requestSubmit();
						}}
					>
						{#each ADMIN_ROLES as r}
							<option value={r} selected={a.role === r}>{ROLE_LABELS[r]}</option>
						{/each}
					</select>
				</form>
			</td>
			<td class="px-4 py-3">
				{#if a.isActive}
					<span class="chip bg-green-100 text-green-700">active</span>
				{:else}
					<span class="chip bg-gray-100 text-gray-600">disabled</span>
				{/if}
			</td>
			<td class="px-4 py-3 hidden lg:table-cell text-gray-600 text-xs">{fmt(a.createdAt)}</td>
			<td class="px-4 py-3 hidden lg:table-cell text-gray-600 text-xs">{fmt(a.lastLoginAt)}</td>
			<td class="px-4 py-3">
				<form method="POST" action="?/toggleActive" use:enhance={() => {
					const wasActive = a.isActive;
					return async ({ result, update }) => {
						await update();
						if (result.type === 'success') toasts.show(wasActive ? `${a.username} disabled` : `${a.username} enabled`);
					};
				}} class="flex justify-end">
					<input type="hidden" name="id" value={a.id} />
					<button
						class={a.isActive ? 'btn-secondary !px-2 !py-1.5' : 'btn-primary !px-2 !py-1.5'}
						disabled={a.id === me.id}
						title={a.isActive ? 'Disable login' : 'Enable login'}
					>
						{#if a.isActive}<UserX size={14} /><span class="hidden sm:inline">Disable</span>
						{:else}<UserCheck size={14} /><span class="hidden sm:inline">Enable</span>{/if}
					</button>
				</form>
			</td>
		</tr>
	{/snippet}
</DataTable>

<Modal open={newOpen} title="New admin" size="md" onClose={closeNew}>
	<form
		method="POST"
		action="?/create"
		use:enhance={() => {
			submitting = true;
			return async ({ result, update }) => {
				if (result.type === 'redirect' || result.type === 'success') {
					toasts.show('Admin account created');
					closeNew();
					await invalidateAll();
				} else {
					await update();
				}
				submitting = false;
			};
		}}
		class="space-y-4"
	>
		<FormField label="Username" name="username" required error={fe.username}>
			<input id="username" name="username" class="input" required autocomplete="off" />
		</FormField>
		<FormField label="Email" name="email" error={fe.email}>
			<input id="email" name="email" type="email" class="input" autocomplete="off" />
		</FormField>
		<FormField label="Password" name="password" required hint="Minimum 8 characters." error={fe.password}>
			<input id="password" name="password" type="password" class="input" required autocomplete="new-password" />
		</FormField>
		<FormField label="Role" name="role" required error={fe.role}>
			<select id="role" name="role" class="input">
				{#each ADMIN_ROLES as r}
					<option value={r}>{ROLE_LABELS[r]}</option>
				{/each}
			</select>
		</FormField>
		<div class="flex justify-end gap-2 pt-2">
			<button type="button" class="btn-secondary" onclick={closeNew}>Cancel</button>
			<button type="submit" class="btn-primary" disabled={submitting}>
				{submitting ? 'Creating…' : 'Create admin'}
			</button>
		</div>
	</form>
</Modal>
