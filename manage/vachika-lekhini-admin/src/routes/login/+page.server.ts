import { fail, redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';
import { loginAdmin } from '$lib/server/auth';

export const load: PageServerLoad = ({ locals, url }) => {
	if (locals.admin) {
		throw redirect(303, url.searchParams.get('redirect') ?? '/');
	}
};

export const actions: Actions = {
	default: async ({ request, cookies, url }) => {
		const data = await request.formData();
		const username = String(data.get('username') ?? '').trim();
		const password = String(data.get('password') ?? '');

		if (!username || !password) {
			return fail(400, { username, error: 'Username and password are required.' });
		}

		try {
			await loginAdmin(cookies, username, password);
		} catch (e) {
			return fail(401, { username, error: 'Invalid username or password.' });
		}

		throw redirect(303, url.searchParams.get('redirect') ?? '/');
	}
};
