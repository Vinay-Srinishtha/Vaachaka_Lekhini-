import bcrypt from 'bcryptjs';
import { error } from '@sveltejs/kit';
import type { RequestEvent } from '@sveltejs/kit';
import { prisma } from './prisma';
import { signUserAccessToken, signUserRefreshToken, verifyUserToken } from './user-jwt';

export interface AuthedAccount {
	id: string;
	mobile: string;
	countryCode: string;
	isBanned: boolean;
}

/// Mint a new access + refresh token pair for [accountId].
export async function issueTokensFor(accountId: string, mobile: string) {
	const access = await signUserAccessToken({ sub: accountId, mobile });
	const refresh = await signUserRefreshToken({ sub: accountId });
	return {
		access_token: access.token,
		access_token_expires_at: access.expiresAt.toISOString(),
		refresh_token: refresh.token,
		refresh_token_expires_at: refresh.expiresAt.toISOString()
	};
}

/// Resolve the bearer token on a public-API request.
/// Returns the account or throws 401/403. Refuses banned accounts.
export async function requireAccount(event: RequestEvent): Promise<AuthedAccount> {
	const auth = event.request.headers.get('authorization');
	if (!auth || !auth.startsWith('Bearer ')) {
		throw error(401, 'Missing bearer token');
	}
	const token = auth.slice('Bearer '.length).trim();
	const payload = await verifyUserToken(token, 'access');
	if (!payload || payload.scope !== 'access') throw error(401, 'Invalid token');

	const account = await prisma.account.findUnique({
		where: { id: payload.sub },
		select: { id: true, mobile: true, countryCode: true, isBanned: true }
	});
	if (!account) throw error(401, 'Account no longer exists');
	if (account.isBanned) throw error(403, 'Account is banned');

	// Touch lastSeenAt — best-effort, don't block on it.
	void prisma.account.update({
		where: { id: account.id },
		data: { lastSeenAt: new Date() }
	}).catch(() => undefined);

	return account;
}

export async function setAccountPassword(accountId: string, password: string): Promise<void> {
	if (password.length < 8) throw error(400, 'Password must be at least 8 characters');
	const hash = await bcrypt.hash(password, 10);
	await prisma.account.update({
		where: { id: accountId },
		data: { passwordHash: hash, passwordSetAt: new Date() }
	});
}

export async function verifyAccountPassword(
	mobile: string,
	password: string
): Promise<AuthedAccount | null> {
	const account = await prisma.account.findUnique({
		where: { mobile },
		select: {
			id: true,
			mobile: true,
			countryCode: true,
			passwordHash: true,
			isBanned: true
		}
	});
	if (!account || !account.passwordHash) return null;
	const ok = await bcrypt.compare(password, account.passwordHash);
	if (!ok) return null;
	return {
		id: account.id,
		mobile: account.mobile,
		countryCode: account.countryCode,
		isBanned: account.isBanned
	};
}

/// Find-or-create the Account for [mobile]. Used on successful OTP verify.
/// The caller's username is used as the primary member's display name.
export async function ensureAccount(
	mobile: string,
	username: string,
	countryCode = '+91'
): Promise<AuthedAccount> {
	let account = await prisma.account.findUnique({
		where: { mobile },
		select: { id: true, mobile: true, countryCode: true, isBanned: true }
	});
	if (account) return account;

	const created = await prisma.account.create({
		data: {
			mobile,
			countryCode,
			members: {
				create: {
					displayName: username,
					isPrimary: true
				}
			}
		},
		select: { id: true, mobile: true, countryCode: true, isBanned: true }
	});
	return created;
}
