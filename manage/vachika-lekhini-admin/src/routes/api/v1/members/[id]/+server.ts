import type { RequestHandler } from './$types';
import { error, json } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { requireAccount } from '$lib/server/user-auth';

/// DELETE /api/v1/members/:id  (Bearer)
/// The primary member can't be deleted directly — transfer primacy first.
export const DELETE: RequestHandler = async (event) => {
	try {
		const account = await requireAccount(event);
		const m = await prisma.member.findUnique({
			where: { id: event.params.id },
			select: { accountId: true, isPrimary: true }
		});
		if (!m) throw error(404, 'Member not found');
		if (m.accountId !== account.id) throw error(403, 'Member belongs to a different account');
		if (m.isPrimary) throw error(409, 'Cannot delete the primary member — transfer primacy first');

		await prisma.member.delete({ where: { id: event.params.id } });
		return snakeJson({ ok: true });
	} catch (e) {
		console.error(e);
		return json({ error: 'Internal error' }, { status: 500 });
	}
};
