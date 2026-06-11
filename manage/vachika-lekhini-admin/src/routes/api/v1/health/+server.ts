import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';

export const GET: RequestHandler = async () => {
	await prisma.$queryRaw`SELECT 1`;
	return snakeJson(
		{ status: 'ok' },
		{
			headers: {
				'cache-control': 'no-store'
			}
		}
	);
};

