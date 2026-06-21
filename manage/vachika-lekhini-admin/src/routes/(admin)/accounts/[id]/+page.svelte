<script lang="ts">
	import { ArrowLeft, User, Smartphone, Star } from '@lucide/svelte';
	import { page } from '$app/state';

	let { data } = $props();
	const a = $derived(data.account);

	function fmt(d: Date | string | null) {
		if (!d) return '—';
		return new Date(d).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });
	}

	const relationLabel: Record<string, string> = {
		self: 'Self',
		spouse: 'Spouse',
		parent: 'Parent',
		child: 'Child',
		sibling: 'Sibling',
		friend: 'Friend',
		other: 'Other'
	};

	const genderLabel: Record<string, string> = {
		male: 'Male',
		female: 'Female',
		other: 'Other',
		prefer_not_to_say: 'Prefer not to say'
	};

	// Aggregate a member's handwriting samples by mantra (count + modes used).
	function hwByMantra(samples: { mode: string; mantra: { nameRoman: string } | null }[]) {
		const map = new Map<string, { count: number; modes: Set<string> }>();
		for (const s of samples) {
			const k = s.mantra?.nameRoman ?? '—';
			const e = map.get(k) ?? { count: 0, modes: new Set<string>() };
			e.count++;
			e.modes.add(s.mode);
			map.set(k, e);
		}
		return [...map.entries()].map(([mantra, e]) => ({
			mantra,
			count: e.count,
			modes: [...e.modes]
		}));
	}

	type MemberAddress = {
		id: string;
		type: 'home' | 'work' | 'other';
		line1: string;
		line2?: string;
		city: string;
		state: string;
		pincode: string;
		country?: string;
	};

	function addresses(p: unknown): MemberAddress[] {
		if (!p || typeof p !== 'object') return [];
		const prefs = p as Record<string, unknown>;
		const list = prefs['addresses'];
		if (!Array.isArray(list)) return [];
		return list as MemberAddress[];
	}

	const typeLabel: Record<string, string> = { home: 'Home', work: 'Work', other: 'Other' };
	const typeIcon: Record<string, string> = { home: '🏠', work: '🏢', other: '📍' };
</script>

<a
	href={`/accounts?${page.url.searchParams.toString()}`}
	class="inline-flex items-center gap-1 text-sm text-gray-600 hover:text-brand-700 mb-4"
>
	<ArrowLeft size={16} /> All accounts
</a>

