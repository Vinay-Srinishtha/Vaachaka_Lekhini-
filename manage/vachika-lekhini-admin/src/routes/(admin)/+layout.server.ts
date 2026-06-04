import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';

/// Guard for the entire (admin) group. Redirects unauthenticated visitors
/// to /login with a return path.
export const load: LayoutServerLoad = ({ locals, url }) => {
	if (!locals.admin) {
		throw redirect(303, `/login?redirect=${encodeURIComponent(url.pathname)}`);
	}
	return { admin: locals.admin };
};
