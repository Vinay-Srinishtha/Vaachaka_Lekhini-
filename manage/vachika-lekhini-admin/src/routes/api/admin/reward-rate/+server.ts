import type { RequestHandler } from './$types';
import { json, error } from '@sveltejs/kit';
import { requireRole } from '$lib/server/auth';
import { getRewardRate, setRewardRate } from '$lib/server/reward-config';
import { emitChange } from '$lib/server/live';

/// GET /api/admin/reward-rate — returns { rate: number }
export const GET: RequestHandler = async (event) => {
	requireRole(event, 'editor');
	const rate = await getRewardRate();
	return json({ rate });
};

/// PUT /api/admin/reward-rate — body { rate: number }
/// Updates the chants_per_point FeatureFlag and broadcasts a live change.
export const PUT: RequestHandler = async (event) => {
	requireRole(event, 'editor');
	const body = await event.request.json().catch(() => null);
	const rate = body?.rate;
	if (typeof rate !== 'number' || rate < 1 || !Number.isFinite(rate)) {
		throw error(400, 'rate must be a positive integer');
	}
	const normalized = Math.max(1, Math.round(rate));
	await setRewardRate(normalized);
	emitChange('reward_event'); // triggers Flutter to refresh balance
	return json({ rate: normalized });
};
