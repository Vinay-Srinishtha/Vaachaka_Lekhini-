import { error, redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';
import { canAccessPath, roleHome } from '$lib/roles';

/// Guard for the entire (admin) group.
///   • Unauthenticated → /login with a return path.
///   • Authenticated but no access to the requested section → bounce to the
///     role's home section (or 403 if they're already there).
export const load: LayoutServerLoad = ({ locals, url }) => {
	if (!locals.admin) {
		throw redirect(303, `/login?redirect=${encodeURIComponent(url.pathname)}`);
	}
	if (!canAccessPath(locals.admin.role, url.pathname)) {
		const home = roleHome(locals.admin.role);
		if (url.pathname !== home) throw redirect(303, home);
		throw error(403, 'No access to this section');
	}
	return { admin: locals.admin };
};
