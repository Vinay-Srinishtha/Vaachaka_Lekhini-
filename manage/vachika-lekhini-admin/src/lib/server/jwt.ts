import { SignJWT, jwtVerify } from 'jose';
import { env } from '$env/dynamic/private';
import type { AdminRole } from '../constants';

const TOKEN_TTL_SECONDS = 60 * 60 * 12; // 12h
const ALG = 'HS256';

function secretKey(): Uint8Array {
	const s = env.SESSION_SECRET;
	if (!s || s.length < 16) {
		throw new Error('SESSION_SECRET is missing or too short (need 16+ chars)');
	}
	return new TextEncoder().encode(s);
}

export interface AdminTokenPayload {
	sub: string; // admin id
	username: string;
	role: AdminRole;
	jti: string;
}

export async function signAdminToken(payload: Omit<AdminTokenPayload, 'jti'>): Promise<{
	token: string;
	jti: string;
	expiresAt: Date;
}> {
	const jti = crypto.randomUUID();
	const expiresAt = new Date(Date.now() + TOKEN_TTL_SECONDS * 1000);
	const token = await new SignJWT({ ...payload, jti })
		.setProtectedHeader({ alg: ALG })
		.setIssuedAt()
		.setExpirationTime(`${TOKEN_TTL_SECONDS}s`)
		.setSubject(payload.sub)
		.setJti(jti)
		.sign(secretKey());
	return { token, jti, expiresAt };
}

export async function verifyAdminToken(token: string): Promise<AdminTokenPayload | null> {
	try {
		const { payload } = await jwtVerify(token, secretKey(), { algorithms: [ALG] });
		if (!payload.sub || !payload.jti) return null;
		return {
			sub: payload.sub as string,
			username: payload.username as string,
			role: payload.role as AdminTokenPayload['role'],
			jti: payload.jti as string
		};
	} catch {
		return null;
	}
}

export const ADMIN_COOKIE = 'admin_token';
export const ADMIN_TOKEN_TTL_SECONDS = TOKEN_TTL_SECONDS;
