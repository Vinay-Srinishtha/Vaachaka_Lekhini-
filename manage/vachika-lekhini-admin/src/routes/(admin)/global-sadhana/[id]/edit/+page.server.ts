import type { PageServerLoad, Actions } from './$types';
import { fail, error, redirect } from '@sveltejs/kit';
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
	status: z.enum(['draft', 'published', 'active', 'paused', 'completed', 'archived']),
	participation_mode: z.enum(['voice', 'handwriting', 'both']).default('both'),
	instructions: z.string().optional()
});

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	const { id } = event.params;

	const [sadhana, mantras, contributionStats, topContributors] = await Promise.all([
		prisma.globalSadhana.findUnique({
			where: { id },
			include: { mantra: { select: { nameRoman: true } }, _count: { select: { enrollments: true, contributions: true } } }
		}),
		prisma.mantra.findMany({
			where: { isActive: true },
			orderBy: { nameRoman: 'asc' },
			select: { id: true, slug: true, nameRoman: true, nameTelugu: true }
		}),
		prisma.globalSadhanaContribution.groupBy({
			by: ['modality'],
			where: { globalSadhanaId: id },
			_sum: { countAdded: true }
		}),
		prisma.globalSadhanaContribution.groupBy({
			by: ['memberId'],
			where: { globalSadhanaId: id },
			_sum: { countAdded: true },
			orderBy: { _sum: { countAdded: 'desc' } },
			take: 10
		})
	]);

	if (!sadhana) throw error(404, 'Global Sadhana not found');

	// Fetch display names for top contributors.
	const memberIds = topContributors.map((c) => c.memberId);
	const members = await prisma.member.findMany({
		where: { id: { in: memberIds } },
		select: { id: true, displayName: true }
	});
	const memberMap = new Map(members.map((m) => [m.id, m.displayName]));

	return {
		sadhana,
		mantras,
		stats: {
			byVoice: contributionStats.find((c) => c.modality === 'voice')?._sum.countAdded ?? 0,
			byHandwriting: contributionStats.find((c) => c.modality === 'handwriting')?._sum.countAdded ?? 0
		},
		topContributors: topContributors.map((c) => ({
			memberId: c.memberId,
			name: memberMap.get(c.memberId) ?? 'Unknown',
			count: c._sum.countAdded ?? 0
		}))
	};
};

export const actions: Actions = {
	save: async (event) => {
		try {
			requireRole(event, 'editor');
			const { id } = event.params;
			const raw = await event.request.formData();
			const parse = schema.safeParse(Object.fromEntries(raw));
			if (!parse.success) {
				return fail(422, { error: 'Validation failed', values: Object.fromEntries(raw) });
			}
			const d = parse.data;
			await prisma.globalSadhana.update({
				where: { id },
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
					instructions: d.instructions || null,
					...(d.status === 'completed' ? { completedAt: new Date() } : {})
				}
			});
			return { ok: true };
		} catch (e) {
			console.error(e);
			return fail(500, { message: 'Internal error' });
		}
	},

	delete: async (event) => {
		try {
			requireRole(event, 'editor');
			const { id } = event.params;
			await prisma.globalSadhana.delete({ where: { id } }).catch(() => undefined);
			throw redirect(303, '/global-sadhana');
		} catch (e) {
			console.error(e);
			return fail(500, { message: 'Internal error' });
		}
	}
};
