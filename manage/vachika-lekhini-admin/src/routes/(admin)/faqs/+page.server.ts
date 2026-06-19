import type { PageServerLoad, Actions } from './$types';
import { error, fail, redirect } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';
import { patchQuery } from '$lib/url';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const faqs = await prisma.faq.findMany({
		orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
		select: { id: true, question: true, answer: true, sortOrder: true, isActive: true, updatedAt: true }
	});
	return { faqs };
};

export const actions: Actions = {
	toggleActive: async (event) => {
		try {
			requireRole(event, 'editor');
			const data = await event.request.formData();
			const id = String(data.get('id') ?? '');
			if (!id) return fail(400, { error: 'Missing id' });
			const current = await prisma.faq.findUnique({ where: { id }, select: { isActive: true } });
			if (!current) throw error(404, 'FAQ not found');
			await prisma.faq.update({ where: { id }, data: { isActive: !current.isActive } });
			return { ok: true };
		} catch (e) {
			console.error(e);
			return fail(500, { message: 'Internal error' });
		}
	},

	reorder: async (event) => {
		try {
			requireRole(event, 'editor');
			const data = await event.request.formData();
			const id = String(data.get('id') ?? '');
			const dir = String(data.get('dir') ?? '');
			if (!id || (dir !== 'up' && dir !== 'down')) return fail(400, { error: 'Bad request' });
			const all = await prisma.faq.findMany({
				orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
				select: { id: true, sortOrder: true }
			});
			const idx = all.findIndex((f) => f.id === id);
			if (idx < 0) return fail(404, { error: 'Not found' });
			const swapIdx = dir === 'up' ? idx - 1 : idx + 1;
			if (swapIdx < 0 || swapIdx >= all.length) return { ok: true };
			const a = all[idx], b = all[swapIdx];
			await prisma.$transaction([
				prisma.faq.update({ where: { id: a.id }, data: { sortOrder: b.sortOrder } }),
				prisma.faq.update({ where: { id: b.id }, data: { sortOrder: a.sortOrder } })
			]);
			return { ok: true };
		} catch (e) {
			console.error(e);
			return fail(500, { message: 'Internal error' });
		}
	},

	delete: async (event) => {
		try {
			requireRole(event, 'editor');
			const data = await event.request.formData();
			const id = String(data.get('id') ?? '');
			if (!id) return fail(400, { error: 'Missing id' });
			await prisma.faq.delete({ where: { id } }).catch(() => undefined);
			throw redirect(303, patchQuery(event.url, { delete: null }));
		} catch (e) {
			console.error(e);
			return fail(500, { message: 'Internal error' });
		}
	}
};
