/// Client-safe role helpers. The server module re-exports these so call
/// sites in server code keep using `$lib/server/auth`.
///
/// Access model is capability-based (NOT a linear hierarchy). Each role maps
/// to an explicit set of accessible sections. A section is identified by the
/// first path segment ('/config/new' → 'config', '/' → 'dashboard'). A role
/// that can access a section has full read+write within it.
///
///   • super_admin        — everything; can create admin accounts.
///   • main_admin         — everything EXCEPT support, feedback, otp-log,
///                          devices, admins.
///   • assets_admin       — config only.
///   • marketplace_admin  — store only.

import { ADMIN_ROLES, ROLE_LABELS, type AdminRole } from './constants';

/// Gate keyword accepted by requireRole(). Kept independent of AdminRole so
/// existing call sites that pass 'viewer'/'editor' (= "needs section access")
/// keep working. 'super_admin' means "must literally be a super admin".
export type RoleGate = 'viewer' | 'editor' | 'super_admin';

/// '*' means every section.
const ROLE_SECTIONS: Record<AdminRole, readonly string[] | '*'> = {
	super_admin: '*',
	main_admin: [
		'dashboard',
		'leaderboard',
		'mantras',
		'quotes',
		'global-sadhana',
		'store',
		'faqs',
		'app-settings',
		'config',
		'accounts',
		'programs',
		'sessions',
		'rewards',
		'reward-rules',
		'invites'
	],
	assets_admin: ['config'],
	marketplace_admin: ['store']
};

/// Map a request path to its section key. Returns null for paths that should
/// not be section-gated (non-reward admin APIs), which callers treat as
/// "allowed for any authenticated admin".
export function sectionForPath(path: string): string | null {
	if (path.startsWith('/api/admin/reward-rate')) return 'rewards';
	if (path.startsWith('/api')) return null;
	const seg = path.split('/').filter(Boolean)[0];
	return seg ?? 'dashboard';
}

export function canAccessSection(
	role: AdminRole | undefined | null,
	section: string | null
): boolean {
	if (section === null) return true; // un-gated (authenticated already checked)
	if (!role) return false;
	const allowed = ROLE_SECTIONS[role];
	if (!allowed) return false;
	if (allowed === '*') return true;
	return allowed.includes(section);
}

export function canAccessPath(role: AdminRole | undefined | null, path: string): boolean {
	return canAccessSection(role, sectionForPath(path));
}

/// The landing route for a role — where to send them from '/' when the
/// dashboard isn't in their accessible set.
export function roleHome(role: AdminRole | undefined | null): string {
	switch (role) {
		case 'assets_admin':
			return '/config';
		case 'marketplace_admin':
			return '/store';
		default:
			return '/';
	}
}

export { ADMIN_ROLES, ROLE_LABELS, type AdminRole };
