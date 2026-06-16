import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';

/// GET /api/v1/mantras — full active catalog for the Flutter app.
/// Public, no auth. Always fresh so admin publish changes reach Flutter.
/// Sorted by admin-defined sortOrder then alphabetical roman name.
export const GET: RequestHandler = async () => {
	const mantras = await prisma.mantra.findMany({
		where: { isActive: true },
		orderBy: [{ sortOrder: 'asc' }, { nameRoman: 'asc' }],
		select: {
			slug: true,
			isActive: true,
			nameDevanagari: true,
			nameRoman: true,
			nameTelugu: true,
			nameKannada: true,
			description: true,
			deity: true,

			tags: true,
			recommendedCount: true,
			recommendedDays: true,
			pronunciationUrl: true,
				milestones: true,
			sortOrder: true,
			updatedAt: true
		}
	});

	const latest = mantras.reduce(
		(acc, m) => (m.updatedAt > acc ? m.updatedAt : acc),
		new Date(0)
	);

	return snakeJson(
		{
			version: latest.toISOString(),
			count: mantras.length,
			mantras
		},
		{
			headers: {
				'cache-control': 'no-store, max-age=0',
				'last-modified': latest.toUTCString()
			}
		}
	);
};
