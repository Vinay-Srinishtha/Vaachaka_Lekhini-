<script lang="ts">
	import { goto } from '$app/navigation';
	import PageHeader from '$lib/components/PageHeader.svelte';
	import StatCard from '$lib/components/StatCard.svelte';
	import SearchInput from '$lib/components/SearchInput.svelte';
	import { Trophy, Flame, Hash, Activity, Users, TrendingUp } from '@lucide/svelte';

	let { data } = $props();

	const BOARDS = [
		{ key: 'progress', label: 'Total Progress', icon: TrendingUp,  hint: 'Chants + writings' },
		{ key: 'streak',   label: 'Longest Streak',  icon: Flame,       hint: 'All-time best streak' },
		{ key: 'sessions', label: 'Session Count',   icon: Activity,    hint: 'Total sessions completed' },
	] as const;

	type Board = typeof BOARDS[number]['key'];

	function switchBoard(b: Board) {
		const u = new URL(window.location.href);
		u.searchParams.set('board', b);
		u.searchParams.delete('q');
		goto(u.toString());
	}

	function medal(rank: number) {
		if (rank === 1) return '🥇';
		if (rank === 2) return '🥈';
		if (rank === 3) return '🥉';
		return String(rank);
	}

	function fmtMobile(m: string) {
		const d = m.replace(/\D/g, '').slice(-10);
		return d.length === 10 ? `${d.slice(0, 5)} ${d.slice(5)}` : m;
	}

	const activeBoard = $derived(BOARDS.find((b) => b.key === data.board) ?? BOARDS[0]);
</script>

<div class="space-y-6">
	<PageHeader title="Leaderboards" subtitle="Top members across practice, streaks, and sessions" />

	<!-- Summary stats -->
	<div class="grid grid-cols-2 md:grid-cols-4 gap-4">
		<StatCard label="Members"        value={data.stats.totalMembers.toLocaleString()}   icon={Users}      tone="blue"   />
		<StatCard label="Total Progress" value={data.stats.totalProgress.toLocaleString()}  icon={TrendingUp} tone="brand"  hint="chants + writings" />
		<StatCard label="Total Sessions" value={data.stats.totalSessions.toLocaleString()}  icon={Activity}   tone="purple" />
		<StatCard label="Active Streaks" value={data.stats.activeStreaks.toLocaleString()}   icon={Flame}      tone="amber"  hint="currently running" />
	</div>

	<!-- Board tabs + search -->
	<div class="card overflow-hidden">
		<div class="flex flex-col sm:flex-row sm:items-center gap-3 px-4 pt-4 pb-3 border-b border-gray-100">
			<!-- Tab pills -->
			<div class="flex gap-1 shrink-0">
				{#each BOARDS as b}
					<button
						onclick={() => switchBoard(b.key)}
						class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors
							{data.board === b.key
								? 'bg-brand-600 text-white shadow-sm'
								: 'text-gray-500 hover:bg-gray-100'}"
					>
						<b.icon size={13} />
						{b.label}
					</button>
				{/each}
			</div>

			<!-- Search -->
			<div class="flex-1 min-w-0">
				<SearchInput placeholder="Search by name…" />
			</div>
		</div>

		<!-- Table -->
		<div class="overflow-x-auto">
			<table class="w-full text-sm">
				<thead>
					<tr class="border-b border-gray-100 bg-gray-50 text-xs font-semibold uppercase tracking-wide text-gray-400">
						<th class="pl-5 pr-3 py-3 text-left w-14">Rank</th>
						<th class="px-3 py-3 text-left">Member</th>
						<th class="px-3 py-3 text-right">Total Progress</th>
						<th class="px-3 py-3 text-right">Longest Streak</th>
						<th class="px-3 py-3 text-right">Sessions</th>
						<th class="px-3 py-3 text-center">Streak</th>
					</tr>
				</thead>
				<tbody>
					{#each data.rows as row (row.memberId)}
						<tr class="border-b border-gray-50 hover:bg-gray-50/60 transition-colors">
							<!-- Rank -->
							<td class="pl-5 pr-3 py-3 font-bold text-center">
								{#if row.rank <= 3}
									<span class="text-lg leading-none">{medal(row.rank)}</span>
								{:else}
									<span class="text-gray-400 tabular-nums">{row.rank}</span>
								{/if}
							</td>

							<!-- Name + mobile -->
							<td class="px-3 py-3">
								<div class="font-medium text-gray-900 truncate max-w-[180px]">{row.name}</div>
								<div class="text-xs text-gray-400 tabular-nums">{fmtMobile(row.mobile)}</div>
							</td>

							<!-- Total progress — highlighted when board=progress -->
							<td class="px-3 py-3 text-right tabular-nums
								{data.board === 'progress' ? 'font-bold text-brand-700' : 'text-gray-700'}">
								{row.totalProgress.toLocaleString()}
							</td>

							<!-- Longest streak — highlighted when board=streak -->
							<td class="px-3 py-3 text-right tabular-nums
								{data.board === 'streak' ? 'font-bold text-amber-600' : 'text-gray-700'}">
								{row.longestStreak} days
							</td>

							<!-- Sessions — highlighted when board=sessions -->
							<td class="px-3 py-3 text-right tabular-nums
								{data.board === 'sessions' ? 'font-bold text-purple-700' : 'text-gray-700'}">
								{row.sessionCount.toLocaleString()}
							</td>

							<!-- Streak active indicator -->
							<td class="px-3 py-3 text-center">
								{#if row.streakActive}
									<span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-amber-50 text-amber-700 text-xs font-semibold">
										🔥 {row.currentStreak}d
									</span>
								{:else}
									<span class="text-gray-300 text-xs">—</span>
								{/if}
							</td>
						</tr>
					{:else}
						<tr>
							<td colspan="6" class="py-16 text-center text-gray-400 text-sm">
								{data.search ? 'No members match your search.' : 'No data yet.'}
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>

		{#if data.rows.length > 0}
			<div class="px-5 py-3 border-t border-gray-100 text-xs text-gray-400">
				Showing {data.rows.length} member{data.rows.length !== 1 ? 's' : ''}
				· sorted by <strong>{activeBoard.hint}</strong>
				· banned accounts excluded
			</div>
		{/if}
	</div>
</div>
