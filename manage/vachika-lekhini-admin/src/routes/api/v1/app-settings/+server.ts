import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';

const DEFAULTS: Record<string, string> = {
	privacy_policy: '',
	about_app: '',
	app_logo_url: '',
	invite_host: 'vaachakalekhini.com'
};

export const GET: RequestHandler = async () => {
	const rows = await prisma.appSetting.findMany({ select: { key: true, value: true, updatedAt: true } });
	const map: Record<string, string> = { ...DEFAULTS };
	let latest = new Date(0);
	for (const r of rows) {
		map[r.key] = r.value;
		if (r.updatedAt > latest) latest = r.updatedAt;
	}

	return snakeJson(
		{
			privacy_policy: map['privacy_policy'],
			about_app: map['about_app'] || null,
			app_logo_url: map['app_logo_url'] || null,
			invite_host: map['invite_host'] || 'vaachakalekhini.com'
		},
		{
			headers: {
				'cache-control': 'public, max-age=60, stale-while-revalidate=600',
				'last-modified': latest.toUTCString()
			}
		}
	);
};
