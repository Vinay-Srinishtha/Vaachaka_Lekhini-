import type { RequestHandler } from './$types';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { requireAccount } from '$lib/server/user-auth';

/// GET /api/v1/me  (Bearer)
/// Returns the full account snapshot the Flutter app uses on launch and
/// foreground. Members include their running aggregates; deep history
/// (sessions / reward events) is paged through separate endpoints.
export const GET: RequestHandler = async (event) => {
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
					avatarKey: true,
					language: true,
					birthYear: true,
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
							currentStreak: true,
							longestStreak: true,
							lastActiveDate: true,
							updatedAt: true,
							mantra: { select: { slug: true } }
						}
					}
				}
			}
		}
	});

	return snakeJson({
		account: full,
		serverTime: new Date().toISOString()
	});
};
