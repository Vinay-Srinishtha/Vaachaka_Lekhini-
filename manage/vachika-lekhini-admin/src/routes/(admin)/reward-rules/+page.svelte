<script lang="ts">
	import { enhance } from '$app/forms';
	import { Gift, Pencil, X, Check, Zap, Calendar, UserPlus, LogIn, Coins } from '@lucide/svelte';

	let { data, form } = $props();

	type Rule = (typeof data.rules)[number];

	// ── Edit state ────────────────────────────────────────────────────────────
	let editingId = $state<string | null>(null);
	let saving = $state(false);
	let savedId = $state<string | null>(null);

	// Editable fields mirror (reset each time we open a row)
	let editName = $state('');
	let editDesc = $state('');
	let editPoints = $state(0);
	let editThreshold = $state<number | null>(null);
	let editActive = $state(true);

	function openEdit(r: Rule) {
		editingId = r.id;
		editName = r.name;
		editDesc = r.description;
		editPoints = r.points;
		editThreshold = r.threshold;
		editActive = r.isActive;
	}

	function closeEdit() {
		editingId = null;
	}

	// ── Rule metadata ─────────────────────────────────────────────────────────
	const RULE_META: Record<string, { icon: typeof Gift; color: string; hint: string }> = {
		join_bonus: {
			icon: Gift,
			color: 'bg-violet-100 text-violet-700',
			hint: 'Fires once per new account.'
		},
		chant_milestone: {
			icon: Coins,
			color: 'bg-orange-100 text-orange-700',
			hint: 'Points = floor(chants ÷ threshold) per session. e.g. threshold=11 → 11 chants = 1 pt, 22 = 2 pts.'
		},
		streak_week: {
			icon: Calendar,
			color: 'bg-green-100 text-green-700',
			hint: 'Fires each time streak crosses a new multiple of threshold days.'
		},
		invite_sent: {
			icon: UserPlus,
			color: 'bg-sky-100 text-sky-700',
			hint: 'Fires for the referrer when their invitee completes registration.'
		},
		invite_used: {
			icon: LogIn,
			color: 'bg-indigo-100 text-indigo-700',
			hint: 'Fires for the new user who joined via a referral link/code.'
		}
	};

	function meta(key: string) {
		return RULE_META[key] ?? { icon: Zap, color: 'bg-slate-100 text-slate-600', hint: '' };
	}
</script>

