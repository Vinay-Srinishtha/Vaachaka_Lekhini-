import type { RequestHandler } from './$types';
import { z } from 'zod';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { requireAccount, setAccountPassword } from '$lib/server/user-auth';

const schema = z.object({ password: z.string().min(8).max(200) });

/// POST /api/v1/auth/password/set  (Bearer required)  { password }
/// Used to set initial password after OTP signup, or change it later.
export const POST: RequestHandler = async (event) => {
	const account = await requireAccount(event);
	const body = await readJsonBody(event, schema);
	await setAccountPassword(account.id, body.password);
	return snakeJson({ ok: true });
};
