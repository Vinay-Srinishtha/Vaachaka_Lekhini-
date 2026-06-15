import bcrypt from 'bcryptjs';
import { error, redirect } from '@sveltejs/kit';
import { prisma } from './prisma';
import {
	ADMIN_COOKIE,
	ADMIN_TOKEN_TTL_SECONDS,
	signAdminToken,
	verifyAdminToken
} from './jwt';
import type { Cookies, RequestEvent } from '@sveltejs/kit';
import { canAccessPath, type AdminRole, type RoleGate } from '../roles';

export { canAccessPath, type AdminRole };

/// Guard for server load fns and form actions.
///
///   requireRole(event, 'viewer' | 'editor')  → admin must have access to the
///       section the current request targets (all roles get full edit within
///       their sections, so 'viewer' and 'editor' are equivalent here).
///   requireRole(event, 'super_admin')         → admin must literally be a
///       super_admin (used by the /admins management page).
export function requireRole(event: RequestEvent, gate: RoleGate): NonNullable<App.Locals['admin']> {
	const admin = event.locals.admin;
	if (!admin) throw redirect(303, `/login?redirect=${encodeURIComponent(event.url.pathname)}`);
	if (gate === 'super_admin') {
		if (admin.role !== 'super_admin') throw error(403, 'Requires super admin');
		return admin;
	}
	if (!canAccessPath(admin.role, event.url.pathname)) {
		throw error(403, 'No access to this section');
	}
	return admin;
}

/// Resolve the current admin from the request cookie (or return null).
/// Used by hooks.server.ts to populate event.locals.admin.
export async function resolveAdmin(cookies: Cookies): Promise<App.Locals['admin']> {
	const token = cookies.get(ADMIN_COOKIE);
	if (!token) return null;

	const payload = await verifyAdminToken(token);
	if (!payload) return null;

	// Cheap revocation check (table is empty by default).
	const revoked = await prisma.revokedToken.findUnique({ where: { jti: payload.jti } });
	if (revoked) return null;

	return {
		id: payload.sub,
		username: payload.username,
		role: payload.role
	};
}

/// Verify username + password and issue a JWT cookie.
export async function loginAdmin(
	cookies: Cookies,
	username: string,
	password: string
): Promise<App.Locals['admin']> {
	const admin = await prisma.adminUser.findUnique({ where: { username } });
	if (!admin || !admin.isActive) {
		throw error(401, 'Invalid credentials');
	}

	const ok = await bcrypt.compare(password, admin.passwordHash);
	if (!ok) throw error(401, 'Invalid credentials');

	const { token, expiresAt } = await signAdminToken({
		sub: admin.id,
		username: admin.username,
		role: admin.role as AdminRole
	});

	cookies.set(ADMIN_COOKIE, token, {
		path: '/',
		httpOnly: true,
		sameSite: 'lax',
		secure: process.env.NODE_ENV === 'production',
		expires: expiresAt
	});

	await prisma.adminUser.update({
		where: { id: admin.id },
		data: { lastLoginAt: new Date() }
	});

	return { id: admin.id, username: admin.username, role: admin.role as AdminRole };
}

export async function logoutAdmin(cookies: Cookies, jti?: string): Promise<void> {
	if (jti) {
		// Best-effort revocation. Token would expire on its own anyway.
		await prisma.revokedToken
			.create({
				data: {
					jti,
					expiresAt: new Date(Date.now() + ADMIN_TOKEN_TTL_SECONDS * 1000)
				}
			})
			.catch(() => undefined);
	}
	cookies.delete(ADMIN_COOKIE, { path: '/' });
}
