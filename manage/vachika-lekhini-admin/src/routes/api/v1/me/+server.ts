import { json, type RequestHandler } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { requireAccount } from '$lib/server/user-auth';

/// GET /api/v1/me  (Bearer)
/// Returns the full account snapshot the Flutter app uses on launch and
/// foreground. Members include their running aggregates; deep history
/// (sessions / reward events) is paged through separate endpoints.
export const GET: RequestHandler = async (event) => {
	try {
		const account = await requireAccount(event);

		const full = await prisma.account.findUnique({
			where: { id: account.id },
			select: {
				id: true,
				mobile: true,
				countryCode: true,
				referralCode: true,
				passwordSetAt: true,
				createdAt: true,
				lastSeenAt: true,
				members: {
					orderBy: [{ isPrimary: 'desc' }, { createdAt: 'asc' }],
					select: {
						id: true,
						displayName: true,
						relation: true,
						gender: true,
						birthYear: true,
						motherTongue: true,
						avatarKey: true,
						language: true,
						mantraLanguage: true,
						preferences: true,
						isPrimary: true,
						rewardPointsBalance: true,
						createdAt: true,
						updatedAt: true,
						lastActiveAt: true,
						programs: {
							select: {
								id: true,
								mantraId: true,
								targetWritings: true,
								targetDays: true,
								startedAt: true,
								completedAt: true,
								totalWritings: true,
								totalChants: true,
								currentStreak: true,
								longestStreak: true,
								lastActiveDate: true,
								updatedAt: true,
								mantra: { select: { slug: true, shareImageUrl: true, shareText: true } }
							}
						},
						rewardEvents: {
							where: { kind: 'spend', storeItemId: { not: null } },
							select: { id: true, storeItemId: true, amount: true, source: true, occurredAt: true }
						}
					}
				}
			}
		});

		return snakeJson({
			account: full,
			serverTime: new Date().toISOString()
		});
	} catch (e) {
		console.error(e);
		return json({ error: 'Internal error' }, { status: 500 });
	}
};

/// DELETE /api/v1/me  (Bearer)
/// Hard-deletes the account and all owned data. Cascade rules in Prisma
/// handle Members → Programs → Sessions → RewardEvents automatically.
export const DELETE: RequestHandler = async (event) => {
	try {
		const account = await requireAccount(event);
		await prisma.account.delete({ where: { id: account.id } });
		return new Response(null, { status: 204 });
	} catch (e) {
		console.error(e);
		return json({ error: 'Internal error' }, { status: 500 });
	}
};
