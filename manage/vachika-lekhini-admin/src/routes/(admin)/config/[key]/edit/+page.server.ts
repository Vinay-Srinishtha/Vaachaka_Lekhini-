import { error, fail, redirect } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';
import { prisma } from '$lib/server/prisma';
import { parseFlagForm } from '$lib/server/flags';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const flag = await prisma.featureFlag.findUnique({
		where: { key: decodeURIComponent(event.params.key) }
	});
	if (!flag) throw error(404, 'Flag not found');
	return { flag };
};

export const actions: Actions = {
	default: async (event) => {
		requireRole(event, 'editor');
		const form = await event.request.formData();

		let parsed;
		try {
			parsed = parseFlagForm(form);
		} catch (e: any) {
			return fail(400, {
				fieldErrors: e?.body?.fieldErrors ?? {},
				values: Object.fromEntries(form)
			});
		}

		await prisma.featureFlag.update({
			where: { key: decodeURIComponent(event.params.key) },
			data: {
				valueType: parsed.valueType,
				value: parsed.value as any,
				description: parsed.description
			}
		});

		const params = new URLSearchParams(event.url.searchParams);
		throw redirect(303, `/config${params.toString() ? '?' + params.toString() : ''}`);
	}
};
