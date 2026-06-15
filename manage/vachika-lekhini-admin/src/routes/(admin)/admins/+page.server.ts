import type { PageServerLoad, Actions } from './$types';
import { fail, redirect } from '@sveltejs/kit';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { parseListQuery } from '$lib/server/list-query';
import { requireRole } from '$lib/server/auth';
import { ADMIN_ROLES } from '$lib/constants';
import { patchQuery } from '$lib/url';

const SORT_COLS = ['username', 'role', 'createdAt', 'lastLoginAt', 'isActive'] as const;

export const load: PageServerLoad = async (event) => {
	requireRole(event, 'super_admin');
	const query = parseListQuery(event.url, { col: 'createdAt', dir: 'desc' }, SORT_COLS);

	const where = query.q
		? {
				OR: [
					{ username: { contains: query.q, mode: 'insensitive' as const } },
					{ email: { contains: query.q, mode: 'insensitive' as const } }
				]
			}
		: {};

	const [rows, total] = await prisma.$transaction([
		prisma.adminUser.findMany({
			where,
			orderBy: { [query.sort.col]: query.sort.dir },
			skip: query.skip,
			take: query.take,
			select: {
				id: true,
				username: true,
				email: true,
				role: true,
				isActive: true,
				createdAt: true,
				lastLoginAt: true
			}
		}),
		prisma.adminUser.count({ where })
	]);

	return {
		admins: rows,
		total,
		query: { q: query.q, page: query.page, pageSize: query.pageSize, sort: query.sort }
	};
};

const createSchema = z.object({
	username: z.string().min(3).max(40).regex(/^[a-z][a-z0-9_]*$/i, 'Letters, digits, underscores only.'),
	email: z.string().email().optional().or(z.literal('')),
	password: z.string().min(8).max(200),
	role: z.enum(ADMIN_ROLES)
});

export const actions: Actions = {
	create: async (event) => {
		requireRole(event, 'super_admin');
		const data = await event.request.formData();
		const parsed = createSchema.safeParse({
			username: String(data.get('username') ?? '').trim(),
			email: String(data.get('email') ?? '').trim(),
			password: String(data.get('password') ?? ''),
			role: String(data.get('role') ?? 'main_admin')
		});
		if (!parsed.success) {
			const fieldErrors: Record<string, string> = {};
			for (const issue of parsed.error.issues) {
				const k = issue.path.join('.') || '_';
				if (!fieldErrors[k]) fieldErrors[k] = issue.message;
			}
			return fail(400, {
				fieldErrors,
				values: Object.fromEntries(data),
				action: 'create'
			});
		}
		const dup = await prisma.adminUser.findUnique({
			where: { username: parsed.data.username },
			select: { id: true }
		});
		if (dup) {
			return fail(409, {
				fieldErrors: { username: 'Username taken.' },
				values: Object.fromEntries(data),
				action: 'create'
			});
		}
		await prisma.adminUser.create({
			data: {
				username: parsed.data.username,
				email: parsed.data.email || null,
				passwordHash: await bcrypt.hash(parsed.data.password, 10),
				role: parsed.data.role
			}
		});
		throw redirect(303, patchQuery(event.url, { new: null }));
	},

	setRole: async (event) => {
		const admin = requireRole(event, 'super_admin');
		const data = await event.request.formData();
		const id = String(data.get('id') ?? '');
		const role = String(data.get('role') ?? '');
		if (!ADMIN_ROLES.includes(role as any)) return fail(400, { error: 'Invalid role' });
		if (id === admin.id) return fail(400, { error: "You can't change your own role." });
		await prisma.adminUser.update({ where: { id }, data: { role: role as any } });
		return { ok: true };
	},

	toggleActive: async (event) => {
		const admin = requireRole(event, 'super_admin');
		const data = await event.request.formData();
		const id = String(data.get('id') ?? '');
		if (id === admin.id) return fail(400, { error: "You can't deactivate yourself." });
		const cur = await prisma.adminUser.findUnique({ where: { id }, select: { isActive: true } });
		if (!cur) return fail(404, { error: 'Admin not found' });
		await prisma.adminUser.update({ where: { id }, data: { isActive: !cur.isActive } });
		return { ok: true };
	}
};
