import { error, fail, redirect } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';
import { prisma } from '$lib/server/prisma';
import { parseStoreItemForm } from '$lib/server/store';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const item = await prisma.storeItem.findUnique({ where: { id: event.params.id } });
	if (!item) throw error(404, 'Store item not found');
	return { item };
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

		await prisma.storeItem.update({
			where: { id: event.params.id },
			data: {
				name: parsed.name,
				description: parsed.description,
				pointsCost: parsed.pointsCost,
				imageUrl: parsed.imageUrl ?? null,
				stock: parsed.stock ?? null,
				isActive: parsed.isActive,
				comingSoon: parsed.comingSoon,
				sortOrder: parsed.sortOrder
			}
		});

		const params = new URLSearchParams(event.url.searchParams);
		throw redirect(303, `/store${params.toString() ? '?' + params.toString() : ''}`);
	}
};
