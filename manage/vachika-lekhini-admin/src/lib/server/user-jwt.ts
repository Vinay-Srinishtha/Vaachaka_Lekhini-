import { SignJWT, jwtVerify } from 'jose';
import { env } from '$env/dynamic/private';

/// JWTs issued to the Flutter app.
/// Distinct from admin JWTs: different secret, different payload, longer
/// access TTL (mobile clients don't sit in front of a keyboard).
const ACCESS_TTL_SECONDS = 60 * 60 * 24; // 24h
const REFRESH_TTL_SECONDS = 60 * 60 * 24 * 30; // 30d
const ALG = 'HS256';

export interface UserAccessPayload {
	sub: string; // account id
	mobile: string;
	scope: 'access';
	jti: string;
}

export interface UserRefreshPayload {
	sub: string;
	scope: 'refresh';
	jti: string;
}

function secretKey(): Uint8Array {
	const s = env.USER_JWT_SECRET;
	if (!s || s.length < 16) {
		throw new Error('USER_JWT_SECRET is missing or too short (need 16+ chars)');
	}
	return new TextEncoder().encode(s);
}

export async function signUserAccessToken(payload: {
	sub: string;
	mobile: string;
}): Promise<{ token: string; jti: string; expiresAt: Date }> {
	const jti = crypto.randomUUID();
	const expiresAt = new Date(Date.now() + ACCESS_TTL_SECONDS * 1000);
	const token = await new SignJWT({ ...payload, scope: 'access', jti })
		.setProtectedHeader({ alg: ALG })
		.setIssuedAt()
		.setExpirationTime(`${ACCESS_TTL_SECONDS}s`)
		.setSubject(payload.sub)
		.setJti(jti)
		.sign(secretKey());
	return { token, jti, expiresAt };
}

export async function signUserRefreshToken(payload: { sub: string }): Promise<{
	token: string;
	jti: string;
	expiresAt: Date;
}> {
	const jti = crypto.randomUUID();
	const expiresAt = new Date(Date.now() + REFRESH_TTL_SECONDS * 1000);
	const token = await new SignJWT({ sub: payload.sub, scope: 'refresh', jti })
		.setProtectedHeader({ alg: ALG })
		.setIssuedAt()
		.setExpirationTime(`${REFRESH_TTL_SECONDS}s`)
		.setSubject(payload.sub)
		.setJti(jti)
		.sign(secretKey());
	return { token, jti, expiresAt };
}

export async function verifyUserToken(
	token: string,
	expectedScope: 'access' | 'refresh'
): Promise<UserAccessPayload | UserRefreshPayload | null> {
	try {
		const { payload } = await jwtVerify(token, secretKey(), { algorithms: [ALG] });
		if (payload.scope !== expectedScope) return null;
		if (!payload.sub || !payload.jti) return null;
		return payload as unknown as UserAccessPayload | UserRefreshPayload;
	} catch {
		return null;
	}
}

export { ACCESS_TTL_SECONDS, REFRESH_TTL_SECONDS };
