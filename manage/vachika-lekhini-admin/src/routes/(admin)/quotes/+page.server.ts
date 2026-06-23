import type { PageServerLoad, Actions } from './$types';
import { error, fail, redirect } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';
import { patchQuery } from '$lib/url';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const q = (event.url.searchParams.get('q') ?? '').trim();

	const where = q
		? {
				OR: [
					{ textRoman: { contains: q, mode: 'insensitive' as const } },
					{ textTelugu: { contains: q, mode: 'insensitive' as const } },
					{ textDevanagari: { contains: q, mode: 'insensitive' as const } },
					{ textKannada: { contains: q, mode: 'insensitive' as const } },
					{ text: { contains: q, mode: 'insensitive' as const } },
					{ sourceRoman: { contains: q, mode: 'insensitive' as const } },
					{ sourceTelugu: { contains: q, mode: 'insensitive' as const } },
					{ slug: { contains: q, mode: 'insensitive' as const } },
					{ mantra: { nameRoman: { contains: q, mode: 'insensitive' as const } } }
				]
			}
		: {};

	const [quotes, mantras, total, totalActive, withImages, universal] = await Promise.all([
		prisma.quote.findMany({
			where,
			orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
			select: {
				id: true,
				text: true,
				source: true,
				textRoman: true,
				sourceRoman: true,
				textTelugu: true,
				sourceTelugu: true,
				textDevanagari: true,
				sourceDevanagari: true,
				textKannada: true,
				sourceKannada: true,
				imageUrl: true,
				isActive: true,
				sortOrder: true,
				slug: true,
				createdAt: true,
				mantra: { select: { id: true, nameRoman: true, nameTelugu: true, slug: true } }
			}
		}),
		prisma.mantra.findMany({
			where: { isActive: true },
			orderBy: { nameRoman: 'asc' },
			select: { id: true, slug: true, nameRoman: true, nameTelugu: true }
		}),
		prisma.quote.count(),
		prisma.quote.count({ where: { isActive: true } }),
		prisma.quote.count({ where: { imageUrl: { not: null } } }),
		prisma.quote.count({ where: { mantraId: null } })
	]);

	return { quotes, mantras, q, total, totalActive, withImages, universal };
};

export const actions: Actions = {
	toggleActive: async (event) => {
		try {
			requireRole(event, 'editor');
			const data = await event.request.formData();
			const id = String(data.get('id') ?? '');
			if (!id) return fail(400, { error: 'Missing id' });
			const current = await prisma.quote.findUnique({ where: { id }, select: { isActive: true } });
			if (!current) throw error(404, 'Quote not found');
			await prisma.quote.update({ where: { id }, data: { isActive: !current.isActive } });
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
			await prisma.quote.delete({ where: { id } }).catch(() => undefined);
			throw redirect(303, patchQuery(event.url, { delete: null }));
		} catch (e) {
			console.error(e);
			return fail(500, { message: 'Internal error' });
		}
	}
};
