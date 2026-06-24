import { error, isHttpError } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import { prisma } from '$lib/server/prisma';
import { issueTokensFor } from '$lib/server/user-auth';
import { snakeJson } from '$lib/server/snake-case';
import { readJsonBody } from '$lib/server/json-input';

// Fast bulk provisioning for the load simulator. Replaces N individual
// /auth/register + /programs round-trips (each doing a bcrypt hash + several
// DB queries) with: ONE bcrypt hash (all sim users share a password), a handful
// of createMany inserts, and cheap in-process JWT signing. Drops 1000-user
// provisioning from minutes to a couple of seconds.

const SIM_PASSWORD = 'SimLoad!2024';
const MOBILE_BASE = 9900000000;
const NAME_PREFIX = 'SIM_';

const schema = z.object({
	count: z.number().int().min(1).max(20000),
	start_index: z.number().int().min(0).default(0),
	mantra_id: z.string().min(1),
	// Per-program goal (chants to complete). Sessions push totals past this for
	// most users so their program is actually marked completed.
	goal: z.number().int().min(1).max(100_000_000).default(108),
	target_days: z.number().int().min(1).max(100_000).default(40),
	// Simulate a referral graph + join/referral reward points.
	referrals: z.boolean().default(true),
	// Enroll every member in the active Global Sadhana for this mantra.
	enroll_global: z.boolean().default(true)
});

// Fallback point values if a reward rule row is missing/inactive.
const DEFAULT_POINTS = { join_bonus: 100, invite_used: 50, invite_sent: 50 };

