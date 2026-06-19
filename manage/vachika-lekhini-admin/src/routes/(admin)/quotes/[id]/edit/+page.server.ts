import { error, fail, redirect } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'editor');
	const { id } = event.params;
	const [quote, mantras] = await Promise.all([
		prisma.quote.findUnique({
			where: { id },
			select: { id: true, text: true, source: true, textRoman: true, sourceRoman: true, textTelugu: true, sourceTelugu: true, textDevanagari: true, sourceDevanagari: true, textKannada: true, sourceKannada: true, imageUrl: true, mantraId: true, isActive: true, sortOrder: true, slug: true }
		}),
		prisma.mantra.findMany({
			where: { isActive: true },
			orderBy: { nameRoman: 'asc' },
			select: { id: true, slug: true, nameRoman: true, nameTelugu: true }
		})
	]);
	if (!quote) throw error(404, 'Quote not found');
	return { quote, mantras };
};

export const actions: Actions = {
	save: async (event) => {
		try {
			requireRole(event, 'editor');
			const { id } = event.params;
			const form = await event.request.formData();
			const text = String(form.get('text') ?? '').trim() || null;
			const source = String(form.get('source') ?? '').trim() || null;
			const textRoman = String(form.get('text_roman') ?? '').trim() || null;
			const sourceRoman = String(form.get('source_roman') ?? '').trim() || null;
			const textTelugu = String(form.get('text_telugu') ?? '').trim() || null;
			const sourceTelugu = String(form.get('source_telugu') ?? '').trim() || null;
			const textDevanagari = String(form.get('text_devanagari') ?? '').trim() || null;
			const sourceDevanagari = String(form.get('source_devanagari') ?? '').trim() || null;
			const textKannada = String(form.get('text_kannada') ?? '').trim() || null;
			const sourceKannada = String(form.get('source_kannada') ?? '').trim() || null;
			const slug = String(form.get('slug') ?? '').trim() || null;
			const mantraId = String(form.get('mantra_id') ?? '').trim() || null;
			const imageUrl = String(form.get('image_url') ?? '').trim() || null;
			const sortOrder = parseInt(String(form.get('sort_order') ?? '0'), 10);
			const isActive = form.get('is_active') === 'on';

			if (!text && !textRoman && !textTelugu && !textDevanagari && !textKannada)
				return fail(400, { error: 'At least one language field is required', values: Object.fromEntries(form) });

			if (mantraId) {
				const exists = await prisma.mantra.findUnique({ where: { id: mantraId }, select: { id: true } });
				if (!exists) return fail(400, { error: 'Selected mantra not found', values: Object.fromEntries(form) });
			}

			await prisma.quote.update({
				where: { id },
				data: {
					text: text ?? '', source, textRoman, sourceRoman, textTelugu, sourceTelugu,
					textDevanagari, sourceDevanagari, textKannada, sourceKannada,
					slug, mantraId, imageUrl, sortOrder: isNaN(sortOrder) ? 0 : sortOrder, isActive
				}
			});
			throw redirect(303, '/quotes');
		} catch (e) {
			console.error(e);
			return fail(500, { message: 'Internal error' });
		}
	},

	delete: async (event) => {
		try {
			requireRole(event, 'editor');
			const { id } = event.params;
			await prisma.quote.delete({ where: { id } }).catch(() => undefined);
			throw redirect(303, '/quotes');
		} catch (e) {
			console.error(e);
			return fail(500, { message: 'Internal error' });
		}
	}
};
