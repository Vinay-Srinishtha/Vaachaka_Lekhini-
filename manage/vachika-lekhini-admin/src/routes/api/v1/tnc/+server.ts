import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { requireRole } from '$lib/server/auth';
import { prisma } from '$lib/server/prisma';

const createSchema = z.object({
	version: z.string().min(1).max(20),
	title: z.string().min(1).max(200),
	content: z.string().min(1),
	effective_at: z.string().datetime().optional()
});

export const GET: RequestHandler = async (event) => {
	requireRole(event, 'editor');
	const list = await prisma.termsAndConditions.findMany({
		orderBy: { createdAt: 'desc' },
		include: { _count: { select: { acceptances: true } } }
	});
	return snakeJson(list);
};

export const POST: RequestHandler = async (event) => {
	try {
		requireRole(event, 'editor');
		const body = await readJsonBody(event, createSchema);
		const tnc = await prisma.termsAndConditions.create({
			data: {
				version: body.version,
				title: body.title,
				content: body.content,
				isActive: false,
				...(body.effective_at ? { effectiveAt: new Date(body.effective_at) } : {})
			}
		});
		return snakeJson(tnc, { status: 201 });
	} catch (e) {
		if ((e as { status?: number }).status) throw e;
		console.error('[tnc POST]', e);
		throw error(500, { code: 'server_error', message: 'Internal error' } as App.Error);
	}
};
