import { error, json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { readJsonBody } from '$lib/server/json-input';
import { verifyAccessToken } from '$lib/server/jwt';

const schema = z.object({
	subject: z.string().min(1).max(200),
	body: z.string().min(10).max(5000),
	kind: z.enum(['report', 'feedback']).default('report')
});

/// POST /api/v1/support  { subject, body }
/// Auth: optional — stores memberId/mobile if token present.
export const POST: RequestHandler = async (event) => {
	const body = await readJsonBody(event, schema);

	let memberId: string | null = null;
	let mobile: string | null = null;

	const authHeader = event.request.headers.get('Authorization');
	if (authHeader?.startsWith('Bearer ')) {
		try {
			const payload = await verifyAccessToken(authHeader.slice(7));
			const account = await prisma.account.findUnique({
				where: { id: payload.sub },
				select: { mobile: true, members: { where: { isPrimary: true }, select: { id: true }, take: 1 } }
			});
			if (account) {
				mobile = account.mobile;
				memberId = account.members[0]?.id ?? null;
			}
		} catch {
			// Token optional — ignore errors
		}
	}

	if (!body.subject.trim() || !body.body.trim()) {
		throw error(400, 'Subject and body are required');
	}

	await prisma.supportReport.create({
		data: {
			kind: body.kind,
			subject: body.subject.trim(),
			body: body.body.trim(),
			memberId,
			mobile
		}
	});

	return json({ ok: true });
};
