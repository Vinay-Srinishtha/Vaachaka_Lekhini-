import { fail, redirect } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'editor');
	const mantras = await prisma.mantra.findMany({
		where: { isActive: true },
		orderBy: { nameRoman: 'asc' },
		select: { id: true, slug: true, nameRoman: true, nameTelugu: true }
	});
	return { mantras };
};

export const actions: Actions = {
	default: async (event) => {
		requireRole(event, 'editor');
		const form = await event.request.formData();
		const text = String(form.get('text') ?? '').trim();
		const source = String(form.get('source') ?? '').trim() || null;
		const mantraId = String(form.get('mantra_id') ?? '').trim() || null;
		const imageUrl = String(form.get('image_url') ?? '').trim() || null;
		const sortOrder = parseInt(String(form.get('sort_order') ?? '0'), 10);
		const isActive = form.get('is_active') === 'on';

		if (!text) return fail(400, { error: 'Quote text is required', values: Object.fromEntries(form) });

		if (mantraId) {
			const exists = await prisma.mantra.findUnique({ where: { id: mantraId }, select: { id: true } });
			if (!exists) return fail(400, { error: 'Selected mantra not found', values: Object.fromEntries(form) });
		}

		await prisma.quote.create({
			data: { text, source, mantraId, imageUrl, sortOrder: isNaN(sortOrder) ? 0 : sortOrder, isActive }
		});
		throw redirect(303, '/quotes');
	}
};
