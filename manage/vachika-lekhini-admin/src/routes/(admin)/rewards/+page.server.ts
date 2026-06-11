import type { PageServerLoad, Actions } from './$types';
import { prisma } from '$lib/server/prisma';
import { parseListQuery } from '$lib/server/list-query';
import { requireRole } from '$lib/server/auth';
import { getRewardRate, setRewardRate } from '$lib/server/reward-config';
import { emitChange } from '$lib/server/live';

const SORT_COLS = ['occurredAt', 'amount'] as const;

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'editor');
	const q = parseListQuery(event.url, { col: 'occurredAt', dir: 'desc' }, SORT_COLS);

	const kind = event.url.searchParams.get('kind') ?? '';

	const where: Record<string, unknown> = {};
	if (['earn', 'spend', 'milestone', 'gift', 'refund'].includes(kind)) {
		where.kind = kind;
	}
	if (q.q) {
		where.OR = [
			{ member: { displayName: { contains: q.q, mode: 'insensitive' } } },
			{ source: { contains: q.q, mode: 'insensitive' } }
		];
	}

	const [rows, total, totals, rewardRate] = await Promise.all([
		prisma.rewardEvent.findMany({
			where,
			orderBy: { [q.sort.col]: q.sort.dir },
			skip: q.skip,
			take: q.take,
			include: {
				member: { select: { id: true, displayName: true, rewardPointsBalance: true } },
				storeItem: { select: { name: true } }
			}
		}),
		prisma.rewardEvent.count({ where }),
		prisma.rewardEvent.groupBy({
			by: ['kind'],
			_sum: { amount: true },
			_count: true
		}),
		getRewardRate()
	]);

	return {
		events: rows,
		total,
		totals,
		kind,
		rewardRate,
		query: { q: q.q, page: q.page, pageSize: q.pageSize, sort: q.sort }
	};
};

export const actions: Actions = {
	setRate: async (event) => {
		requireRole(event, 'editor');
		const fd = await event.request.formData();
		const raw = Number(fd.get('rate'));
		if (!Number.isFinite(raw) || raw < 1) return { error: 'Rate must be ≥ 1' };
		await setRewardRate(raw);
		emitChange('reward_event');
		return { success: true, rate: Math.max(1, Math.round(raw)) };
	}
};
