import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { issueTokensFor, verifyAccountPassword } from '$lib/server/user-auth';
import { prisma } from '$lib/server/prisma';

const schema = z.object({
	mobile: z.string().regex(/^\d{10,12}$/),
	password: z.string().min(1)
});

/// POST /api/v1/auth/password/login  { mobile, password }
/// → 200 { access_token, refresh_token, account, primary_member }
export const POST: RequestHandler = async (event) => {
	const body = await readJsonBody(event, schema);
	const account = await verifyAccountPassword(body.mobile, body.password);
	if (!account) throw error(401, 'Invalid mobile or password');
	if (account.isBanned) throw error(403, 'Account is banned');

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
