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

	const [recentSessions, memberMetrics] = await Promise.all([
		prisma.session.findMany({
			where: { memberId: { in: memberIds } },
			orderBy: { startedAt: 'desc' },
			take: 10,
			select: {
				id: true, startedAt: true, durationSec: true, countAdded: true, modality: true,
				member: { select: { displayName: true } },
				program: { select: { mantra: { select: { nameRoman: true } } } }
			}
		}),
		// Per-member: voice sample count, handwriting sample count, total chants
		Promise.all(memberIds.map(async (memberId) => {
			const [voiceEnrolments, hwSamples, chantTotal] = await Promise.all([
				prisma.voiceEnrolment.findMany({
					where: { memberId },
					select: { mantraId: true, sampleCount: true }
				}),
				prisma.handwritingSample.count({ where: { memberId } }),
				prisma.session.aggregate({
					where: { memberId },
					_sum: { countAdded: true }
				})
			]);
			return {
				memberId,
				voiceSampleCount: voiceEnrolments.reduce((s, e) => s + e.sampleCount, 0),
				handwritingSampleCount: hwSamples,
				totalChantCount: chantTotal._sum.countAdded ?? 0
			};
		}))
	]);

	return { account, recentSessions, memberMetrics };
};
