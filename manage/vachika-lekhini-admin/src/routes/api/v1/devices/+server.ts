import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { readJsonBody } from '$lib/server/json-input';
import { requireAccount } from '$lib/server/user-auth';
import { deviceUpsertSchema } from '$lib/server/sync';

/// POST /api/v1/devices  (Bearer) — register or update this device.
/// Client supplies a stable per-install UUID. Used for FCM push routing.
export const POST: RequestHandler = async (event) => {
	const account = await requireAccount(event);
	const body = await readJsonBody(event, deviceUpsertSchema);

	const device = await prisma.device.upsert({
		where: { id: body.id },
		create: {
			id: body.id,
			accountId: account.id,
			platform: body.platform,
			appVersion: body.app_version ?? null,
			pushToken: body.push_token ?? null,
			lastMemberId: body.last_member_id ?? null
		},
		update: {
			accountId: account.id,
			platform: body.platform,
			appVersion: body.app_version ?? null,
			pushToken: body.push_token ?? null,
			lastMemberId: body.last_member_id ?? null,
			lastSeenAt: new Date()
		}
	});

	return snakeJson({ device });
};
