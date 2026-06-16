import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { prisma } from '$lib/server/prisma';
import { accountDetail } from '$lib/server/accounts';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'editor');
	const account = await accountDetail(event.params.id);
	if (!account) throw error(404, 'Account not found');

	const memberIds = account.members.map((m) => m.id);
	const recentSessions = await prisma.session.findMany({
		where: { memberId: { in: memberIds } },
		orderBy: { startedAt: 'desc' },
		take: 10,
		select: {
			id: true, startedAt: true, durationSec: true, countAdded: true, modality: true,
			member: { select: { displayName: true } },
			program: { select: { mantra: { select: { nameRoman: true } } } }
		}
	});

	return { account, recentSessions };
};
