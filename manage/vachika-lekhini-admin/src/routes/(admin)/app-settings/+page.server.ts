import type { PageServerLoad, Actions } from './$types';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';

const KEYS = ['privacy_policy', 'about_app', 'app_logo_url', 'app_link', 'invite_host', 'app_download_link', 'share_quote_image_url', 'share_quote_text', 'bulletin_mode', 'bulletin_text'] as const;

async function loadSettings() {
	const rows = await prisma.appSetting.findMany({ where: { key: { in: [...KEYS] } } });
	const map: Record<string, string> = {
		privacy_policy: '',
		about_app: '',
		app_logo_url: '',
		app_link: 'https://vaachika-lekhani.vercel.app',
		invite_host: 'vaachakalekhini.com',
		app_download_link: '',
		share_quote_image_url: '',
		share_quote_text: '',
		bulletin_mode: 'custom_text',
		bulletin_text: ''
	};
	for (const r of rows) map[r.key] = r.value;
	return map;
}

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'viewer');
	return { settings: await loadSettings() };
};

export const actions: Actions = {
	save: async (event) => {
		try { requireRole(event, 'editor'); } catch {
			return { ok: false, settings: await loadSettings(), error: 'You do not have permission to save settings.' };
		}
		const form = await event.request.formData();
		const privacyPolicy     = String(form.get('privacy_policy') ?? '').trim();
		const aboutApp          = String(form.get('about_app') ?? '').trim();
		const appLogoUrl        = String(form.get('app_logo_url') ?? '').trim();
		const appLink           = String(form.get('app_link') ?? '').trim();
		const inviteHost        = String(form.get('invite_host') ?? '').trim();
		const appDownloadLink   = String(form.get('app_download_link') ?? '').trim();
		const shareQuoteImgUrl  = String(form.get('share_quote_image_url') ?? '').trim();
		const shareQuoteText    = String(form.get('share_quote_text') ?? '').trim();
		const bulletinModeRaw   = String(form.get('bulletin_mode') ?? 'custom_text').trim();
		const bulletinMode      = bulletinModeRaw === 'stats' ? 'stats' : 'custom_text';
		const bulletinText      = String(form.get('bulletin_text') ?? '').trim();

		const upsert = (key: string, value: string) =>
			prisma.appSetting.upsert({
				where: { key },
				update: { value, updatedAt: new Date() },
				create: { key, value, updatedAt: new Date() }
			});

		try {
			await prisma.$transaction([
				upsert('privacy_policy', privacyPolicy),
				upsert('about_app', aboutApp),
				upsert('app_logo_url', appLogoUrl),
				upsert('app_link', appLink),
				upsert('invite_host', inviteHost || 'vaachika-lekhani.vercel.app'),
				upsert('app_download_link', appDownloadLink),
				upsert('share_quote_image_url', shareQuoteImgUrl),
				upsert('share_quote_text', shareQuoteText),
				upsert('bulletin_mode', bulletinMode),
				upsert('bulletin_text', bulletinText),
			]);
		} catch (e) {
			console.error('[app-settings save]', e);
			return { ok: false, settings: await loadSettings(), error: 'Database error — changes not saved. Check server logs.' };
		}

		const settings = await loadSettings();
		return { ok: true, settings, error: null };
	}
};
