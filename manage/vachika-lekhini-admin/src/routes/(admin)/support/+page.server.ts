import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';
import { fail } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const reports = await prisma.supportReport.findMany({
		orderBy: { createdAt: 'desc' },
		take: 200
	});
	return { reports };
};

export const actions: Actions = {
	setStatus: async (event) => {
		requireRole(event, 'editor');
		const data = await event.request.formData();
		const id = data.get('id') as string;
		const status = data.get('status') as string;
		if (!id || !['open', 'resolved', 'dismissed'].includes(status)) {
			return fail(400, { error: 'Invalid input' });
		}
		await prisma.supportReport.update({ where: { id }, data: { status } });
		return { ok: true };
	}
};
