/// Client-safe role helpers. The server module re-exports these so call
/// sites in server code keep using `$lib/server/auth`.

import { ADMIN_ROLES, type AdminRole } from './constants';

const ROLE_RANK: Record<AdminRole, number> = {
	viewer: 0,
	editor: 1,
	super_admin: 2
};

export function hasRole(role: AdminRole | undefined | null, min: AdminRole): boolean {
	if (!role) return false;
	return ROLE_RANK[role] >= ROLE_RANK[min];
}

export { ADMIN_ROLES, type AdminRole };
