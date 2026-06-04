import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { otpService } from '$lib/server/otp';
import { ensureAccount, issueTokensFor } from '$lib/server/user-auth';

const schema = z.object({
	mobile: z.string().regex(/^\d{10,12}$/),
	code: z.string().regex(/^\d{4,8}$/),
	country_code: z.string().optional()
});

/// POST /api/v1/auth/otp/verify  { mobile, code, country_code? }
/// → 200 { access_token, refresh_token, account: { id, mobile, ... }, primary_member_id }
export const POST: RequestHandler = async (event) => {
	const body = await readJsonBody(event, schema);

	const result = await otpService().verify(body.mobile, body.code);
	if (!result.ok) throw error(401, result.error);

	const account = await ensureAccount(body.mobile, body.country_code ?? '+91');
	if (account.isBanned) throw error(403, 'Account is banned');

	// Pull the primary member so the client can land on the right profile.
	const { prisma } = await import('$lib/server/prisma');
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
