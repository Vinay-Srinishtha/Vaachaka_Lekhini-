import { fail, redirect } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';
import { prisma } from '$lib/server/prisma';
import { parseStoreItemForm } from '$lib/server/store';
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
			parsed = parseStoreItemForm(form);
		} catch (e: any) {
			return fail(400, {
				fieldErrors: e?.body?.fieldErrors ?? {},
				values: Object.fromEntries(form)
			});
		}

		const dup = await prisma.storeItem.findUnique({
			where: { slug: parsed.slug },
			select: { id: true }
		});
		if (dup) {
			return fail(409, {
				fieldErrors: { slug: 'Slug already exists.' },
				values: Object.fromEntries(form)
			});
		}

		await prisma.storeItem.create({
			data: {
				slug: parsed.slug,
				name: parsed.name,
				description: parsed.description,
				pointsCost: parsed.pointsCost,
				imageUrl: parsed.imageUrl ?? null,
				stock: parsed.stock ?? null,
				isActive: parsed.isActive,
				sortOrder: parsed.sortOrder
			}
		});

		const params = new URLSearchParams(event.url.searchParams);
		throw redirect(303, `/store${params.toString() ? '?' + params.toString() : ''}`);
	}
};
