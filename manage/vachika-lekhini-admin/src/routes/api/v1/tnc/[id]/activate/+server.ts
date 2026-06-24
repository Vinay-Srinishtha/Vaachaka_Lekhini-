import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { snakeJson } from '$lib/server/snake-case';
import { requireRole } from '$lib/server/auth';
import { prisma } from '$lib/server/prisma';

export const POST: RequestHandler = async (event) => {
	try {
		requireRole(event, 'editor');
		const { id } = event.params;
		const existing = await prisma.termsAndConditions.findUnique({ where: { id }, select: { id: true } });
		if (!existing) throw error(404, { code: 'not_found', message: 'T&C not found' } as App.Error);

		const [, activated] = await prisma.$transaction([
			prisma.termsAndConditions.updateMany({
				where: { isActive: true, id: { not: id } },
				data: { isActive: false }
			}),
			prisma.termsAndConditions.update({
				where: { id },
				data: { isActive: true }
			})
		]);
		return snakeJson(activated);
	} catch (e) {
		if ((e as { status?: number }).status) throw e;
		console.error('[tnc/activate POST]', e);
		throw error(500, { code: 'server_error', message: 'Internal error' } as App.Error);
	}
};
