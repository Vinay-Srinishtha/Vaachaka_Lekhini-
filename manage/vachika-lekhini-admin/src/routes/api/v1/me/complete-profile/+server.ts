import type { RequestHandler } from './$types';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { readJsonBody } from '$lib/server/json-input';
import { requireAccount } from '$lib/server/user-auth';
import { recomputeMemberBalance } from '$lib/server/sync';

const bodySchema = z.object({
	member_id: z.string().min(1),
	gender: z.string().nullable().optional(),
	birth_year: z.number().int().min(1900).max(2100).nullable().optional(),
	mother_tongue: z.string().nullable().optional()
});

/// POST /api/v1/me/complete-profile  (Bearer)
/// Updates profile fields and, if this is the first time all required fields
/// are present, awards 50 reward points and sets profileCompletedAt.
/// Idempotent — calling it again after completion does not re-award points.
export const POST: RequestHandler = async (event) => {
	const account = await requireAccount(event);
	const body = await readJsonBody(event, bodySchema);

	const member = await prisma.member.findUnique({
		where: { id: body.member_id },
		select: { accountId: true, profileCompletedAt: true, displayName: true, gender: true, birthYear: true, motherTongue: true }
	});
	if (!member) {
		return snakeJson({ ok: false, error: 'Member not found' }, { status: 404 });
	}
	if (member.accountId !== account.id) {
		return snakeJson({ ok: false, error: 'Forbidden' }, { status: 403 });
	}

	// Merge incoming fields with existing values to evaluate completeness.
	const gender = body.gender !== undefined ? body.gender : member.gender;
	const birthYear = body.birth_year !== undefined ? body.birth_year : member.birthYear;
	const motherTongue = body.mother_tongue !== undefined ? body.mother_tongue : member.motherTongue;

	const isComplete = !!gender && !!birthYear && !!motherTongue && !!member.displayName;
	const alreadyRewarded = !!member.profileCompletedAt;
	const awardNow = isComplete && !alreadyRewarded;

	await prisma.$transaction(async (tx) => {
		await tx.member.update({
			where: { id: body.member_id },
			data: {
				gender: body.gender !== undefined ? body.gender : undefined,
				birthYear: body.birth_year !== undefined ? body.birth_year : undefined,
				motherTongue: body.mother_tongue !== undefined ? body.mother_tongue : undefined,
				...(awardNow ? { profileCompletedAt: new Date() } : {})
			}
		});

		if (awardNow) {
			await tx.rewardEvent.create({
				data: {
					memberId: body.member_id,
					kind: 'earn',
					amount: 50,
					source: 'profile_completion'
				}
			});
		}
	});

	const newBalance = await recomputeMemberBalance(body.member_id);

	return snakeJson({
		ok: true,
		rewarded: awardNow,
		points_awarded: awardNow ? 50 : 0,
		new_balance: newBalance,
		profile_completed: isComplete
	});
};
