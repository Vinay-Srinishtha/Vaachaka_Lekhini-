import { error, fail } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const report = await prisma.supportReport.findUnique({ where: { id: event.params.id } });
	if (!report || report.kind !== 'report') throw error(404, 'Report not found');
	return { report };
};

export const actions: Actions = {
	setStatus: async (event) => {
		requireRole(event, 'editor');
		const data = await event.request.formData();
		const status = data.get('status') as string;
		if (!['open', 'resolved', 'dismissed'].includes(status)) {
			return fail(400, { error: 'Invalid status' });
		}
		await prisma.supportReport.update({ where: { id: event.params.id }, data: { status } });
		return { ok: true };
	}
};
