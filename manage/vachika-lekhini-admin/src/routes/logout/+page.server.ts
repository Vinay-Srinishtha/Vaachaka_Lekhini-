import { redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { ADMIN_COOKIE, verifyAdminToken } from '$lib/server/jwt';
import { logoutAdmin } from '$lib/server/auth';

export const load: PageServerLoad = () => {
	throw redirect(303, '/login');
};

export const actions: Actions = {
	default: async ({ cookies }) => {
		const token = cookies.get(ADMIN_COOKIE);
		const payload = token ? await verifyAdminToken(token) : null;
		await logoutAdmin(cookies, payload?.jti);
		throw redirect(303, '/login');
	}
};
