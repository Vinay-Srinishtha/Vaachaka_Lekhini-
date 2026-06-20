import { error, isHttpError } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { otpService } from '$lib/server/otp';
import { issueTokensFor, setAccountPassword } from '$lib/server/user-auth';
import { prisma } from '$lib/server/prisma';

const schema = z.object({
	mobile: z
		.string()
		.regex(/^(\+91)?[6-9]\d{9}$/, 'Invalid Indian mobile number')
		.transform((m) => m.replace(/^\+91/, '')),
	code: z.string().regex(/^\d{4,8}$/, 'Enter the code from your SMS'),
	new_password: z.string().min(8, 'Password must be at least 8 characters').max(200)
});

/// POST /api/v1/auth/password/reset  { mobile, code, new_password }
/// Verifies the reset OTP, sets the new password, and signs the user in.
///   404 account_not_found — no account for this number
///   401 invalid_otp        — wrong / expired / used code
export const POST: RequestHandler = async (event) => {
	try {
		const body = await readJsonBody(event, schema);

		const account = await prisma.account.findUnique({
			where: { mobile: body.mobile },
			select: { id: true, mobile: true, countryCode: true, isBanned: true }
		});
		if (!account) {
			throw error(404, {
				code: 'account_not_found',
				message: 'No account found for this number.'
			});
		}
		if (account.isBanned) {
			throw error(403, {
				code: 'account_banned',
				message: 'Your account has been suspended. Please contact support.'
			});
		}

		const result = await otpService().verify(body.mobile, body.code);
		if (!result.ok) {
			throw error(401, { code: 'invalid_otp', message: result.error });
		}

		await setAccountPassword(account.id, body.new_password);

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
	} catch (e) {
		if (isHttpError(e)) throw e;
		console.error('[auth/password/reset]', e);
		throw error(500, { code: 'server_error', message: 'Internal error' });
	}
};
