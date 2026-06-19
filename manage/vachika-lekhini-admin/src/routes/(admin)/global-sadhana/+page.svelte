<script lang="ts">
	import { enhance } from '$app/forms';
	import { toasts } from '$lib/stores/toast';
	import { Globe, PlusCircle, Pencil, Trash2, Users, Target, Play, Pause, Archive, CheckCircle } from '@lucide/svelte';
	import { IndianNumber } from '$lib/utils/format';

	let { data, form } = $props();

	const STATUS_COLORS: Record<string, string> = {
		draft:     'bg-slate-100 text-slate-600',
		published: 'bg-blue-50 text-blue-700 border border-blue-200',
		active:    'bg-green-50 text-green-700 border border-green-200',
		paused:    'bg-amber-50 text-amber-700 border border-amber-200',
		completed: 'bg-purple-50 text-purple-700 border border-purple-200',
		archived:  'bg-slate-50 text-slate-500'
	};

	const STATUS_LABELS: Record<string, string> = {
		draft: 'Draft', published: 'Published', active: 'Active',
		paused: 'Paused', completed: 'Completed', archived: 'Archived'
	};

	let confirmDeleteId = $state<string | null>(null);
	let deleting = $state(false);

	function progressPct(current: number, target: number) {
		return target > 0 ? Math.min(100, Math.round((current / target) * 100)) : 0;
	}

	function fmt(n: number) {
		return n.toLocaleString('en-IN');
	}
</script>

