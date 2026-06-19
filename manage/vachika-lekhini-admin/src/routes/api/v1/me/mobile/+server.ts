import { error, json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { readJsonBody } from '$lib/server/json-input';
import { snakeJson } from '$lib/server/snake-case';
import { otpService } from '$lib/server/otp';
import { requireAccount } from '$lib/server/user-auth';

const mobileSchema = z
	.string()
	.regex(/^(\+91)?[6-9]\d{9}$/, 'Invalid Indian mobile number')
	.transform((m) => m.replace(/^\+91/, ''));

const schema = z.object({
	new_mobile: mobileSchema,
	otp: z.string().regex(/^\d{4,8}$/, 'OTP must be 4–8 digits')
});

/// PUT /api/v1/me/mobile  (Bearer)
/// Verifies the OTP sent to new_mobile and updates the account's mobile number.
/// The client must first call POST /api/v1/auth/otp/start with new_mobile to
/// trigger the OTP send before calling this endpoint.
export const PUT: RequestHandler = async (event) => {
	try {
		const account = await requireAccount(event);
		const body = await readJsonBody(event, schema);

		// Verify OTP against the new mobile number.
		const result = await otpService().verify(body.new_mobile, body.otp);
		if (!result.ok) throw error(401, result.error);

		// Reject if the new number is the same as the current one.
		const current = await prisma.account.findUnique({
			where: { id: account.id },
			select: { mobile: true }
		});
		if (current?.mobile === body.new_mobile) {
			throw error(400, 'New number is the same as the current number.');
		}

		// Reject if the new number is already in use by another account.
		const taken = await prisma.account.findUnique({
			where: { mobile: body.new_mobile },
			select: { id: true }
		});
		if (taken && taken.id !== account.id) {
			throw error(409, 'This mobile number is already registered to another account.');
		}

		// Persist the change.
		const updated = await prisma.account.update({
			where: { id: account.id },
			data: { mobile: body.new_mobile },
			select: { id: true, mobile: true, countryCode: true }
		});

		return snakeJson({ account: updated });
	} catch (e) {
		console.error(e);
		return json({ error: 'Internal error' }, { status: 500 });
	}
};
