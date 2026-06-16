import { prisma } from './prisma';
import { recomputeMemberBalance } from './sync';
import { emitChange } from './live';

// ── Default rule definitions ────────────────────────────────────────────────

const DEFAULT_RULES = [
	{
		key: 'join_bonus',
		name: 'Joining Bonus',
		description: 'Awarded once when a new account is created.',
		points: 100,
		threshold: null
	},
	{
		key: 'chant_milestone',
		name: 'Chant Milestone',
		description: 'Awarded per every N chants or writings in a session. 1 point per threshold batch.',
		points: 1,
		threshold: 11
	},
	{
		key: 'streak_week',
		name: 'Weekly Streak',
		description: 'Awarded for every 7-day continuous practice streak milestone.',
		points: 50,
		threshold: 7
	},
	{
		key: 'invite_sent',
		name: 'Referral — Inviter',
		description: 'Awarded to you when someone joins the app using your referral link or code.',
		points: 50,
		threshold: null
	},
	{
		key: 'invite_used',
		name: 'Referral — Joinee',
		description: 'Awarded to you when you join the app using someone else\'s referral link or code.',
		points: 50,
		threshold: null
	}
] as const;

/// Idempotent seed — inserts default rules if they don't already exist.
/// Never overwrites admin-edited values.
export async function seedRewardRules(): Promise<void> {
	await Promise.all(
		DEFAULT_RULES.map((r) =>
			prisma.rewardRule.upsert({
				where: { key: r.key },
				create: { ...r, threshold: r.threshold ?? undefined },
				update: {}
			})
		)
	);
}

// ── Internal helpers ────────────────────────────────────────────────────────

async function getActiveRule(key: string) {
	return prisma.rewardRule.findUnique({ where: { key } });
}

async function awardPoints(memberId: string, eventId: string, amount: number, source: string) {
	await prisma.rewardEvent.upsert({
		where: { id: eventId },
		create: { id: eventId, memberId, kind: 'earn', amount, source },
		update: {}
	});
	await recomputeMemberBalance(memberId);
	emitChange('reward_event');
}

// ── Public rule triggers ────────────────────────────────────────────────────

/// Called immediately after a new account + primary member are created.
/// Applies join_bonus, invite_used (for new member), invite_sent (for referrer).
export async function applyJoinRewards(
	primaryMemberId: string,
	referralCode: string | undefined,
	newAccountId: string
): Promise<void> {
	const [joinRule, inviteUsedRule, inviteSentRule] = await Promise.all([
		getActiveRule('join_bonus'),
		getActiveRule('invite_used'),
		getActiveRule('invite_sent')
	]);

	// 1. Join bonus for the new member
	if (joinRule?.isActive) {
		await awardPoints(
			primaryMemberId,
			`rule:join_bonus:${primaryMemberId}`,
			joinRule.points,
			'join_bonus'
		);
	}

	if (referralCode) {
		const code = referralCode.toUpperCase().replace(/-/g, '');
		const rows = await prisma.$queryRaw<{ member_id: string }[]>`
			SELECT m.id AS member_id
			FROM "Member" m
			JOIN "Account" a ON a.id = m."accountId"
			WHERE REPLACE(a.id::text, '-', '') ILIKE ${code + '%'}
			  AND m."isPrimary" = true
			  AND a.id != ${newAccountId}
			LIMIT 1
		`;
		const referrerMemberId = rows[0]?.member_id;

		// 2. Joinee bonus (I used someone's code)
		if (inviteUsedRule?.isActive) {
			await awardPoints(
				primaryMemberId,
				`rule:invite_used:${primaryMemberId}`,
				inviteUsedRule.points,
				'invite_used'
			);
		}

		// 3. Referrer bonus (they sent me the invite)
		if (referrerMemberId && inviteSentRule?.isActive) {
			await awardPoints(
				referrerMemberId,
				`rule:invite_sent:${referrerMemberId}:${newAccountId}`,
				inviteSentRule.points,
				'invite_sent'
			);
		}
	}
}

/// Called after new sessions are inserted.
/// Awards floor(countAdded / threshold) × points per session for chant_milestone rule.
export async function applySessionRewards(
	sessions: Array<{ id: string; memberId: string; countAdded: number }>
): Promise<void> {
	const rule = await getActiveRule('chant_milestone');
	if (!rule?.isActive || !rule.threshold || rule.threshold <= 0) return;

	const { threshold, points } = rule;
	const touchedMembers = new Set<string>();

	await Promise.all(
		sessions.map(async (s) => {
			const batches = Math.floor(s.countAdded / threshold);
			if (batches <= 0) return;
			const pts = batches * points;
			await prisma.rewardEvent.upsert({
				where: { id: `rule:chant_milestone:${s.id}` },
				create: {
					id: `rule:chant_milestone:${s.id}`,
					memberId: s.memberId,
					kind: 'earn',
					amount: pts,
					source: `chant_milestone (${s.countAdded} ÷ ${threshold} = ${batches} pt)`
				},
				update: {}
			});
			touchedMembers.add(s.memberId);
		})
	);

	if (touchedMembers.size > 0) {
		await Promise.all([...touchedMembers].map((id) => recomputeMemberBalance(id)));
		emitChange('reward_event');
	}
}

/// Called after streak is recomputed for a program.
/// Awards streak_week points each time currentStreak crosses a new multiple of threshold (default 7).
export async function applyStreakRewards(memberId: string, currentStreak: number): Promise<void> {
	const rule = await getActiveRule('streak_week');
	if (!rule?.isActive || currentStreak < 1) return;

	const threshold = rule.threshold ?? 7;
	if (currentStreak < threshold) return;

	const weekNumber = Math.floor(currentStreak / threshold);
	const eventId = `rule:streak_week:${memberId}:${weekNumber}`;
	await awardPoints(
		memberId,
		eventId,
		rule.points,
		`streak_week (${weekNumber * threshold} day streak)`
	);
}
