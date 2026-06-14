import bcrypt from 'bcryptjs';
import { env } from '$env/dynamic/private';
import { prisma } from './prisma';

/// One-time-password service. Pluggable by `OTP_PROVIDER` env var.
///   - "dev"   : prints the code to the server log; any 6-digit OTP is
///               consumed via verify() because we hash + check the real one.
///   - "msg91" / "twilio" / etc. : implement when ready.
///
/// The raw code is NEVER persisted. Only a bcrypt hash lands in the DB.
export interface OtpService {
	/// Sends an OTP to [mobile] and persists a hashed challenge.
	/// Returns the challenge id so the client can echo it back on verify
	/// (also enforces 1-minute rate limit per mobile).
	start(mobile: string): Promise<{ challengeId: string }>;

	/// Validates the OTP. Returns null on success; an error string on failure.
	/// On success the matching OtpChallenge is marked consumed.
	verify(mobile: string, code: string): Promise<{ ok: true } | { ok: false; error: string }>;
}

const OTP_TTL_SECONDS = 5 * 60; // 5 min
const MAX_ATTEMPTS = 5;
const RESEND_COOLDOWN_SECONDS = 30;

class DevOtpService implements OtpService {
	async start(mobile: string): Promise<{ challengeId: string }> {
		// Throttle: refuse if any unconsumed challenge < 30s old exists.
		const recent = await prisma.otpChallenge.findFirst({
			where: {
				mobile,
				consumedAt: null,
				createdAt: { gt: new Date(Date.now() - RESEND_COOLDOWN_SECONDS * 1000) }
			}
		});
		if (recent) {
			return { challengeId: recent.id };
		}

		const code = String(Math.floor(100000 + Math.random() * 900000));
		const codeHash = await bcrypt.hash(code, 10);
		const challenge = await prisma.otpChallenge.create({
			data: {
				mobile,
				codeHash,
				expiresAt: new Date(Date.now() + OTP_TTL_SECONDS * 1000)
			}
		});
		// Log OTP to server console (dev only — OTP_PROVIDER=dev means no SMS is sent).
		process.stdout.write(`[otp:dev] OTP for ${mobile} → ${code}\n`);
		return { challengeId: challenge.id };
	}

	async verify(
		mobile: string,
		code: string
	): Promise<{ ok: true } | { ok: false; error: string }> {
		const candidates = await prisma.otpChallenge.findMany({
			where: {
				mobile,
				consumedAt: null,
				expiresAt: { gt: new Date() }
			},
			orderBy: { createdAt: 'desc' },
			take: 3
		});
		if (candidates.length === 0) {
			return { ok: false, error: 'No active OTP. Request a new one.' };
		}

		for (const c of candidates) {
			if (c.attempts >= MAX_ATTEMPTS) continue;
			const match = await bcrypt.compare(code, c.codeHash);
			if (match) {
				await prisma.otpChallenge.update({
					where: { id: c.id },
					data: { consumedAt: new Date() }
				});
				return { ok: true };
			}
			await prisma.otpChallenge.update({
				where: { id: c.id },
				data: { attempts: { increment: 1 } }
			});
		}
		return { ok: false, error: 'Incorrect OTP.' };
	}
}

class TwoFactorOtpService implements OtpService {
	constructor(private apiKey: string, private templateName?: string) {}

	async start(mobile: string): Promise<{ challengeId: string }> {
		const digits = mobile.replace(/^\+91/, '').replace(/\D/g, '');

		const recent = await prisma.otpChallenge.findFirst({
			where: {
				mobile,
				consumedAt: null,
				createdAt: { gt: new Date(Date.now() - RESEND_COOLDOWN_SECONDS * 1000) }
			}
		});
		if (recent) {
			return { challengeId: recent.id };
		}

		// Append template name if set — forces SMS delivery.
		// Use TWO_FACTOR_TEMPLATE=OTPONLY for the 2factor built-in SMS-only template.
		const template = this.templateName ? `/${this.templateName}` : '';
		const res = await fetch(
			`https://2factor.in/API/V1/${this.apiKey}/SMS/${digits}/AUTOGEN${template}`
		);
		const data = await res.json();
		if (data.Status !== 'Success') {
			throw new Error(`2factor.in error: ${data.Details}`);
		}

		// Store 2factor session_id in codeHash (repurposed — no bcrypt here)
		const challenge = await prisma.otpChallenge.create({
			data: {
				mobile,
				codeHash: data.Details,
				expiresAt: new Date(Date.now() + OTP_TTL_SECONDS * 1000)
			}
		});
		return { challengeId: challenge.id };
	}

	async verify(
		mobile: string,
		code: string
	): Promise<{ ok: true } | { ok: false; error: string }> {
		const candidates = await prisma.otpChallenge.findMany({
			where: { mobile, consumedAt: null, expiresAt: { gt: new Date() } },
			orderBy: { createdAt: 'desc' },
			take: 3
		});
		if (candidates.length === 0) {
			return { ok: false, error: 'No active OTP. Request a new one.' };
		}

		const c = candidates[0];
		if (c.attempts >= MAX_ATTEMPTS) {
			return { ok: false, error: 'Too many attempts. Request a new OTP.' };
		}

		const res = await fetch(
			`https://2factor.in/API/V1/${this.apiKey}/SMS/VERIFY/${c.codeHash}/${code}`
		);
		const data = await res.json();

		if (data.Status === 'Success') {
			await prisma.otpChallenge.update({
				where: { id: c.id },
				data: { consumedAt: new Date() }
			});
			return { ok: true };
		}

		await prisma.otpChallenge.update({
			where: { id: c.id },
			data: { attempts: { increment: 1 } }
		});
		return { ok: false, error: 'Incorrect OTP.' };
	}
}

let _instance: OtpService | null = null;

export function otpService(): OtpService {
	if (_instance) return _instance;
	const provider = env.OTP_PROVIDER ?? 'dev';
	switch (provider) {
		case 'dev':
			_instance = new DevOtpService();
			break;
		case '2factor':
			if (!env.TWO_FACTOR_API_KEY) throw new Error('TWO_FACTOR_API_KEY is not set in .env');
			_instance = new TwoFactorOtpService(env.TWO_FACTOR_API_KEY, env.TWO_FACTOR_TEMPLATE);
			break;
		default:
			throw new Error(`Unknown OTP_PROVIDER: ${provider}`);
	}
	return _instance;
}
