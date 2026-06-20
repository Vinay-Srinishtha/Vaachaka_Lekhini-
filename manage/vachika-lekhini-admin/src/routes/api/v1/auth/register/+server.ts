import { error, isHttpError } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { ensureAccount, issueTokensFor, setAccountPassword } from '$lib/server/user-auth';
import { prisma } from '$lib/server/prisma';

const schema = z.object({
	mobile: z
		.string()
		.regex(/^(\+91)?[6-9]\d{9}$/, 'Invalid Indian mobile number')
		.transform((m) => m.replace(/^\+91/, '')),
	username: z.string().min(1).max(50),
	password: z.string().min(8, 'Password must be at least 8 characters').max(200),
	country_code: z.string().optional(),
	referral_code: z.string().max(10).optional()
});

/// POST /api/v1/auth/register  { mobile, username, password, country_code?, referral_code? }
/// Password-only signup — NO OTP. Creates a new account + primary member and
/// sets the password, then signs the user in.
/// - 409 account_exists if the number already has an account (log in instead).
export const POST: RequestHandler = async (event) => {
	try {
		const body = await readJsonBody(event, schema);

		const existing = await prisma.account.findUnique({
			where: { mobile: body.mobile },
			select: { id: true }
		});
		if (existing) {
			throw error(409, {
				code: 'account_exists',
				message: 'An account already exists for this number. Please log in instead.'
			} as App.Error);
		}

		const account = await ensureAccount(
			body.mobile,
			body.username,
			body.country_code ?? '+91'
		);
		await setAccountPassword(account.id, body.password);

		const primary = await prisma.member.findFirst({
			where: { accountId: account.id, isPrimary: true },
			select: { id: true, displayName: true }
		});

		const tokens = await issueTokensFor(account.id, account.mobile);

		// Fire join rewards asynchronously — never blocks the auth response.
		if (primary) {
			import('$lib/server/reward-rules')
				.then(({ applyJoinRewards }) =>
					applyJoinRewards(primary.id, body.referral_code, account.id)
				)
				.catch(() => {});
		}

		return snakeJson({
			...tokens,
			account: {
				id: account.id,
				mobile: account.mobile,
				countryCode: account.countryCode
			},
			primaryMember: primary
		});
	} catch (e) {
		if (isHttpError(e)) throw e;
		console.error('[auth/register]', e);
		throw error(500, { code: 'server_error', message: 'Internal error' } as App.Error);
	}
};
