import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { verifyUserToken } from '$lib/server/user-jwt';
import { issueTokensFor } from '$lib/server/user-auth';
import { prisma } from '$lib/server/prisma';

const schema = z.object({ refresh_token: z.string().min(1) });

/// POST /api/v1/auth/refresh  { refresh_token } → { access_token, refresh_token, ... }
export const POST: RequestHandler = async (event) => {
	const body = await readJsonBody(event, schema);
	const payload = await verifyUserToken(body.refresh_token, 'refresh');
	if (!payload || payload.scope !== 'refresh') throw error(401, 'Invalid refresh token');

	const account = await prisma.account.findUnique({
		where: { id: payload.sub },
		select: { id: true, mobile: true, isBanned: true }
	});
	if (!account) throw error(401, 'Account no longer exists');
	if (account.isBanned) throw error(403, 'Account is banned');

	const tokens = await issueTokensFor(account.id, account.mobile);
	return snakeJson(tokens);
};
