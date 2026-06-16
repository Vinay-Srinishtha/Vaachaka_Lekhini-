import type { PageServerLoad } from './$types';
import { prisma } from '$lib/server/prisma';
import { parseListQuery } from '$lib/server/list-query';
import { requireRole } from '$lib/server/auth';

const SORT_COLS = ['enrolledAt', 'createdAt', 'qualityScore', 'sampleCount'] as const;

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'editor');
	const q = parseListQuery(event.url, { col: 'enrolledAt', dir: 'desc' }, SORT_COLS);
	const tab = event.url.searchParams.get('tab') === 'handwriting' ? 'handwriting' : 'voice';

	const memberWhere = q.q
		? { OR: [
			{ member: { displayName: { contains: q.q, mode: 'insensitive' as const } } },
			{ mantra: { nameRoman: { contains: q.q, mode: 'insensitive' as const } } }
		] }
		: {};

	if (tab === 'voice') {
		const [rows, total] = await Promise.all([
			prisma.voiceEnrolment.findMany({
				where: memberWhere,
				orderBy: { [q.sort.col === 'createdAt' ? 'enrolledAt' : q.sort.col]: q.sort.dir },
				skip: q.skip,
				take: q.take,
				include: {
					member: { select: { id: true, displayName: true } },
					mantra: { select: { nameRoman: true } }
				}
			}),
			prisma.voiceEnrolment.count({ where: memberWhere })
		]);
		return { tab, voiceRows: rows, hwRows: [], total, query: { q: q.q, page: q.page, pageSize: q.pageSize, sort: q.sort } };
	} else {
		const hwWhere = q.q
			? { OR: [
				{ member: { displayName: { contains: q.q, mode: 'insensitive' as const } } },
				{ mantra: { nameRoman: { contains: q.q, mode: 'insensitive' as const } } }
			] }
			: {};
		const [rows, total] = await Promise.all([
			prisma.handwritingSample.findMany({
				where: hwWhere,
				orderBy: { createdAt: q.sort.dir },
				skip: q.skip,
				take: q.take,
				include: {
					member: { select: { id: true, displayName: true } },
					mantra: { select: { nameRoman: true } }
				}
			}),
			prisma.handwritingSample.count({ where: hwWhere })
		]);
		return { tab, voiceRows: [], hwRows: rows, total, query: { q: q.q, page: q.page, pageSize: q.pageSize, sort: q.sort } };
	}
};
