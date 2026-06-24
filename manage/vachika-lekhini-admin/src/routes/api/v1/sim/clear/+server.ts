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

// In range AND (has a SIM_ member  OR  has no members at all — orphan rows from
// a failed provision). A real user in this range would have a non-SIM member,
// so they are still never matched.
const simWhere = {
	mobile: { gte: SIM_LO, lte: SIM_HI },
	OR: [
		{ members: { some: { displayName: { startsWith: SIM_NAME_PREFIX } } } },
		{ members: { none: {} } }
	]
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
		// Roll back each Global Sadhana's denormalised currentCount by exactly
		// what sim members contributed — done entirely in SQL so it scales to
		// any number of sim members (no huge IN list loaded into JS). Re-opens
		// any sadhana the sim load had pushed to 'completed'.
		const sadhanasAdjusted: number = await prisma.$executeRawUnsafe(
			`WITH sums AS (
				SELECT c."globalSadhanaId" AS gid, SUM(c."countAdded")::int AS s
				FROM "GlobalSadhanaContribution" c
				JOIN "Member" m ON m.id = c."memberId"
				JOIN "Account" a ON a.id = m."accountId"
				WHERE a.mobile BETWEEN '${SIM_LO}' AND '${SIM_HI}'
				  AND m."displayName" LIKE '${SIM_NAME_PREFIX}%'
				GROUP BY c."globalSadhanaId"
			)
			UPDATE "GlobalSadhana" g
			SET "currentCount" = GREATEST(0, g."currentCount" - sums.s),
			    status = CASE WHEN g.status = 'completed'::"GlobalSadhanaStatus"
			                   AND (g."currentCount" - sums.s) < g."targetCount"
			                  THEN 'active'::"GlobalSadhanaStatus" ELSE g.status END,
			    "completedAt" = CASE WHEN g.status = 'completed'::"GlobalSadhanaStatus"
			                          AND (g."currentCount" - sums.s) < g."targetCount"
			                         THEN NULL ELSE g."completedAt" END
			FROM sums WHERE g.id = sums.gid`
		);

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