<header class="mb-6 flex items-start justify-between gap-3">
	<div>
		<h1 class="text-xl md:text-2xl font-bold text-gray-900">{a.countryCode} {a.mobile}</h1>
		<p class="text-sm text-gray-500 mt-1">
			{a._count.members} {a._count.members === 1 ? 'member' : 'members'} ·
			{a.passwordSetAt ? 'OTP + password' : 'OTP only'} ·
			joined {fmt(a.createdAt)}
		</p>
	</div>
	{#if a.isBanned}
		<span class="chip bg-red-100 text-red-700">banned</span>
	{:else}
		<span class="chip bg-green-100 text-green-700">active</span>
	{/if}
</header>

<section class="mb-8 space-y-3">
	<h2 class="text-sm font-semibold text-gray-700 uppercase tracking-wide">Account</h2>
	<div class="card p-4 grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
		<div>
			<div class="text-[10px] text-gray-500 uppercase tracking-wide">Mobile</div>
			<div class="font-medium text-gray-900">{a.countryCode} {a.mobile}</div>
		</div>
		<div>
			<div class="text-[10px] text-gray-500 uppercase tracking-wide">Auth</div>
			<div class="font-medium text-gray-900">{a.passwordSetAt ? 'OTP + password' : 'OTP only'}</div>
		</div>
		<div>
			<div class="text-[10px] text-gray-500 uppercase tracking-wide">Referral code</div>
			<div class="font-medium text-gray-900">{a.referralCode ?? '—'}</div>
		</div>
		<div>
			<div class="text-[10px] text-gray-500 uppercase tracking-wide">Invited by</div>
			<div class="font-medium text-gray-900">
				{a.invitedBy ? `${a.invitedBy.countryCode} ${a.invitedBy.mobile}` : 'Direct'}
			</div>
		</div>
		<div>
			<div class="text-[10px] text-gray-500 uppercase tracking-wide">Referrals made</div>
			<div class="font-medium text-gray-900">{a._count.referrals}</div>
		</div>
		<div>
			<div class="text-[10px] text-gray-500 uppercase tracking-wide">Members</div>
			<div class="font-medium text-gray-900">{a._count.members}</div>
		</div>
		<div>
			<div class="text-[10px] text-gray-500 uppercase tracking-wide">Joined</div>
			<div class="font-medium text-gray-900">{fmt(a.createdAt)}</div>
		</div>
		<div>
			<div class="text-[10px] text-gray-500 uppercase tracking-wide">Last seen</div>
			<div class="font-medium text-gray-900">{fmt(a.lastSeenAt)}</div>
		</div>
		{#if a.isBanned}
			<div class="col-span-2 md:col-span-4">
				<div class="text-[10px] text-gray-500 uppercase tracking-wide">Banned reason</div>
				<div class="font-medium text-red-700">{a.bannedReason ?? '—'}</div>
			</div>
		{/if}
	</div>
</section>

<section class="space-y-4">
	<h2 class="text-sm font-semibold text-gray-700 uppercase tracking-wide">Family members</h2>
	<div class="grid grid-cols-1 md:grid-cols-2 gap-3">
		{#each a.members as m (m.id)}
			{@const metrics = data.memberMetrics.find((x: { memberId: string }) => x.memberId === m.id)}
			{@const hw = hwByMantra(m.handwritingSamples)}
			<div class="card p-4">
				<div class="flex items-start gap-3">
					<div class="w-10 h-10 rounded-full bg-brand-100 text-brand-700 grid place-items-center font-bold">
						{m.displayName.slice(0, 1).toUpperCase()}
					</div>
					<div class="flex-1 min-w-0">
						<div class="flex items-center gap-2">
							<div class="font-medium text-gray-900 truncate">{m.displayName}</div>
							{#if m.isPrimary}
								<span class="chip bg-amber-100 text-amber-700 inline-flex items-center gap-1">
									<Star size={10} /> primary
								</span>
							{/if}
						</div>
						<div class="text-xs text-gray-500 mt-0.5">
							{relationLabel[m.relation] ?? m.relation} · App: {m.language} · Mantra: {m.mantraLanguage}
						</div>
						<div class="mt-3 grid grid-cols-3 gap-2 text-center">
							<div>
								<div class="text-base font-semibold text-gray-900">{m._count.programs}</div>
								<div class="text-[10px] text-gray-500 uppercase tracking-wide">Programs</div>
							</div>
							<div>
								<div class="text-base font-semibold text-gray-900">{m._count.sessions}</div>
								<div class="text-[10px] text-gray-500 uppercase tracking-wide">Sessions</div>
							</div>
							<div>
								<div class="text-base font-semibold text-gray-900">{m.rewardPointsBalance}</div>
								<div class="text-[10px] text-gray-500 uppercase tracking-wide">Points</div>
							</div>
						</div>
						{#if metrics}
						<div class="mt-2 grid grid-cols-3 gap-2 text-center border-t border-gray-100 pt-2">
							<div>
								<div class="text-sm font-semibold text-indigo-700">{metrics.totalChantCount.toLocaleString()}</div>
								<div class="text-[10px] text-gray-500 uppercase tracking-wide">Total Chants</div>
							</div>
							<div>
								<div class="text-sm font-semibold text-indigo-700">{metrics.voiceSampleCount}</div>
								<div class="text-[10px] text-gray-500 uppercase tracking-wide">Voice Samples</div>
							</div>
							<div>
								<div class="text-sm font-semibold text-indigo-700">{metrics.handwritingSampleCount}</div>
								<div class="text-[10px] text-gray-500 uppercase tracking-wide">HW Samples</div>
							</div>
						</div>
						{/if}

						<!-- Full profile collected from the user -->
						<div class="mt-3 border-t border-gray-100 pt-2 grid grid-cols-2 gap-x-3 gap-y-1 text-xs">
							<div><span class="text-gray-500">Gender:</span> <span class="text-gray-800">{m.gender ? (genderLabel[m.gender] ?? m.gender) : '—'}</span></div>
							<div><span class="text-gray-500">Birth year:</span> <span class="text-gray-800">{m.birthYear ?? '—'}</span></div>
							<div><span class="text-gray-500">Mother tongue:</span> <span class="text-gray-800">{m.motherTongue ?? '—'}</span></div>
							<div><span class="text-gray-500">Relation:</span> <span class="text-gray-800">{relationLabel[m.relation] ?? m.relation}</span></div>
							<div><span class="text-gray-500">Profile done:</span> <span class="text-gray-800">{m.profileCompletedAt ? fmt(m.profileCompletedAt) : 'No'}</span></div>
							<div><span class="text-gray-500">Joined:</span> <span class="text-gray-800">{fmt(m.createdAt)}</span></div>
							<div><span class="text-gray-500">Last active:</span> <span class="text-gray-800">{fmt(m.lastActiveAt)}</span></div>
							<div><span class="text-gray-500">Longest streak:</span> <span class="text-gray-800">{Math.max(0, ...m.programs.map((p: { longestStreak: number }) => p.longestStreak), 0)}</span></div>
						</div>

						<!-- Addresses -->
						{#if addresses(m.preferences).length > 0}
							<div class="mt-2 text-xs">
								<div class="text-gray-500 mb-1">Addresses</div>
								<div class="space-y-1">
									{#each addresses(m.preferences) as addr (addr.id)}
										<div class="rounded-md border border-gray-100 bg-gray-50 px-3 py-2">
											<span class="font-semibold text-gray-800">{typeIcon[addr.type] ?? '📍'} {typeLabel[addr.type] ?? addr.type}</span>
											<div class="text-gray-600 mt-0.5">
												{addr.line1}{addr.line2 ? ', ' + addr.line2 : ''}, {addr.city}, {addr.state} – {addr.pincode}
											</div>
										</div>
									{/each}
								</div>
							</div>
						{/if}

						<!-- Voice training per mantra -->
						{#if m.voiceEnrolments.length > 0}
							<div class="mt-2 text-xs">
								<div class="text-gray-500 mb-0.5">Voice trained</div>
								{#each m.voiceEnrolments as v (v.mantra?.nameRoman)}
									<div class="text-gray-800">
										{v.mantra?.nameRoman ?? '—'} · {v.sampleCount} samples{v.qualityScore != null ? ` · q ${(v.qualityScore).toFixed(2)}` : ''}
									</div>
								{/each}
							</div>
						{/if}

						<!-- Handwriting per mantra -->
						{#if hw.length > 0}
							<div class="mt-2 text-xs">
								<div class="text-gray-500 mb-0.5">Handwriting</div>
								{#each hw as h (h.mantra)}
									<div class="text-gray-800">{h.mantra} · {h.count} samples · {h.modes.join(', ')}</div>
								{/each}
							</div>
						{/if}

						<!-- Programs -->
						{#if m.programs.length > 0}
							<div class="mt-2 text-xs">
								<div class="text-gray-500 mb-0.5">Programs</div>
								{#each m.programs as p (p.id)}
									<div class="text-gray-800">
										{p.mantra?.nameRoman ?? '—'} · {(p.totalChants + p.totalWritings).toLocaleString()}{p.targetWritings > 0 ? ` / ${p.targetWritings.toLocaleString()}` : ' (no goal)'} · streak {p.currentStreak}{p.completedAt ? ' · ✓ done' : ''}
									</div>
								{/each}
							</div>
						{/if}
					</div>
				</div>
			</div>
		{/each}
	</div>
</section>

<section class="mt-8 space-y-3">
	<h2 class="text-sm font-semibold text-gray-700 uppercase tracking-wide">Recent sessions</h2>
	<div class="card overflow-hidden">
		{#if data.recentSessions.length === 0}
			<div class="px-5 py-10 text-center text-sm text-gray-500">No sessions yet.</div>
		{:else}
			<ul class="divide-y divide-gray-100">
				{#each data.recentSessions as s (s.id)}
					<li class="px-5 py-3 flex items-center justify-between gap-3">
						<div class="min-w-0">
							<div class="text-sm font-medium text-gray-900 truncate">
								{s.member.displayName} · {s.program.mantra.nameRoman}
							</div>
							<div class="text-xs text-gray-500">{fmt(s.startedAt)} · {s.modality} · {s.durationSec}s</div>
						</div>
						<div class="text-sm font-semibold text-brand-700 tabular-nums">+{s.countAdded}</div>
					</li>
				{/each}
			</ul>
		{/if}
	</div>
</section>

<section class="mt-8 space-y-3">
	<h2 class="text-sm font-semibold text-gray-700 uppercase tracking-wide">Devices</h2>
	<div class="card overflow-hidden">
		{#if a.devices.length === 0}
			<div class="px-5 py-10 text-center text-sm text-gray-500">No devices registered.</div>
		{:else}
			<ul class="divide-y divide-gray-100">
				{#each a.devices as d (d.id)}
					<li class="px-5 py-3 flex items-center justify-between">
						<div class="flex items-center gap-3">
							<Smartphone size={16} class="text-gray-400" />
							<div>
								<div class="text-sm font-medium text-gray-900">
									{d.platform}{d.appVersion ? ` · v${d.appVersion}` : ''}
								</div>
								<div class="text-xs text-gray-500">Last seen {fmt(d.lastSeenAt)}</div>
							</div>
						</div>
						{#if d.pushToken}
							<span class="chip bg-blue-50 text-blue-700">push enabled</span>
						{/if}
					</li>
				{/each}
			</ul>
		{/if}
	</div>
</section>
