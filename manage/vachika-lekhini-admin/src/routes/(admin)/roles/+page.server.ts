import { fail, type RequestEvent } from '@sveltejs/kit';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';
import { ADMIN_ROLES, ROLE_LABELS } from '$lib/constants';
import { ALL_PERMISSIONS, DEFAULT_PERMISSIONS } from '$lib/permissions';

export const load = async (event: RequestEvent) => {
	requireRole(event, 'super_admin');

	// Load built-in role configs.
	const configs = await prisma.adminRoleConfig.findMany();
	const configMap = Object.fromEntries(configs.map((c) => [c.role, c.permissions]));

	const builtInRoles = ADMIN_ROLES.map((role) => ({
		role,
		label: ROLE_LABELS[role],
		permissions: configMap[role] ?? DEFAULT_PERMISSIONS[role] ?? [],
		updatedAt: configs.find((c) => c.role === role)?.updatedAt ?? null,
		isCustom: false
	}));

	// Load custom roles.
	const customRoles = await prisma.customAdminRole.findMany({ orderBy: { createdAt: 'asc' } });
	const customRoleEntries = customRoles.map((r) => ({
		role: r.key,
		label: r.label,
		permissions: r.permissions,
		updatedAt: r.updatedAt,
		isCustom: true
	}));

	const roles = [...builtInRoles, ...customRoleEntries];

	// Count admins per built-in role.
	const counts = await prisma.adminUser.groupBy({ by: ['role'], _count: true });
	const adminCounts = Object.fromEntries(counts.map((c) => [c.role, c._count]));

	return { roles, adminCounts, allPermissions: ALL_PERMISSIONS };
};

const saveSchema = z.object({
	role: z.string().min(1),
	permissions: z.array(z.string()).default([])
});

const createSchema = z.object({
	key: z
		.string()
		.min(2)
		.max(40)
		.regex(/^[a-z][a-z0-9_]*$/, 'Key must be lowercase letters, digits or underscores'),
	label: z.string().min(2).max(60),
	permissions: z.array(z.string()).default([])
});

const deleteSchema = z.object({ key: z.string().min(1) });

export const actions = {
	save: async (event: RequestEvent) => {
		requireRole(event, 'super_admin');
		const fd = await event.request.formData();

		const parsed = saveSchema.safeParse({
			role: fd.get('role'),
			permissions: fd.getAll('permissions')
		});
		if (!parsed.success) return fail(400, { error: 'Invalid input.' });

		const { role, permissions } = parsed.data;

		const invalid = permissions.filter((p) => !ALL_PERMISSIONS.includes(p));
		if (invalid.length) return fail(400, { error: `Unknown permission keys: ${invalid.join(', ')}` });

		// Built-in role?
		if ((ADMIN_ROLES as readonly string[]).includes(role)) {
			await prisma.adminRoleConfig.upsert({
				where: { role: role as never },
				create: { role: role as never, permissions },
				update: { permissions }
			});
		} else {
			// Custom role — update by key.
			const existing = await prisma.customAdminRole.findUnique({ where: { key: role } });
			if (!existing) return fail(404, { error: 'Role not found.' });
			await prisma.customAdminRole.update({ where: { key: role }, data: { permissions } });
		}

		return { success: true, role };
	},

	create: async (event: RequestEvent) => {
		requireRole(event, 'super_admin');
		const fd = await event.request.formData();

		const parsed = createSchema.safeParse({
			key: fd.get('key'),
			label: fd.get('label'),
			permissions: fd.getAll('permissions')
		});
		if (!parsed.success) {
			const msg = parsed.error.errors[0]?.message ?? 'Invalid input.';
			return fail(400, { error: msg });
		}

		const { key, label, permissions } = parsed.data;

		if ((ADMIN_ROLES as readonly string[]).includes(key))
			return fail(400, { error: `"${key}" is a reserved role key.` });

		const invalid = permissions.filter((p) => !ALL_PERMISSIONS.includes(p));
		if (invalid.length) return fail(400, { error: `Unknown permission keys: ${invalid.join(', ')}` });

		try {
			await prisma.customAdminRole.create({ data: { key, label, permissions } });
		} catch {
			return fail(400, { error: `A role with key "${key}" already exists.` });
		}

		return { success: true, created: key };
	},

	delete: async (event: RequestEvent) => {
		requireRole(event, 'super_admin');
		const fd = await event.request.formData();

		const parsed = deleteSchema.safeParse({ key: fd.get('key') });
		if (!parsed.success) return fail(400, { error: 'Invalid input.' });

		const { key } = parsed.data;

		if ((ADMIN_ROLES as readonly string[]).includes(key))
			return fail(400, { error: 'Built-in roles cannot be deleted.' });

		await prisma.customAdminRole.deleteMany({ where: { key } });
		return { success: true, deleted: key };
	}
};
