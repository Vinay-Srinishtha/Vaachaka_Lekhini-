import { fail, redirect } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = (event) => { requireRole(event, 'editor'); };

export const actions: Actions = {
	default: async (event) => {
		requireRole(event, 'editor');
		const form = await event.request.formData();
		const question = String(form.get('question') ?? '').trim();
		const answer = String(form.get('answer') ?? '').trim();
		const sortOrder = parseInt(String(form.get('sort_order') ?? '0'), 10);
		const isActive = form.get('is_active') === 'on';

		if (!question) return fail(400, { error: 'Question is required', values: Object.fromEntries(form) });
		if (!answer) return fail(400, { error: 'Answer is required', values: Object.fromEntries(form) });

		await prisma.faq.create({ data: { question, answer, sortOrder: isNaN(sortOrder) ? 0 : sortOrder, isActive } });
		throw redirect(303, '/faqs');
	}
};
