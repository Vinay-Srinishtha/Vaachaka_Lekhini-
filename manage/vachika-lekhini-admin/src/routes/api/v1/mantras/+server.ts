import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';

/// GET /api/v1/mantras — full active catalog for the Flutter app.
/// Public, no auth. Cached for 5 minutes on edge / device.
/// Sorted by admin-defined sortOrder then alphabetical roman name.
export const GET: RequestHandler = async () => {
	const mantras = await prisma.mantra.findMany({
		where: { isActive: true },
		orderBy: [{ sortOrder: 'asc' }, { nameRoman: 'asc' }],
		select: {
			slug: true,
			nameDevanagari: true,
			nameRoman: true,
			nameTelugu: true,
			nameKannada: true,
			description: true,
			deity: true,
			thumbPalette: true,
			tags: true,
			recommendedCount: true,
			recommendedDays: true,
			pronunciationUrl: true,
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
				'cache-control': 'public, max-age=300, stale-while-revalidate=600',
				'last-modified': latest.toUTCString()
			}
		}
	);
};
