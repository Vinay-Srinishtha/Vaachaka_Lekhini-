import type { PageServerLoad } from './$types';
import { prisma } from '$lib/server/prisma';

/// Dashboard aggregates — single round trip via $transaction.
export const load: PageServerLoad = async () => {
	const [
		mantraCount,
		activeMantras,
		storeCount,
		flagCount,
		accountCount,
		bannedAccountCount,
		memberCount,
		programCount,
		sessionCount,
		recentAccounts
	] = await prisma.$transaction([
		prisma.mantra.count(),
		prisma.mantra.count({ where: { isActive: true } }),
		prisma.storeItem.count({ where: { isActive: true } }),
		prisma.featureFlag.count(),
		prisma.account.count(),
		prisma.account.count({ where: { isBanned: true } }),
		prisma.member.count(),
		prisma.program.count(),
		prisma.session.count(),
		prisma.account.findMany({
			orderBy: { createdAt: 'desc' },
			take: 5,
			select: {
				id: true,
				mobile: true,
				createdAt: true,
				isBanned: true,
				_count: { select: { members: true } }
			}
		})
	]);

	const topMantras = await prisma.program.groupBy({
		by: ['mantraId'],
		_count: { mantraId: true },
		orderBy: { _count: { mantraId: 'desc' } },
		take: 5
	});
	const topMantraRows = topMantras.length
		? await prisma.mantra.findMany({
				where: { id: { in: topMantras.map((t) => t.mantraId) } },
				select: { id: true, nameRoman: true, slug: true }
			})
		: [];
	const topMantraView = topMantras.map((t) => ({
		mantra: topMantraRows.find((r) => r.id === t.mantraId)!,
		count: t._count.mantraId
	}));

	return {
		stats: {
			mantraCount,
			activeMantras,
			storeCount,
			flagCount,
			accountCount,
			bannedAccountCount,
			memberCount,
			programCount,
			sessionCount
		},
		recentAccounts,
		topMantras: topMantraView
	};
};