export const POST: RequestHandler = async (event) => {
	try {
		const { count, start_index, mantra_id, goal, target_days, referrals, enroll_global } = await readJsonBody(event, schema);

		const mantra = await prisma.mantra.findFirst({
			where: { OR: [{ slug: mantra_id }, { id: mantra_id }] },
			select: { id: true }
		});
		if (!mantra) throw error(400, { code: 'unknown_mantra', message: 'Unknown mantra_id' });
		const mantraId = mantra.id;

		const indices = Array.from({ length: count }, (_, k) => start_index + k);
		const mobiles = indices.map((i) => String(MOBILE_BASE + i));

		const passwordHash = await bcrypt.hash(SIM_PASSWORD, 10);
		const now = new Date();

		// 1) Create any missing accounts. Re-query afterwards so we always link
		//    members to the AUTHORITATIVE account id (skipDuplicates can silently
		//    drop a row whose mobile already exists, which would orphan a member).
		const preAccounts = await prisma.account.findMany({
			where: { mobile: { in: mobiles } },
			select: { mobile: true }
		});
		const haveMobile = new Set(preAccounts.map((a) => a.mobile));
		const newAccounts = mobiles
			.filter((m) => !haveMobile.has(m))
			.map((mobile) => ({ id: crypto.randomUUID(), mobile, countryCode: '+91', passwordHash, passwordSetAt: now }));
		if (newAccounts.length) await prisma.account.createMany({ data: newAccounts, skipDuplicates: true });

		// 2) Authoritative mobile → account id, with current primary member.
		const accounts = await prisma.account.findMany({
			where: { mobile: { in: mobiles } },
			select: { id: true, mobile: true, members: { where: { isPrimary: true }, select: { id: true } } }
		});
		const byMobile = new Map(accounts.map((a) => [a.mobile, a]));

		// 3) Create a primary member for any account missing one.
		const newMembers: { id: string; accountId: string; displayName: string; relation: 'self'; isPrimary: boolean }[] = [];
		const resolved: { index: number; mobile: string; accountId: string; memberId: string }[] = [];
		for (const i of indices) {
			const mobile = String(MOBILE_BASE + i);
			const ex = byMobile.get(mobile);
			if (!ex) continue; // should not happen after the insert above
			if (ex.members[0]) {
				resolved.push({ index: i, mobile, accountId: ex.id, memberId: ex.members[0].id });
			} else {
				const memberId = crypto.randomUUID();
				newMembers.push({ id: memberId, accountId: ex.id, displayName: `${NAME_PREFIX}${i}`, relation: 'self', isPrimary: true });
				resolved.push({ index: i, mobile, accountId: ex.id, memberId });
			}
		}
		if (newMembers.length) await prisma.member.createMany({ data: newMembers, skipDuplicates: true });

		// 4) One never-completing program per member for this mantra (skip if present).
		const memberIds = resolved.map((r) => r.memberId);
		const existingPrograms = await prisma.program.findMany({
			where: { memberId: { in: memberIds }, mantraId },
			select: { id: true, memberId: true }
		});
		const progByMember = new Map(existingPrograms.map((p) => [p.memberId, p.id]));
		const newPrograms: { id: string; memberId: string; mantraId: string; targetWritings: number; targetDays: number; startedAt: Date }[] = [];
		for (const r of resolved) {
			if (!progByMember.has(r.memberId)) {
				const pid = crypto.randomUUID();
				newPrograms.push({ id: pid, memberId: r.memberId, mantraId, targetWritings: goal, targetDays: target_days, startedAt: now });
				progByMember.set(r.memberId, pid);
			}
		}
		if (newPrograms.length) await prisma.program.createMany({ data: newPrograms, skipDuplicates: true });

		// ── Referral graph + join/referral reward points ──────────────────────
		// Roles: ~20% referrers, ~45% referees (each linked to a random
		// referrer), the rest normal. Everyone gets a join bonus; referees +
		// referrers also get referral points. All rows are idempotent (stable
		// ids) so re-runs never double-credit.
		const roles = new Map<number, 'referrer' | 'referee' | 'normal'>();
		if (referrals && resolved.length > 0) {
			const rules = await prisma.rewardRule.findMany({
				where: { key: { in: ['join_bonus', 'invite_used', 'invite_sent'] } },
				select: { key: true, points: true, isActive: true }
			});
			const pts = (k: keyof typeof DEFAULT_POINTS) => {
				const r = rules.find((x) => x.key === k);
				return r && r.isActive ? r.points : DEFAULT_POINTS[k];
			};

			// Stable shuffle (index-based, no Math.random reliance for split sizes).
			const shuffled = [...resolved].sort((a, b) => ((a.index * 2654435761) % 1000) - ((b.index * 2654435761) % 1000));
			const nReferrer = Math.max(1, Math.floor(shuffled.length * 0.2));
			const nReferee = Math.floor(shuffled.length * 0.45);
			const referrers = shuffled.slice(0, nReferrer);
			const referees = shuffled.slice(nReferrer, nReferrer + nReferee);
			referrers.forEach((r) => roles.set(r.index, 'referrer'));
			referees.forEach((r) => roles.set(r.index, 'referee'));
			resolved.forEach((r) => { if (!roles.has(r.index)) roles.set(r.index, 'normal'); });

			const rewardRows: { id: string; memberId: string; kind: 'earn'; amount: number; source: string }[] = [];
			const invitedByUpdates: { accountId: string; referrerAccountId: string }[] = [];

			for (const r of resolved) {
				rewardRows.push({ id: `rule:join_bonus:${r.memberId}`, memberId: r.memberId, kind: 'earn', amount: pts('join_bonus'), source: 'join_bonus' });
			}
			referees.forEach((ref, i) => {
				const referrer = referrers[i % referrers.length];
				rewardRows.push({ id: `rule:invite_used:${ref.memberId}`, memberId: ref.memberId, kind: 'earn', amount: pts('invite_used'), source: 'invite_used' });
				rewardRows.push({ id: `rule:invite_sent:${referrer.memberId}:${ref.accountId}`, memberId: referrer.memberId, kind: 'earn', amount: pts('invite_sent'), source: `invite_sent:${referrer.memberId}:${ref.accountId}` });
				invitedByUpdates.push({ accountId: ref.accountId, referrerAccountId: referrer.accountId });
			});

			if (rewardRows.length) await prisma.rewardEvent.createMany({ data: rewardRows, skipDuplicates: true });

			// Link referees → referrer accounts (only where not already set).
			for (let i = 0; i < invitedByUpdates.length; i += 50) {
				const chunk = invitedByUpdates.slice(i, i + 50);
				await Promise.all(chunk.map((u) =>
					prisma.account.updateMany({ where: { id: u.accountId, invitedById: null }, data: { invitedById: u.referrerAccountId } })
				));
			}
		}

		// ── Enroll everyone in the active Global Sadhana for this mantra ───────
		let enrolled = 0;
		let activeSadhanaId: string | null = null;
		if (enroll_global) {
			const sadhana = await prisma.globalSadhana.findFirst({
				where: { mantraId, status: 'active' },
				select: { id: true }
			});
			if (sadhana) {
				activeSadhanaId = sadhana.id;
				const enrollRows = resolved.map((r) => ({ id: crypto.randomUUID(), globalSadhanaId: sadhana.id, memberId: r.memberId }));
				const res = await prisma.globalSadhanaEnrollment.createMany({ data: enrollRows, skipDuplicates: true });
				enrolled = res.count;
			}
		}

		// ── Recompute denormalised balances for all sim members in one query ──
		if (memberIds.length > 0) {
			const idList = memberIds.map((id) => `'${id}'`).join(',');
			await prisma.$executeRawUnsafe(
				`UPDATE "Member" m SET "rewardPointsBalance" = COALESCE((
					SELECT SUM(CASE WHEN e.kind = 'spend' THEN -e.amount ELSE e.amount END)
					FROM "RewardEvent" e WHERE e."memberId" = m.id), 0)
				 WHERE m.id IN (${idList})`
			);
		}

		// Cheap HMAC token signing (no DB, no bcrypt) — parallelised.
		const users = await Promise.all(
			resolved.map(async (r) => {
				const t = await issueTokensFor(r.accountId, r.mobile);
				return {
					index: r.index,
					mobile: r.mobile,
					account_id: r.accountId,
					member_id: r.memberId,
					program_id: progByMember.get(r.memberId),
					role: roles.get(r.index) ?? 'normal',
					access_token: t.access_token
				};
			})
		);

		return snakeJson({
			provisioned: users.length,
			created_accounts: newAccounts.length,
			created_programs: newPrograms.length,
			enrolled_global: enrolled,
			active_sadhana_id: activeSadhanaId,
			referrals_enabled: referrals,
			mantra_id: mantraId,
			users
		});
	} catch (e) {
		if (isHttpError(e)) throw e;
		console.error('[sim/provision]', e);
		throw error(500, { code: 'server_error', message: 'Bulk provision failed' });
	}
};
