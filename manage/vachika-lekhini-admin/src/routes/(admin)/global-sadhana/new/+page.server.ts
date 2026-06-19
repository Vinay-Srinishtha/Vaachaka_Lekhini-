import type { PageServerLoad, Actions } from './$types';
import { fail, redirect } from '@sveltejs/kit';
import { GlobalSadhanaStatus } from '@prisma/client';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';

const schema = z.object({
	title: z.string().min(1),
	description: z.string().default(''),
	mantra_id: z.string().cuid(),
	mantra_text: z.string().optional(),
	mantra_language: z.string().default('hi'),
	target_count: z.coerce.number().int().positive(),
	start_at: z.string().refine((s) => !isNaN(Date.parse(s)), 'Invalid date'),
	end_at: z.string().optional(),
	image_url: z.string().url().optional().or(z.literal('')),
	is_sponsored: z.coerce.boolean().default(false),
	status: z.enum(['draft', 'published', 'active']).default('draft'),
	participation_mode: z.enum(['voice', 'handwriting', 'both']).default('both'),
	instructions: z.string().optional()
});

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const mantras = await prisma.mantra.findMany({
		where: { isActive: true },
		orderBy: { nameRoman: 'asc' },
		select: { id: true, slug: true, nameRoman: true, nameTelugu: true }
	});
	return { mantras };
};

export const actions: Actions = {
	default: async (event) => {
		try {
			requireRole(event, 'editor');
			const raw = await event.request.formData();
			const parse = schema.safeParse(Object.fromEntries(raw));
			if (!parse.success) {
				return fail(422, { error: 'Validation failed', values: Object.fromEntries(raw) });
			}
			const d = parse.data;
			const sadhana = await prisma.globalSadhana.create({
				data: {
					title: d.title,
					description: d.description,
					mantraId: d.mantra_id,
					mantraText: d.mantra_text || null,
					mantraLanguage: d.mantra_language,
					targetCount: d.target_count,
					startAt: new Date(d.start_at),
					endAt: d.end_at ? new Date(d.end_at) : null,
					imageUrl: d.image_url || null,
					isSponsored: d.is_sponsored,
					status: d.status as GlobalSadhanaStatus,
					participationMode: d.participation_mode,
					instructions: d.instructions || null
				}
			});
			throw redirect(303, `/global-sadhana/${sadhana.id}/edit`);
		} catch (e) {
			console.error(e);
			return fail(500, { message: 'Internal error' });
		}
	}
};
