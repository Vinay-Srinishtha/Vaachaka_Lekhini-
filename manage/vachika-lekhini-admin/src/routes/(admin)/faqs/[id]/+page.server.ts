import { error, fail, redirect } from '@sveltejs/kit';
import type { PageServerLoad, Actions } from './$types';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const faq = await prisma.faq.findUnique({
		where: { id: event.params.id },
		select: { id: true, question: true, answer: true, sortOrder: true, isActive: true }
	});
	if (!faq) throw error(404, 'FAQ not found');
	return { faq };
};

export const actions: Actions = {
	default: async (event) => {
		requireRole(event, 'editor');
		const form = await event.request.formData();
		const question = String(form.get('question') ?? '').trim();
		const answer = String(form.get('answer') ?? '').trim();
		const sortOrder = parseInt(String(form.get('sort_order') ?? '0'), 10);
		const isActive = form.get('is_active') === 'on';

		if (!question) return fail(400, { error: 'Question is required' });
		if (!answer) return fail(400, { error: 'Answer is required' });

		await prisma.faq.update({
			where: { id: event.params.id },
			data: { question, answer, sortOrder: isNaN(sortOrder) ? 0 : sortOrder, isActive }
		});
		throw redirect(303, '/faqs');
	}
};
