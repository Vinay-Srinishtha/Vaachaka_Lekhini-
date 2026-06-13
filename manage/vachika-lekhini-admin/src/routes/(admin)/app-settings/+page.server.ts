import type { PageServerLoad, Actions } from './$types';
import { fail } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';

const KEYS = ['support_email', 'privacy_policy', 'app_logo_url', 'invite_host'] as const;

async function loadSettings() {
	const rows = await prisma.appSetting.findMany({ where: { key: { in: [...KEYS] } } });
	const map: Record<string, string> = {
		support_email: 'support@vaachikalekhini.com',
		privacy_policy: '',
		app_logo_url: '',
		invite_host: 'kvl.app'
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
		requireRole(event, 'editor');
		const form = await event.request.formData();
		const supportEmail = String(form.get('support_email') ?? '').trim();
		const privacyPolicy = String(form.get('privacy_policy') ?? '').trim();
		const appLogoUrl = String(form.get('app_logo_url') ?? '').trim();
		const inviteHost = String(form.get('invite_host') ?? '').trim();

		if (supportEmail && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(supportEmail)) {
			return fail(400, {
				error: 'Invalid support email address',
				settings: { support_email: supportEmail, privacy_policy: privacyPolicy, app_logo_url: appLogoUrl, invite_host: inviteHost }
			});
		}

		await prisma.$transaction([
			prisma.appSetting.upsert({
				where: { key: 'support_email' },
				update: { value: supportEmail, updatedAt: new Date() },
				create: { key: 'support_email', value: supportEmail, updatedAt: new Date() }
			}),
			prisma.appSetting.upsert({
				where: { key: 'privacy_policy' },
				update: { value: privacyPolicy, updatedAt: new Date() },
				create: { key: 'privacy_policy', value: privacyPolicy, updatedAt: new Date() }
			}),
			prisma.appSetting.upsert({
				where: { key: 'app_logo_url' },
				update: { value: appLogoUrl, updatedAt: new Date() },
				create: { key: 'app_logo_url', value: appLogoUrl, updatedAt: new Date() }
			}),
			prisma.appSetting.upsert({
				where: { key: 'invite_host' },
				update: { value: inviteHost || 'kvl.app', updatedAt: new Date() },
				create: { key: 'invite_host', value: inviteHost || 'kvl.app', updatedAt: new Date() }
			})
		]);

		return { ok: true };
	}
};
