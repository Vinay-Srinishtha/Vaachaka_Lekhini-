import { error, isHttpError } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { otpService } from '$lib/server/otp';
import { prisma } from '$lib/server/prisma';

const schema = z.object({
	mobile: z
		.string()
		.regex(/^(\+91)?[6-9]\d{9}$/, 'Invalid Indian mobile number')
		.transform((m) => m.replace(/^\+91/, ''))
});

const MAX_ATTEMPTS = 5;
const COOLDOWN_MS = 2 * 60 * 60 * 1000; // 2 hours

/// POST /api/v1/auth/password/forgot  { mobile }
/// Sends a password-reset OTP. The code is valid for 9 minutes.
/// Once a code has expired / been used / run out of attempts, a new one can
/// only be requested 2 hours after it was issued.
///   404 account_not_found — no account for this number
///   403 account_banned    — suspended accounts cannot reset
///   429 reset_cooldown     — must wait until 2h after the last code was issued
export const POST: RequestHandler = async (event) => {
	try {
		const body = await readJsonBody(event, schema);

		const account = await prisma.account.findUnique({
			where: { mobile: body.mobile },
			select: { id: true, isBanned: true }
		});
		if (!account) {
			throw error(404, {
				code: 'account_not_found',
				message: 'No account found for this number. Please create an account first.'
			});
		}
		if (account.isBanned) {
			throw error(403, {
				code: 'account_banned',
				message: 'Your account has been suspended. Please contact support.'
			});
		}

		// Enforce the 2-hour cooldown. Look at the most recent challenge issued
		// within the last 2 hours; if it can no longer be used (expired, used, or
		// out of attempts) the user must wait out the remainder of the window.
		const recent = await prisma.otpChallenge.findFirst({
			where: { mobile: body.mobile, createdAt: { gt: new Date(Date.now() - COOLDOWN_MS) } },
			orderBy: { createdAt: 'desc' }
		});
		if (recent) {
			const exhausted =
				recent.consumedAt !== null ||
				recent.expiresAt <= new Date() ||
				recent.attempts >= MAX_ATTEMPTS;
			if (exhausted) {
				throw error(429, {
					code: 'reset_cooldown',
					message:
						'For your security, a new reset code can only be requested 2 hours after the last one. Please try again later.'
				});
			}
		}

		await otpService().start(body.mobile);
		return snakeJson({ ok: true, expiresInSeconds: 9 * 60 });
	} catch (e) {
		if (isHttpError(e)) throw e;
		console.error('[auth/password/forgot]', e);
		throw error(500, { code: 'server_error', message: 'Internal error' });
	}
};
