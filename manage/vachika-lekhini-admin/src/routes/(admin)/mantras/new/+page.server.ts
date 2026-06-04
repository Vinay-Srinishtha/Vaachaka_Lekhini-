import { fail, redirect } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';
import { prisma } from '$lib/server/prisma';
import { parseMantraForm } from '$lib/server/mantras';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = (event) => {
	requireRole(event, 'editor');
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

		const dup = await prisma.mantra.findUnique({
			where: { slug: parsed.slug },
			select: { id: true }
		});
		if (dup) {
			return fail(409, {
				fieldErrors: { slug: 'Slug already exists.' },
				values: Object.fromEntries(form),
				tags: form.getAll('tags').map(String)
			});
		}

		await prisma.mantra.create({
			data: {
				slug: parsed.slug,
				nameDevanagari: parsed.nameDevanagari,
				nameRoman: parsed.nameRoman,
				nameTelugu: parsed.nameTelugu ?? null,
				nameKannada: parsed.nameKannada ?? null,
				description: parsed.description,
				deity: parsed.deity ?? null,
				thumbPalette: parsed.thumbPalette,
				tags: parsed.tags,
				recommendedCount: parsed.recommendedCount ?? null,
				recommendedDays: parsed.recommendedDays ?? null,
				pronunciationUrl: parsed.pronunciationUrl ?? null,
				isActive: parsed.isActive,
				sortOrder: parsed.sortOrder
			}
		});

		// Return to list, preserving filters
		const params = new URLSearchParams(event.url.searchParams);
		throw redirect(303, `/mantras${params.toString() ? '?' + params.toString() : ''}`);
	}
};
