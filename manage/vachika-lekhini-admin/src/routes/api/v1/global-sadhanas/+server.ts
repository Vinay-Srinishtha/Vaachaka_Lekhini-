import { json, type RequestHandler } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';

/**
 * GET /api/v1/global-sadhanas
 * Public (no auth required) — returns active/published global sadhanas.
 * Optional query param: ?status=active (default: active)
 *
 * Response: { sadhanas: GlobalSadhana[] }
 */
export const GET: RequestHandler = async ({ url }) => {
	// Return both active and published sadhanas so Flutter sees newly-published programs
	const sadhanas = await prisma.globalSadhana.findMany({
		where: { status: { in: ['active', 'published'] as never[] } },
		orderBy: [{ isSponsored: 'desc' }, { startAt: 'desc' }],
		select: {
			id: true,
			title: true,
			description: true,
			mantraId: true,
			mantraText: true,
			mantraLanguage: true,
			imageUrl: true,
			targetCount: true,
			currentCount: true,
			startAt: true,
			endAt: true,
			status: true,
			participationMode: true,
			instructions: true,
			isSponsored: true,
			completedAt: true,
			_count: { select: { enrollments: true } }
		}
	});

	return json({
		sadhanas: sadhanas.map((s) => ({
			id: s.id,
			title: s.title,
			description: s.description,
			mantra_id: s.mantraId,
			mantra_text: s.mantraText ?? null,
			mantra_language: s.mantraLanguage,
			image_url: s.imageUrl ?? null,
			target_count: s.targetCount,
			current_count: s.currentCount,
			start_at: s.startAt.toISOString(),
			end_at: s.endAt?.toISOString() ?? null,
			status: s.status,
			participation_mode: s.participationMode,
			instructions: s.instructions ?? null,
			is_sponsored: s.isSponsored,
			completed_at: s.completedAt?.toISOString() ?? null,
			participant_count: s._count.enrollments
		}))
	});
};
