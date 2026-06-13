import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { otpService } from '$lib/server/otp';
import { ensureAccount, issueTokensFor } from '$lib/server/user-auth';

// Accept either raw 10-digit or +91-prefixed mobile; normalise to digits only.
const mobileSchema = z
	.string()
	.regex(/^(\+91)?[6-9]\d{9}$/, 'Invalid Indian mobile number')
	.transform((m) => m.replace(/^\+91/, ''));

const schema = z.object({
	mobile: mobileSchema,
	code: z.string().regex(/^\d{4,8}$/),
	country_code: z.string().optional(),
	/// Present on registration; absent on login.
	username: z.string().min(1).max(50).optional(),
	/// Optional 6-char referral code from an invite link. Only applied on new registrations.
	referral_code: z.string().max(10).optional()
});

/// POST /api/v1/auth/otp/verify  { mobile, code, country_code?, username?, referral_code? }
/// - username present  → registration: create account if new, then sign in.
/// - username absent   → login: account MUST already exist; 401 if not found.
export const POST: RequestHandler = async (event) => {
	const body = await readJsonBody(event, schema);

	const result = await otpService().verify(body.mobile, body.code);
	if (!result.ok) throw error(401, result.error);

	let account;
	let isNewAccount = false;

	if (body.username) {
		// Check if account already exists before creating so we know whether
		// to apply the referral credit.
		const existing = await prisma.account.findUnique({
			where: { mobile: body.mobile },
			select: { id: true }
		});
		isNewAccount = !existing;
		account = await ensureAccount(body.mobile, body.username, body.country_code ?? '+91');
	} else {
		// Login — refuse if account doesn't exist.
		account = await prisma.account.findUnique({
			where: { mobile: body.mobile },
			select: { id: true, mobile: true, countryCode: true, isBanned: true }
		});
		if (!account) throw error(401, 'No account found. Please register first.');
	}

	if (account.isBanned) throw error(403, 'Account is banned');

	// Credit the referrer if this is a brand-new account and a referral code was supplied.
	// The code is the first 6 hex chars of the referrer's account UUID (dashes stripped,
	// uppercased) — matching the Flutter InviteService.codeFor() logic.
	if (isNewAccount && body.referral_code) {
		const code = body.referral_code.toUpperCase().replace(/-/g, '');
		// Find the referrer's primary member via a raw query (UUID hex prefix match).
		const rows = await prisma.$queryRaw<{ member_id: string }[]>`
			SELECT m.id AS member_id
			FROM "Member" m
			JOIN "Account" a ON a.id = m."accountId"
			WHERE REPLACE(a.id::text, '-', '') ILIKE ${code + '%'}
			  AND m."isPrimary" = true
			  AND a.id != ${account.id}
			LIMIT 1
		`;
		if (rows.length > 0) {
			const referrerMemberId = rows[0].member_id;
			await prisma.rewardEvent.create({
				data: {
					id: crypto.randomUUID(),
					memberId: referrerMemberId,
					kind: 'earn',
					amount: 100,
					source: 'referral',
					occurredAt: new Date()
				}
			});
		}
	}

	const primary = await prisma.member.findFirst({
		where: { accountId: account.id, isPrimary: true },
		select: { id: true, displayName: true }
	});

	const tokens = await issueTokensFor(account.id, account.mobile);
	return snakeJson({
		...tokens,
		account: {
			id: account.id,
			mobile: account.mobile,
			countryCode: account.countryCode
		},
		primaryMember: primary
	});
};
