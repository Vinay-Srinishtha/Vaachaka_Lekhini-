import type { RequestHandler } from './$types';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';

const schema = z.object({
	mobile: z
		.string()
		.regex(/^(\+91)?[6-9]\d{9}$/, 'Invalid Indian mobile number')
		.transform((m) => m.replace(/^\+91/, ''))
});

/// POST /api/v1/auth/check  { mobile }
/// Returns { exists: bool } — whether an active account exists for this number.
export const POST: RequestHandler = async (event) => {
	const body = await readJsonBody(event, schema);
	const account = await prisma.account.findUnique({
		where: { mobile: body.mobile },
		select: { id: true, isBanned: true }
	});
	return snakeJson({ exists: account !== null && !account.isBanned });
};