{#if form?.error}
	<div class="fixed bottom-6 right-6 z-50 max-w-md rounded-lg bg-red-50 text-red-700 border border-red-200 px-4 py-3 text-sm shadow-lg">{form.error}</div>
{/if}

<!-- Header -->
<div class="mb-6 flex flex-wrap items-start justify-between gap-4">
	<div>
		<h1 class="text-xl font-semibold text-slate-900 flex items-center gap-2">
			<Globe size={20} class="text-brand-600" /> Global Sadhana
		</h1>
		<p class="mt-1 text-sm text-slate-500">{data.sadhanas.length} programs · community spiritual initiatives</p>
	</div>
	<a href="/global-sadhana/new" class="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-700 transition-colors">
		<PlusCircle size={16} /> New Global Sadhana
	</a>
</div>

<!-- List -->
<div class="space-y-3">
	{#if data.sadhanas.length === 0}
		<div class="bg-white rounded-xl border border-slate-200 py-16 text-center text-slate-500 text-sm">
			No global sadhanas yet — create one to launch a community initiative.
		</div>
	{/if}

	{#each data.sadhanas as s (s.id)}
		{@const pct = progressPct(s.currentCount, s.targetCount)}
		<div class="bg-white rounded-xl border border-slate-200 p-5">
			<div class="flex flex-wrap items-start justify-between gap-3">
				<!-- Thumbnail -->
				<div class="shrink-0">
					{#if s.imageUrl}
						<img src={s.imageUrl} alt={s.title} class="w-14 h-14 rounded-lg object-cover" />
					{:else}
						<div class="w-14 h-14 rounded-lg bg-slate-100 flex items-center justify-center text-slate-400">
							<Globe size={24} />
						</div>
					{/if}
				</div>
				<!-- Left: info -->
				<div class="flex-1 min-w-0">
					<div class="flex items-center gap-2 flex-wrap">
						<span class="text-base font-semibold text-slate-900 truncate">{s.title}</span>
						{#if s.isSponsored}
							<span class="inline-flex items-center rounded-full bg-amber-50 px-2 py-0.5 text-xs font-semibold text-amber-700 border border-amber-200">⭐ Sponsored</span>
						{/if}
						<span class="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold {STATUS_COLORS[s.status]}">
							{STATUS_LABELS[s.status]}
						</span>
					</div>
					<p class="mt-1 text-sm text-slate-500">
						{s.mantra.nameRoman}{s.mantra.nameTelugu ? ` · ${s.mantra.nameTelugu}` : ''} ·
						{s.participationMode === 'both' ? 'Voice & Handwriting' : s.participationMode === 'voice' ? 'Voice only' : 'Handwriting only'}
					</p>
					<p class="mt-0.5 text-xs text-slate-400">
						{new Date(s.startAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
						{s.endAt ? ` → ${new Date(s.endAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}` : ''}
					</p>

					<!-- Progress bar -->
					<div class="mt-3">
						<div class="flex items-center justify-between text-xs text-slate-500 mb-1">
							<span>{fmt(s.currentCount)} / {fmt(s.targetCount)}</span>
							<span>{pct}%</span>
						</div>
						<div class="h-2 rounded-full bg-slate-100 overflow-hidden">
							<div class="h-full rounded-full bg-brand-500 transition-all" style="width: {pct}%"></div>
						</div>
					</div>

					<!-- Stats row -->
					<div class="mt-3 flex items-center gap-4 text-xs text-slate-500">
						<span class="inline-flex items-center gap-1"><Users size={13} /> {s._count.enrollments} enrolled</span>
						<span class="inline-flex items-center gap-1"><Target size={13} /> {fmt(s._count.contributions)} contributions</span>
					</div>
				</div>

				<!-- Right: actions -->
				<div class="flex flex-col items-end gap-2">
					<a href="/global-sadhana/{s.id}/edit" class="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm text-slate-700 hover:bg-slate-50 transition-colors">
						<Pencil size={13} /> Edit
					</a>

					{#if s.status === 'published' || s.status === 'paused'}
						<form method="POST" action="?/setStatus" use:enhance={({ cancel }) => { return async ({ update }) => update({ reset: false }); }}>
							<input type="hidden" name="id" value={s.id} />
							<input type="hidden" name="status" value="active" />
							<button type="submit" class="inline-flex items-center gap-1.5 rounded-lg border border-green-300 bg-green-50 px-3 py-1.5 text-sm text-green-700 hover:bg-green-100 transition-colors">
								<Play size={13} /> Activate
							</button>
						</form>
					{/if}

					{#if s.status === 'active'}
						<form method="POST" action="?/setStatus" use:enhance={({ cancel }) => { return async ({ update }) => update({ reset: false }); }}>
							<input type="hidden" name="id" value={s.id} />
							<input type="hidden" name="status" value="paused" />
							<button type="submit" class="inline-flex items-center gap-1.5 rounded-lg border border-amber-300 bg-amber-50 px-3 py-1.5 text-sm text-amber-700 hover:bg-amber-100 transition-colors">
								<Pause size={13} /> Pause
							</button>
						</form>
					{/if}

					{#if !['archived', 'completed'].includes(s.status)}
						<form method="POST" action="?/setStatus" use:enhance={({ cancel }) => { return async ({ update }) => update({ reset: false }); }}>
							<input type="hidden" name="id" value={s.id} />
							<input type="hidden" name="status" value="archived" />
							<button type="submit" class="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-3 py-1.5 text-xs text-slate-500 hover:bg-slate-50 transition-colors">
								<Archive size={13} /> Archive
							</button>
						</form>
					{/if}
				</div>
			</div>
		</div>
	{/each}
</div>

<!-- Delete confirm dialog (hidden by default) -->
{#if confirmDeleteId}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
		<div class="bg-white rounded-2xl shadow-xl max-w-sm w-full p-6">
			<h2 class="text-lg font-semibold text-slate-900">Delete Global Sadhana?</h2>
			<p class="mt-2 text-sm text-slate-600">This permanently removes the sadhana and all enrollments and contributions. This cannot be undone.</p>
			<div class="mt-5 flex gap-3 justify-end">
				<button onclick={() => confirmDeleteId = null} class="btn-secondary text-sm">Cancel</button>
				<form method="POST" action="?/delete" use:enhance={() => {
					deleting = true;
					return async ({ result, update }) => {
						await update();
						deleting = false;
						confirmDeleteId = null;
						if (result.type === 'redirect') toasts.show('Sadhana deleted');
					};
				}}>
					<input type="hidden" name="id" value={confirmDeleteId} />
					<button type="submit" disabled={deleting} class="inline-flex items-center gap-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-60 transition-colors">
						<Trash2 size={15} /> {deleting ? 'Deleting…' : 'Delete'}
					</button>
				</form>
			</div>
		</div>
	</div>
{/if}
