import type { Actions } from './$types';
import { error, fail, redirect } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';
import { patchQuery } from '$lib/url';

export const actions: Actions = {
	toggleActive: async (event) => {
		requireRole(event, 'editor');
		const data = await event.request.formData();
		const id = String(data.get('id') ?? '');
		if (!id) return fail(400, { error: 'Missing id' });
		const current = await prisma.storeItem.findUnique({
			where: { id },
			select: { isActive: true }
		});
		if (!current) throw error(404, 'Store item not found');
		await prisma.storeItem.update({ where: { id }, data: { isActive: !current.isActive } });
		return { ok: true };
	},

	delete: async (event) => {
		requireRole(event, 'editor');
		const data = await event.request.formData();
		const id = String(data.get('id') ?? '');
		if (!id) return fail(400, { error: 'Missing id' });
		await prisma.storeItem.delete({ where: { id } });
		throw redirect(303, patchQuery(event.url, { delete: null }));
	}
};
