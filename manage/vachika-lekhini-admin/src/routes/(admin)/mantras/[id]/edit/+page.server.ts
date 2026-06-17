import { error, fail, redirect } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';
import { prisma } from '$lib/server/prisma';
import { parseMantraForm } from '$lib/server/mantras';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const mantra = await prisma.mantra.findUnique({ where: { id: event.params.id } });
	if (!mantra) throw error(404, 'Mantra not found');
	return { mantra };
};

export const actions: Actions = {
	default: async (event) => {
		requireRole(event, 'editor');
		const form = await event.request.formData();

		let parsed;
		try {
			parsed = parseMantraForm(form);
		} catch (e: any) {
			return fail(400, {
				fieldErrors: e?.body?.fieldErrors ?? {},
				values: Object.fromEntries(form),
				tags: form.getAll('tags').map(String)
			});
		}

		await prisma.mantra.update({
			where: { id: event.params.id },
			data: {
				nameDevanagari: parsed.nameDevanagari,
				nameRoman: parsed.nameRoman,
				nameTelugu: parsed.nameTelugu ?? null,
				nameKannada: parsed.nameKannada ?? null,
				description: parsed.description,
				deity: parsed.deity ?? null,
				tags: parsed.tags,
				recommendedCount: parsed.recommendedCount ?? null,
				recommendedDays: parsed.recommendedDays ?? null,
				pronunciationUrl: parsed.pronunciationUrl ?? null,
				previewImageUrl: parsed.previewImageUrl ?? null,
				imageUrl: parsed.imageUrl ?? null,
				milestones: parsed.milestones ?? undefined,
				isActive: parsed.isActive,
				sortOrder: parsed.sortOrder
			}
		});

		const params = new URLSearchParams(event.url.searchParams);
		throw redirect(303, `/mantras${params.toString() ? '?' + params.toString() : ''}`);
	}
};
