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
 *   { quotes: [ { id, slug, text, source, text_roman, source_roman,
 *                 text_telugu, source_telugu, text_devanagari, source_devanagari,
 *                 text_kannada, source_kannada, image_url, mantra_id } ] }
 */
export const GET: RequestHandler = async ({ url }) => {
	try {
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
			select: {
				id: true, slug: true, text: true, source: true,
				textRoman: true, sourceRoman: true,
				textTelugu: true, sourceTelugu: true,
				textDevanagari: true, sourceDevanagari: true,
				textKannada: true, sourceKannada: true,
				imageUrl: true, mantraId: true
			}
		});

		return json({
			quotes: quotes.map((q) => ({
				id: q.id,
				slug: q.slug ?? null,
				text: q.text ?? null,
				source: q.source ?? null,
				text_roman: q.textRoman ?? null,
				source_roman: q.sourceRoman ?? null,
				text_telugu: q.textTelugu ?? null,
				source_telugu: q.sourceTelugu ?? null,
				text_devanagari: q.textDevanagari ?? null,
				source_devanagari: q.sourceDevanagari ?? null,
				text_kannada: q.textKannada ?? null,
				source_kannada: q.sourceKannada ?? null,
				image_url: q.imageUrl ?? null,
				mantra_id: q.mantraId ?? null
			}))
		});
	} catch (e) {
		console.error(e);
		return json({ error: 'Internal error' }, { status: 500 });
	}
};
