import { json, type RequestHandler } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';

/// GET /api/v1/store — active rewards-store catalogue for the Flutter app.
export const GET: RequestHandler = async () => {
	try {
		const items = await prisma.storeItem.findMany({
			where: { isActive: true },
			orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
			select: {
				slug: true,
				name: true,
				description: true,
				pointsCost: true,
				imageUrl: true,
				stock: true,
				comingSoon: true,
				sortOrder: true,
				updatedAt: true
			}
		});

		const latest = items.reduce((acc, i) => (i.updatedAt > acc ? i.updatedAt : acc), new Date(0));

		return snakeJson(
			{ version: latest.toISOString(), count: items.length, items },
			{
				headers: {
					'cache-control': 'public, max-age=300, stale-while-revalidate=600',
					'last-modified': latest.toUTCString()
				}
			}
		);
	} catch (e) {
		console.error(e);
		return json({ error: 'Internal error' }, { status: 500 });
	}
};
