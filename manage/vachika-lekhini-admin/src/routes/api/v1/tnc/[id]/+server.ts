import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { requireRole } from '$lib/server/auth';
import { prisma } from '$lib/server/prisma';

const updateSchema = z.object({
	version: z.string().min(1).max(20).optional(),
	title: z.string().min(1).max(200).optional(),
	content: z.string().min(1).optional(),
	effective_at: z.string().datetime().optional()
});

export const PUT: RequestHandler = async (event) => {
	try {
		requireRole(event, 'editor');
		const { id } = event.params;
		const body = await readJsonBody(event, updateSchema);
		const tnc = await prisma.termsAndConditions.update({
			where: { id },
			data: {
				...(body.version ? { version: body.version } : {}),
				...(body.title ? { title: body.title } : {}),
				...(body.content ? { content: body.content } : {}),
				...(body.effective_at ? { effectiveAt: new Date(body.effective_at) } : {})
			}
		});
		return snakeJson(tnc);
	} catch (e) {
		if ((e as { status?: number }).status) throw e;
		console.error('[tnc PUT]', e);
		throw error(500, { code: 'server_error', message: 'Internal error' } as App.Error);
	}
};

export const DELETE: RequestHandler = async (event) => {
	try {
		requireRole(event, 'editor');
		const { id } = event.params;
		const tnc = await prisma.termsAndConditions.findUnique({ where: { id }, select: { isActive: true } });
		if (!tnc) throw error(404, { code: 'not_found', message: 'T&C not found' } as App.Error);
		if (tnc.isActive) throw error(400, { code: 'cannot_delete_active', message: 'Cannot delete the active T&C. Activate another version first.' } as App.Error);
		await prisma.termsAndConditions.delete({ where: { id } });
		return new Response(null, { status: 204 });
	} catch (e) {
		if ((e as { status?: number }).status) throw e;
		console.error('[tnc DELETE]', e);
		throw error(500, { code: 'server_error', message: 'Internal error' } as App.Error);
	}
};
