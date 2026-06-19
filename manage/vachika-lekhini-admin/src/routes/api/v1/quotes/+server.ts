import { json, type RequestHandler } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';

/**
 * GET /api/v1/quotes
 *
 * Returns active quote cards for the Flutter home screen.
 *
 * Query params:
 *   mantra_ids  – comma-separated list of mantraIds the active member has programs for.
 *                 Quotes whose mantraId matches one of these are included.
 *                 Universal quotes (mantraId = null) are always included.
 *
 * Response (snake_case for Flutter):
 *   { quotes: [ { id, text, source, image_url, mantra_id } ] }
 */
export const GET: RequestHandler = async ({ url }) => {
	const rawIds = url.searchParams.get('mantra_ids') ?? '';
	const mantraIds = rawIds
		.split(',')
		.map((s) => s.trim())
		.filter(Boolean);

	const quotes = await prisma.quote.findMany({
		where: {
			isActive: true,
			OR: [
				{ mantraId: null },
				...(mantraIds.length ? [{ mantraId: { in: mantraIds } }] : [])
			]
		},
		orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
		select: { id: true, text: true, source: true, imageUrl: true, mantraId: true }
	});

	return json({
		quotes: quotes.map((q) => ({
			id: q.id,
			text: q.text,
			source: q.source ?? null,
			image_url: q.imageUrl ?? null,
			mantra_id: q.mantraId ?? null
		}))
	});
};
