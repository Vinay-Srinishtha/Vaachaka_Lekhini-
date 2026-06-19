import type { PageServerLoad, Actions } from './$types';
import { error, fail, redirect } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');

	const [sadhanas, mantras] = await Promise.all([
		prisma.globalSadhana.findMany({
			orderBy: [{ status: 'asc' }, { startAt: 'desc' }],
			select: {
				id: true,
				title: true,
				status: true,
				participationMode: true,
				targetCount: true,
				currentCount: true,
				startAt: true,
				endAt: true,
				isSponsored: true,
				completedAt: true,
				mantra: { select: { nameRoman: true, nameTelugu: true, slug: true } },
				_count: { select: { enrollments: true, contributions: true } }
			}
		}),
		prisma.mantra.findMany({
			where: { isActive: true },
			orderBy: { nameRoman: 'asc' },
			select: { id: true, slug: true, nameRoman: true, nameTelugu: true }
		})
	]);

	return { sadhanas, mantras };
};

export const actions: Actions = {
	setStatus: async (event) => {
		requireRole(event, 'editor');
		const data = await event.request.formData();
		const id = String(data.get('id') ?? '');
		const status = String(data.get('status') ?? '');
		const allowed = ['draft', 'published', 'active', 'paused', 'archived'];
		if (!id || !allowed.includes(status)) return fail(400, { error: 'Invalid params' });
		const sadhana = await prisma.globalSadhana.findUnique({ where: { id }, select: { status: true } });
		if (!sadhana) throw error(404, 'Not found');
		const completedAt = status === 'completed' ? new Date() : undefined;
		await prisma.globalSadhana.update({ where: { id }, data: { status: status as never, ...(completedAt ? { completedAt } : {}) } });
		return { ok: true };
	},

	delete: async (event) => {
		requireRole(event, 'editor');
		const data = await event.request.formData();
		const id = String(data.get('id') ?? '');
		if (!id) return fail(400, { error: 'Missing id' });
		await prisma.globalSadhana.delete({ where: { id } }).catch(() => undefined);
		throw redirect(303, '/global-sadhana');
	}
};
