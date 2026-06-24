import type { PageServerLoad } from './$types';
import { requireRole } from '$lib/server/auth';
import { prisma } from '$lib/server/prisma';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'editor');
	const list = await prisma.termsAndConditions.findMany({
		orderBy: { createdAt: 'desc' },
		include: { _count: { select: { acceptances: true } } }
	});
	return { list };
};
