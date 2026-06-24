import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { snakeJson } from '$lib/server/snake-case';
import { prisma } from '$lib/server/prisma';

export const GET: RequestHandler = async () => {
	const tnc = await prisma.termsAndConditions.findFirst({
		where: { isActive: true }
	});
	if (!tnc) throw error(404, { code: 'not_found', message: 'No active T&C found' } as App.Error);
	return snakeJson(tnc);
};
