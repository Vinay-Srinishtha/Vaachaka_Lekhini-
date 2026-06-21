import { error, isHttpError } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { snakeJson } from '$lib/server/snake-case';
import { prisma } from '$lib/server/prisma';

// Simulator accounts are doubly tagged: a reserved mobile range
// (9900000000 + index) AND a primary member named "SIM_<index>". We require
// BOTH so a real user who merely happens to have a 990… number can never be
// deleted. All Member/Program/Session/RewardEvent/etc. rows cascade-delete from
// Account (onDelete: Cascade), so removing the accounts removes only their data.
const SIM_LO = '9900000000';
const SIM_HI = '9900999999';
const SIM_NAME_PREFIX = 'SIM_';

const simWhere = {
	mobile: { gte: SIM_LO, lte: SIM_HI },
	members: { some: { displayName: { startsWith: SIM_NAME_PREFIX } } }
} as const;

/// POST /api/v1/sim/clear  → { deleted, sadhanasAdjusted }
/// Deletes ONLY simulator-created accounts (and, via cascade, only their data).
/// Scoped to the reserved mobile range AND the SIM_ member-name signature.
///
/// GlobalSadhana.currentCount is a denormalized counter that sessions only ever
/// increment — a plain cascade delete would leave it inflated. So before
/// deleting we roll back each sadhana's count by exactly what the sim members
/// contributed, and re-open any sadhana the sim load had pushed to 'completed'.
export const POST: RequestHandler = async () => {
	try {
		// Sim member ids (both tags) — used to scope the contribution rollback.
		const simMembers = await prisma.member.findMany({
			where: {
				displayName: { startsWith: SIM_NAME_PREFIX },
				account: { mobile: { gte: SIM_LO, lte: SIM_HI } }
			},
			select: { id: true }
		});
		const memberIds = simMembers.map((m) => m.id);

		let sadhanasAdjusted = 0;
		if (memberIds.length > 0) {
			const byS = await prisma.globalSadhanaContribution.groupBy({
				by: ['globalSadhanaId'],
				where: { memberId: { in: memberIds } },
				_sum: { countAdded: true }
			});
			for (const row of byS) {
				const back = row._sum.countAdded ?? 0;
				if (back <= 0) continue;
				await prisma.$transaction(async (tx) => {
					const gs = await tx.globalSadhana.findUnique({
						where: { id: row.globalSadhanaId },
						select: { currentCount: true, targetCount: true, status: true }
					});
					if (!gs) return;
					const next = Math.max(0, gs.currentCount - back);
					await tx.globalSadhana.update({
						where: { id: row.globalSadhanaId },
						data: {
							currentCount: next,
							// Re-open if the sim load is what had completed it.
							...(gs.status === 'completed' && next < gs.targetCount
								? { status: 'active', completedAt: null }
								: {})
						}
					});
				});
				sadhanasAdjusted++;
			}
		}

		const result = await prisma.account.deleteMany({ where: simWhere });
		return snakeJson({ deleted: result.count, sadhanasAdjusted });
	} catch (e) {
		if (isHttpError(e)) throw e;
		console.error('[sim/clear]', e);
		throw error(500, { code: 'server_error', message: 'Failed to clear sim data' });
	}
};

/// GET → count how many sim accounts currently exist (handy for the UI).
export const GET: RequestHandler = async () => {
	const count = await prisma.account.count({ where: simWhere });
	return snakeJson({ count });
};
