import { json, type RequestHandler } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { computeBulletinText } from '$lib/server/bulletin';

const DEFAULTS: Record<string, string> = {
	privacy_policy: '',
	about_app: '',
	app_logo_url: '',
	app_link: 'https://vaachakalekhini.com/app',
	invite_host: 'vaachakalekhini.com',
	app_download_link: '',
	share_quote_image_url: '',
	share_quote_text: '',
	bulletin_mode: 'custom_text', // 'custom_text' | 'stats'
	bulletin_text: ''
};

export const GET: RequestHandler = async () => {
	try {
		const rows = await prisma.appSetting.findMany({ select: { key: true, value: true, updatedAt: true } });
		const map: Record<string, string> = { ...DEFAULTS };
		let latest = new Date(0);
		for (const r of rows) {
			map[r.key] = r.value;
			if (r.updatedAt > latest) latest = r.updatedAt;
		}

		// Bulletin: in 'stats' mode the banner text is computed live from app
		// totals; in 'custom_text' mode it's whatever the admin typed.
		const bulletinText =
			map['bulletin_mode'] === 'stats'
				? await computeBulletinText()
				: (map['bulletin_text'] || '');

		return snakeJson(
			{
				privacy_policy:        map['privacy_policy'],
				about_app:             map['about_app'] || null,
				app_logo_url:          map['app_logo_url'] || null,
				app_link:              map['app_link'] || 'https://vaachakalekhini.com/app',
				invite_host:           map['invite_host'] || 'vaachakalekhini.com',
				app_download_link:     map['app_download_link'] || null,
				share_quote_image_url: map['share_quote_image_url'] || null,
				share_quote_text:      map['share_quote_text'] || null,
				bulletin_mode:         map['bulletin_mode'] || 'custom_text',
				bulletin_text:         bulletinText || null
			},
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
