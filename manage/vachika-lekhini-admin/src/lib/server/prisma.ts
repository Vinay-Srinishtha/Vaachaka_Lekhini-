import { PrismaClient } from '../../generated/prisma/client.js';
import { PrismaPg } from '@prisma/adapter-pg';
import { env } from '$env/dynamic/private';

// One PrismaClient per process, reused across requests.
// Vite HMR will re-evaluate modules → guard with globalThis to avoid
// exhausting connections in dev.

const globalForPrisma = globalThis as unknown as { __prisma?: PrismaClient };

function createPrisma() {
	const connectionString = env.DATABASE_URL;
	if (!connectionString) {
		throw new Error('DATABASE_URL is not set');
	}
	const adapter = new PrismaPg({ connectionString });
	return new PrismaClient({ adapter });
}

export const prisma: PrismaClient = globalForPrisma.__prisma ?? createPrisma();

if (env.NODE_ENV !== 'production') {
	globalForPrisma.__prisma = prisma;
}
