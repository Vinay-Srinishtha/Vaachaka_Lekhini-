import type { Actions } from './$types';
import { fail, redirect } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';
import { patchQuery } from '$lib/url';

export const actions: Actions = {
	delete: async (event) => {
		requireRole(event, 'editor');
		const data = await event.request.formData();
		const key = String(data.get('key') ?? '');
		if (!key) return fail(400, { error: 'Missing key' });
		await prisma.featureFlag.delete({ where: { key } }).catch(() => undefined);
		throw redirect(303, patchQuery(event.url, { delete: null }));
	}
};
