import { fail, type RequestEvent } from '@sveltejs/kit';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { requireRole } from '$lib/server/auth';
import { ADMIN_ROLES, ROLE_LABELS } from '$lib/constants';
import { ALL_PERMISSIONS, DEFAULT_PERMISSIONS } from '$lib/permissions';

export const load = async (event: RequestEvent) => {
	requireRole(event, 'super_admin');

	// Load all role configs; create missing ones with defaults on-the-fly.
	const configs = await prisma.adminRoleConfig.findMany();
	const configMap = Object.fromEntries(configs.map((c) => [c.role, c.permissions]));

	const roles = ADMIN_ROLES.map((role) => ({
		role,
		label: ROLE_LABELS[role],
		permissions: configMap[role] ?? DEFAULT_PERMISSIONS[role] ?? [],
		updatedAt: configs.find((c) => c.role === role)?.updatedAt ?? null
	}));

	// Count admins per role for display.
	const counts = await prisma.adminUser.groupBy({ by: ['role'], _count: true });
	const adminCounts = Object.fromEntries(counts.map((c) => [c.role, c._count]));

	return { roles, adminCounts, allPermissions: ALL_PERMISSIONS };
};

const saveSchema = z.object({
	role: z.enum(ADMIN_ROLES),
	permissions: z.array(z.string()).default([])
});

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

		// Validate all submitted keys exist in our defined set.
		const invalid = permissions.filter((p) => !ALL_PERMISSIONS.includes(p));
		if (invalid.length) return fail(400, { error: `Unknown permission keys: ${invalid.join(', ')}` });

		await prisma.adminRoleConfig.upsert({
			where: { role },
			create: { role, permissions },
			update: { permissions }
		});

		return { success: true, role };
	}
};
