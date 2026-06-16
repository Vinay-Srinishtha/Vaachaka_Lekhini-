import type { Handle } from '@sveltejs/kit';
import { resolveAdmin } from '$lib/server/auth';
import { seedRewardRules } from '$lib/server/reward-rules';
import { seedDefaultFlags } from '$lib/server/reward-config';

// Seed on cold start — idempotent, safe to run multiple times.
seedDefaultFlags().catch(() => {});
seedRewardRules().catch(() => {});

export const handle: Handle = async ({ event, resolve }) => {
	event.locals.admin = await resolveAdmin(event.cookies);
	return resolve(event);
};
