import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { verifyUserToken } from '$lib/server/user-jwt';
import { prisma } from '$lib/server/prisma';

const schema = z.object({
	tnc_id: z.string().min(1)
});

export const POST: RequestHandler = async (event) => {
	try {
		const authHeader = event.request.headers.get('authorization') ?? '';
		const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
		if (!token) throw error(401, { code: 'unauthorized', message: 'Missing token' } as App.Error);

		const payload = await verifyUserToken(token, 'access');
		if (!payload) throw error(401, { code: 'unauthorized', message: 'Invalid or expired token' } as App.Error);

		const body = await readJsonBody(event, schema);

		await prisma.tncAcceptance.upsert({
			where: { accountId_tncId: { accountId: payload.sub, tncId: body.tnc_id } },
			create: { accountId: payload.sub, tncId: body.tnc_id },
			update: { acceptedAt: new Date() }
		});

		return snakeJson({ ok: true });
	} catch (e) {
		if ((e as { status?: number }).status) throw e;
		console.error('[tnc/accept POST]', e);
		throw error(500, { code: 'server_error', message: 'Internal error' } as App.Error);
	}
};
