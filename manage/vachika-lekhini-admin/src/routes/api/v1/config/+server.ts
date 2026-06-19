import { json, type RequestHandler } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';

/// GET /api/v1/config — remote config / feature flags.
/// Flat key→value map. Values are decoded per flag type so the client
/// gets typed JSON values (bool, int, string, json) instead of stringified.
export const GET: RequestHandler = async () => {
	try {
		const flags = await prisma.featureFlag.findMany({
			select: { key: true, valueType: true, value: true, updatedAt: true }
		});

		const out: Record<string, unknown> = {};
		for (const f of flags) {
			out[f.key] = f.value;
		}

		const latest = flags.reduce(
			(acc, f) => (f.updatedAt > acc ? f.updatedAt : acc),
			new Date(0)
		);

		return snakeJson(
			{ version: latest.toISOString(), config: out },
			{
				headers: {
					'cache-control': 'public, max-age=60, stale-while-revalidate=600',
					'last-modified': latest.toUTCString()
				}
			}
		);
	} catch (e) {
		console.error(e);
		return json({ error: 'Internal error' }, { status: 500 });
	}
};
