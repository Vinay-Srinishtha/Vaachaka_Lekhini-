import { json, type RequestHandler } from '@sveltejs/kit';
import { z } from 'zod';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { otpService } from '$lib/server/otp';
import { prisma } from '$lib/server/prisma';

const schema = z.object({
	mobile: z
		.string()
		.regex(/^(\+91)?[6-9]\d{9}$/, 'Invalid Indian mobile number')
		.transform((m) => m.replace(/^\+91/, '')),
	country_code: z.string().optional()
});

/// POST /api/v1/auth/otp/start  { mobile, country_code? }
/// Always returns 200 (we don't leak whether the number is registered).
/// Silently skips OTP delivery for banned accounts — they will get the
/// ban error on /otp/verify instead, which avoids wasting SMS credits.
export const POST: RequestHandler = async (event) => {
	try {
		const body = await readJsonBody(event, schema);

		const account = await prisma.account.findUnique({
			where: { mobile: body.mobile },
			select: { isBanned: true }
		});

		// Return a fake challengeId for banned accounts — same shape, no SMS sent.
		if (account?.isBanned) {
			return snakeJson({ challengeId: 'banned', expiresInSeconds: 300 });
		}

		const { challengeId } = await otpService().start(body.mobile);
		return snakeJson({ challengeId, expiresInSeconds: 300 });
	} catch (e) {
		console.error(e);
		return json({ error: 'Internal error' }, { status: 500 });
	}
};
