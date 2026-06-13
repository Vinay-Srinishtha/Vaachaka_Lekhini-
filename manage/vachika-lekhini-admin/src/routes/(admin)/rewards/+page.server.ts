import type { PageServerLoad, Actions } from './$types';
import { fail } from '@sveltejs/kit';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { parseListQuery } from '$lib/server/list-query';
import { requireRole } from '$lib/server/auth';
import { getRewardRate, setRewardRate } from '$lib/server/reward-config';
import { recomputeMemberBalance } from '$lib/server/sync';
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

	const [rows, total, totals, rewardRate, members] = await Promise.all([
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
		getRewardRate(),
		prisma.member.findMany({
			orderBy: { displayName: 'asc' },
			select: { id: true, displayName: true, rewardPointsBalance: true }
		})
	]);

	return {
		events: rows,
		total,
		totals,
		kind,
		rewardRate,
		members,
		query: { q: q.q, page: q.page, pageSize: q.pageSize, sort: q.sort }
	};
};

const grantSchema = z.object({
	memberId: z.string().cuid(),
	kind: z.enum(['gift', 'refund']),
	amount: z.coerce.number().int().min(1).max(100_000),
	note: z.string().max(300).default('')
});

export const actions: Actions = {
	setRate: async (event) => {
		requireRole(event, 'editor');
		const fd = await event.request.formData();
		const raw = Number(fd.get('rate'));
		if (!Number.isFinite(raw) || raw < 1) return { error: 'Rate must be ≥ 1' };
		await setRewardRate(raw);
		emitChange('reward_event');
		return { success: true, rate: Math.max(1, Math.round(raw)) };
	},

	grantPoints: async (event) => {
		requireRole(event, 'editor');
		const fd = await event.request.formData();
		const parsed = grantSchema.safeParse({
			memberId: fd.get('memberId'),
			kind: fd.get('kind'),
			amount: fd.get('amount'),
			note: fd.get('note') ?? ''
		});
		if (!parsed.success) {
			return fail(400, { grantError: parsed.error.issues[0]?.message ?? 'Invalid input' });
		}
		const { memberId, kind, amount, note } = parsed.data;

		const member = await prisma.member.findUnique({ where: { id: memberId }, select: { id: true } });
		if (!member) return fail(404, { grantError: 'Member not found' });

		const admin = event.locals.admin;
		const source = `admin_grant${note ? ': ' + note : ''} (by ${admin?.username ?? 'admin'})`;
		await prisma.rewardEvent.create({
			data: { memberId, kind, amount, source }
		});
		await recomputeMemberBalance(memberId);
		emitChange('reward_event');
		return { grantSuccess: true };
	}
};
