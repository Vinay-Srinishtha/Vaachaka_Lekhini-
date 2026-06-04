import { fail, redirect } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';
import { prisma } from '$lib/server/prisma';
import { parseFlagForm } from '$lib/server/flags';
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
			parsed = parseFlagForm(form);
		} catch (e: any) {
			return fail(400, {
				fieldErrors: e?.body?.fieldErrors ?? {},
				values: Object.fromEntries(form)
			});
		}

		const dup = await prisma.featureFlag.findUnique({
			where: { key: parsed.key },
			select: { key: true }
		});
		if (dup) {
			return fail(409, {
				fieldErrors: { key: 'Key already exists.' },
				values: Object.fromEntries(form)
			});
		}

		await prisma.featureFlag.create({
			data: {
				key: parsed.key,
				valueType: parsed.valueType,
				value: parsed.value as any,
				description: parsed.description
			}
		});

		const params = new URLSearchParams(event.url.searchParams);
		throw redirect(303, `/config${params.toString() ? '?' + params.toString() : ''}`);
	}
};