<div class="space-y-6">
	<!-- Header -->
	<div class="flex items-start justify-between gap-4">
		<div>
			<h1 class="text-xl font-bold text-slate-900">Reward Rules</h1>
			<p class="mt-1 text-sm text-slate-500">
				Configure how users earn points. Changes take effect immediately — no redeploy needed.
			</p>
		</div>
	</div>

	{#if form?.error}
		<div class="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
			{form.error}
		</div>
	{/if}

	<!-- Rules cards -->
	<div class="grid gap-4 sm:grid-cols-1 lg:grid-cols-2 xl:grid-cols-3">
		{#each data.rules as rule (rule.id)}
			{@const m = meta(rule.key)}
			{@const isEditing = editingId === rule.id}
			{@const justSaved = savedId === rule.id}

			<div
				class="relative flex flex-col rounded-2xl border bg-white shadow-sm transition-shadow
					{isEditing ? 'border-brand-400 shadow-md ring-1 ring-brand-300' : 'border-slate-200 hover:shadow-md'}
					{!rule.isActive && !isEditing ? 'opacity-60' : ''}"
			>
				<!-- Top bar: icon + name + toggle + edit -->
				<div class="flex items-start gap-3 p-5 pb-3">
					<div class="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-xl {m.color}">
						<m.icon size={18} />
					</div>
					<div class="min-w-0 flex-1">
						{#if isEditing}
							<input
								bind:value={editName}
								class="w-full rounded-lg border border-slate-300 px-2 py-1 text-sm font-semibold text-slate-800 focus:border-brand-400 focus:outline-none"
							/>
						{:else}
							<p class="truncate text-sm font-semibold text-slate-800">{rule.name}</p>
						{/if}
						<p class="mt-0.5 text-xs text-slate-400 font-mono">{rule.key}</p>
					</div>
					<div class="flex shrink-0 items-center gap-1.5">
						{#if !isEditing}
							<!-- Active pill -->
							<span
								class="rounded-full px-2 py-0.5 text-[10px] font-semibold
									{rule.isActive ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-500'}"
							>
								{rule.isActive ? 'Active' : 'Off'}
							</span>
							<button
								onclick={() => openEdit(rule)}
								class="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors"
								title="Edit rule"
							>
								<Pencil size={14} />
							</button>
						{:else}
							<button
								onclick={closeEdit}
								class="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 transition-colors"
								title="Cancel"
							>
								<X size={14} />
							</button>
						{/if}
					</div>
				</div>

				<!-- Description -->
				<div class="px-5 pb-3">
					{#if isEditing}
						<textarea
							bind:value={editDesc}
							rows={2}
							class="w-full resize-none rounded-lg border border-slate-300 px-2 py-1.5 text-xs text-slate-600 focus:border-brand-400 focus:outline-none"
						></textarea>
					{:else}
						<p class="text-xs text-slate-500 leading-relaxed">{rule.description}</p>
					{/if}
				</div>

				<!-- Hint (non-edit only) -->
				{#if !isEditing && m.hint}
					<div class="mx-5 mb-3 rounded-lg bg-slate-50 px-3 py-2 text-[11px] text-slate-500 leading-snug">
						{m.hint}
					</div>
				{/if}

				<!-- Stats / edit fields -->
				<div class="mt-auto border-t border-slate-100 px-5 py-4">
					{#if isEditing}
						<div class="space-y-3">
							<!-- Points + Threshold row -->
							<div class="flex gap-3">
								<div class="flex-1">
									<label class="mb-1 block text-[11px] font-medium text-slate-500 uppercase tracking-wide">
										Points
									</label>
									<input
										type="number"
										min="0"
										max="100000"
										bind:value={editPoints}
										class="w-full rounded-lg border border-slate-300 px-2.5 py-1.5 text-sm font-semibold text-slate-800 focus:border-brand-400 focus:outline-none"
									/>
								</div>
								{#if rule.threshold !== null || rule.key === 'chant_milestone' || rule.key === 'streak_week'}
									<div class="flex-1">
										<label class="mb-1 block text-[11px] font-medium text-slate-500 uppercase tracking-wide">
											Threshold
										</label>
										<input
											type="number"
											min="1"
											max="10000"
											bind:value={editThreshold}
											placeholder="e.g. 11"
											class="w-full rounded-lg border border-slate-300 px-2.5 py-1.5 text-sm text-slate-800 focus:border-brand-400 focus:outline-none"
										/>
									</div>
								{/if}
							</div>

							<!-- Active toggle -->
							<label class="flex cursor-pointer items-center gap-2">
								<input
									type="checkbox"
									bind:checked={editActive}
									class="h-4 w-4 rounded border-slate-300 accent-brand-600"
								/>
								<span class="text-sm text-slate-700">Rule is active</span>
							</label>

							<!-- Save button -->
							<form
								method="POST"
								action="?/update"
								use:enhance={() => {
									saving = true;
									return async ({ update }) => {
										await update({ reset: false });
										saving = false;
										savedId = rule.id;
										editingId = null;
										setTimeout(() => (savedId = null), 2000);
									};
								}}
							>
								<input type="hidden" name="id" value={rule.id} />
								<input type="hidden" name="name" value={editName} />
								<input type="hidden" name="description" value={editDesc} />
								<input type="hidden" name="points" value={editPoints} />
								<input type="hidden" name="threshold" value={editThreshold ?? ''} />
								<input type="hidden" name="isActive" value={String(editActive)} />
								<button
									type="submit"
									disabled={saving}
									class="flex w-full items-center justify-center gap-1.5 rounded-xl bg-brand-600 px-4 py-2 text-sm font-semibold text-white
										hover:bg-brand-700 disabled:opacity-60 transition-colors"
								>
									{#if saving}
										<span class="h-3.5 w-3.5 animate-spin rounded-full border-2 border-white/30 border-t-white"></span>
										Saving…
									{:else}
										<Check size={14} />
										Save Rule
									{/if}
								</button>
							</form>
						</div>
					{:else}
						<!-- Read mode: show current values -->
						<div class="flex items-center gap-4">
							<div class="text-center">
								<p class="text-2xl font-bold text-slate-900">{rule.points}</p>
								<p class="text-[10px] text-slate-400 uppercase tracking-wide font-medium">Points</p>
							</div>
							{#if rule.threshold !== null}
								<div class="h-8 w-px bg-slate-200"></div>
								<div class="text-center">
									<p class="text-2xl font-bold text-slate-900">{rule.threshold}</p>
									<p class="text-[10px] text-slate-400 uppercase tracking-wide font-medium">Threshold</p>
								</div>
							{/if}
							{#if justSaved}
								<div class="ml-auto flex items-center gap-1 text-green-600 text-xs font-semibold">
									<Check size={13} /> Saved
								</div>
							{/if}
						</div>

						<!-- Visual example for chant rule -->
						{#if rule.key === 'chant_milestone' && rule.threshold}
							<div class="mt-3 flex flex-wrap gap-2">
								{#each [rule.threshold, rule.threshold * 2, rule.threshold * 3] as n}
									<span class="rounded-full bg-orange-50 border border-orange-200 px-2.5 py-0.5 text-[11px] text-orange-700 font-medium">
										{n} chants → {Math.floor(n / rule.threshold) * rule.points} pt{Math.floor(n / rule.threshold) * rule.points !== 1 ? 's' : ''}
									</span>
								{/each}
							</div>
						{/if}
					{/if}
				</div>
			</div>
		{/each}
	</div>

	<!-- Summary table -->
	<div class="rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden">
		<div class="border-b border-slate-100 px-5 py-4">
			<h2 class="text-sm font-semibold text-slate-700">Rules Summary</h2>
		</div>
		<table class="w-full text-sm">
			<thead>
				<tr class="border-b border-slate-100 bg-slate-50 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
					<th class="px-5 py-3">Rule</th>
					<th class="px-5 py-3">Trigger</th>
					<th class="px-5 py-3 text-right">Points</th>
					<th class="px-5 py-3 text-right">Threshold</th>
					<th class="px-5 py-3 text-center">Status</th>
				</tr>
			</thead>
			<tbody class="divide-y divide-slate-100">
				{#each data.rules as rule (rule.id)}
					{@const m = meta(rule.key)}
					<tr class="hover:bg-slate-50 transition-colors">
						<td class="px-5 py-3">
							<div class="flex items-center gap-2">
								<span class="inline-flex h-6 w-6 items-center justify-center rounded-lg {m.color}">
									<m.icon size={12} />
								</span>
								<span class="font-medium text-slate-800">{rule.name}</span>
							</div>
						</td>
						<td class="px-5 py-3 text-slate-500 font-mono text-xs">{rule.key}</td>
						<td class="px-5 py-3 text-right font-semibold text-slate-800">{rule.points}</td>
						<td class="px-5 py-3 text-right text-slate-500">
							{rule.threshold ?? '—'}
						</td>
						<td class="px-5 py-3 text-center">
							<span
								class="rounded-full px-2 py-0.5 text-[10px] font-semibold
									{rule.isActive ? 'bg-green-100 text-green-700' : 'bg-slate-100 text-slate-500'}"
							>
								{rule.isActive ? 'Active' : 'Off'}
							</span>
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>
</div>
