import type { PageServerLoad, Actions } from './$types';
import { fail } from '@sveltejs/kit';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';
import { seedRewardRules } from '$lib/server/reward-rules';
import { emitChange } from '$lib/server/live';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'editor');
	await seedRewardRules(); // ensure defaults exist
	const rules = await prisma.rewardRule.findMany({ orderBy: { createdAt: 'asc' } });
	return { rules };
};

const updateSchema = z.object({
	id: z.string().min(1),
	name: z.string().min(1).max(80),
	description: z.string().max(300),
	points: z.coerce.number().int().min(0).max(100_000),
	threshold: z.coerce.number().int().min(1).max(10_000).nullable(),
	isActive: z.coerce.boolean()
});

export const actions: Actions = {
	update: async (event) => {
		try {
			requireRole(event, 'editor');
			const fd = await event.request.formData();
			const raw = {
				id: fd.get('id'),
				name: fd.get('name'),
				description: fd.get('description'),
				points: fd.get('points'),
				threshold: fd.get('threshold') || null,
				isActive: fd.get('isActive') === 'true'
			};
			const parsed = updateSchema.safeParse(raw);
			if (!parsed.success) {
				return fail(400, { error: parsed.error.issues[0]?.message ?? 'Invalid input' });
			}
			const { id, ...data } = parsed.data;
			await prisma.rewardRule.update({
				where: { id },
				data: { ...data, threshold: data.threshold ?? null }
			});
			emitChange('reward_event');
			return { success: true };
		} catch (e) {
			console.error(e);
			return fail(500, { message: 'Internal error' });
		}
	}
};
