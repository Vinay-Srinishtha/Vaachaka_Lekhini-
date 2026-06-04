import type { PageServerLoad, Actions } from './$types';
import { fail } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { listAccounts, ACCOUNT_SORT_COLS } from '$lib/server/accounts';
import { parseListQuery } from '$lib/server/list-query';
import { requireRole } from '$lib/server/auth';

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'editor');
	const query = parseListQuery(event.url, { col: 'createdAt', dir: 'desc' }, ACCOUNT_SORT_COLS);
	const { rows, total } = await listAccounts({
		q: query.q,
		skip: query.skip,
		take: query.take,
		sort: query.sort
	});
	return {
		accounts: rows,
		total,
		query: { q: query.q, page: query.page, pageSize: query.pageSize, sort: query.sort }
	};
};

export const actions: Actions = {
	toggleBan: async (event) => {
		requireRole(event, 'editor');
		const data = await event.request.formData();
		const id = String(data.get('id') ?? '');
		const reason = String(data.get('reason') ?? '').trim() || null;
		if (!id) return fail(400, { error: 'Missing id' });

		const cur = await prisma.account.findUnique({ where: { id }, select: { isBanned: true } });
		if (!cur) return fail(404, { error: 'Account not found' });
		await prisma.account.update({
			where: { id },
			data: { isBanned: !cur.isBanned, bannedReason: !cur.isBanned ? reason : null }
		});
		return { ok: true };
	}
};
