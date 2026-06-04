import type { LayoutServerLoad } from './$types';

// Expose the admin (if any) to every page via $page.data.admin.
export const load: LayoutServerLoad = ({ locals }) => {
	return { admin: locals.admin };
};
