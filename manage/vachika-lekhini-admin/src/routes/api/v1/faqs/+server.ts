import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';

export const GET: RequestHandler = async () => {
	const faqs = await prisma.faq.findMany({
		where: { isActive: true },
		orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
		select: { id: true, question: true, answer: true, sortOrder: true, updatedAt: true }
	});

	const latest = faqs.reduce((acc, f) => (f.updatedAt > acc ? f.updatedAt : acc), new Date(0));

	return snakeJson(
		{ count: faqs.length, faqs },
		{
			headers: {
				'cache-control': 'public, max-age=300, stale-while-revalidate=3600',
				'last-modified': latest.toUTCString()
			}
		}
	);
};
