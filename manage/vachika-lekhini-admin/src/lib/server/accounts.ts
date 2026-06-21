import { prisma } from './prisma';

export const ACCOUNT_SORT_COLS = ['mobile', 'createdAt', 'lastSeenAt', 'isBanned'] as const;

export interface ListAccountsArgs {
	q: string;
	skip: number;
	take: number;
	sort: { col: string; dir: 'asc' | 'desc' };
}

/// Accounts list + total in one round trip. Includes member count + a
/// peek at the primary member's display name for quick scanning.
export async function listAccounts(args: ListAccountsArgs) {
	const where = args.q
		? {
				OR: [
					{ mobile: { contains: args.q, mode: 'insensitive' as const } },
					{ countryCode: { contains: args.q, mode: 'insensitive' as const } },
					{ referralCode: { contains: args.q, mode: 'insensitive' as const } },
					{ members: { some: { displayName: { contains: args.q, mode: 'insensitive' as const } } } }
				]
			}
		: {};

	const [rows, total] = await prisma.$transaction([
		prisma.account.findMany({
			where,
			orderBy: { [args.sort.col]: args.sort.dir },
			skip: args.skip,
			take: args.take,
			select: {
				id: true,
				mobile: true,
				countryCode: true,
				referralCode: true,
				isBanned: true,
				bannedReason: true,
				passwordSetAt: true,
				createdAt: true,
				lastSeenAt: true,
				_count: { select: { members: true, devices: true } },
				members: {
					orderBy: { isPrimary: 'desc' as const },
					select: {
						isPrimary: true,
						displayName: true,
						// Voice is registered when a VoiceEnrolment row exists.
						_count: { select: { voiceEnrolments: true } },
						// Handwriting is registered only via a personalised sample
						// (the default-font mode isn't the user's own writing).
						handwritingSamples: {
							where: { mode: { not: 'useDefaultFont' as const } },
							select: { id: true },
							take: 1
						}
					}
				}
			}
		}),
		prisma.account.count({ where })
	]);

	// Roll per-member enrolment up to an account-level flag (any member counts).
	const augmented = rows.map((a) => ({
		...a,
		hasVoice: a.members.some((m) => m._count.voiceEnrolments > 0),
		hasHandwriting: a.members.some((m) => m.handwritingSamples.length > 0)
	}));

	return { rows: augmented, total };
}

export async function accountDetail(id: string) {
	return prisma.account.findUnique({
		where: { id },
		include: {
			_count: { select: { members: true, devices: true } },
			members: {
				orderBy: [{ isPrimary: 'desc' }, { createdAt: 'asc' }],
				include: {
					_count: {
						select: { programs: true, sessions: true, rewardEvents: true }
					}
				}
			},
			devices: {
				orderBy: { lastSeenAt: 'desc' },
				take: 5
			}
		}
	});
}
