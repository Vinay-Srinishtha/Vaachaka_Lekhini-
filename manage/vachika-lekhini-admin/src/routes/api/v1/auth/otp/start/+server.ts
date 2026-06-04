import type { RequestHandler } from './$types';
import { z } from 'zod';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { otpService } from '$lib/server/otp';

const schema = z.object({
	mobile: z.string().regex(/^\d{10,12}$/, 'Mobile must be 10–12 digits'),
	country_code: z.string().optional()
});

/// POST /api/v1/auth/otp/start  { mobile, country_code? }
/// Always returns 200 (we don't leak whether the number is registered).
export const POST: RequestHandler = async (event) => {
	const body = await readJsonBody(event, schema);
	const { challengeId } = await otpService().start(body.mobile);
	return snakeJson({ challengeId, expiresInSeconds: 300 });
};
