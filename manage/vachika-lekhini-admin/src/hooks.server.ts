import type { Handle } from '@sveltejs/kit';
import { resolveAdmin } from '$lib/server/auth';
import { seedRewardRules } from '$lib/server/reward-rules';
import { seedDefaultFlags } from '$lib/server/reward-config';

// Seed on cold start — idempotent, safe to run multiple times.
seedDefaultFlags().catch(() => {});
seedRewardRules().catch(() => {});

// CORS for the public API so dev tools (e.g. the load simulator page opened
// from a different origin / file:// / preview panel) can call it. Bearer-token
// auth only — no cookies — so a wildcard origin is safe here.
function applyApiCors(request: Request, headers: Headers) {
	const origin = request.headers.get('origin');
	headers.set('access-control-allow-origin', origin ?? '*');
	headers.set('vary', 'origin');
	headers.set('access-control-allow-methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
	headers.set('access-control-allow-headers', 'authorization,content-type,accept');
	headers.set('access-control-max-age', '86400');
}

export const handle: Handle = async ({ event, resolve }) => {
	const isApi = event.url.pathname.startsWith('/api/v1/');

	// Preflight — answer before any auth/body parsing.
	if (isApi && event.request.method === 'OPTIONS') {
		const headers = new Headers();
		applyApiCors(event.request, headers);
		return new Response(null, { status: 204, headers });
	}

	event.locals.admin = await resolveAdmin(event.cookies);
	const response = await resolve(event);
	if (isApi) applyApiCors(event.request, response.headers);
	return response;
};
