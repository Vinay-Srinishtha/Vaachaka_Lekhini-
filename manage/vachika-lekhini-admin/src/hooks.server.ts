import type { Handle } from '@sveltejs/kit';
import { resolveAdmin } from '$lib/server/auth';

export const handle: Handle = async ({ event, resolve }) => {
	event.locals.admin = await resolveAdmin(event.cookies);
	return resolve(event);
};
