import { prisma } from './prisma';

const FLAG_KEY = 'chants_per_point';
const DEFAULT_RATE = 1; // 1 chant = 1 point

/// Read the current reward rate. Returns how many chants earn 1 point.
/// e.g. rate=1 → every chant earns 1 pt; rate=10 → 10 chants earn 1 pt.
export async function getRewardRate(): Promise<number> {
	const flag = await prisma.featureFlag.findUnique({ where: { key: FLAG_KEY } });
	if (!flag) return DEFAULT_RATE;
	const v = flag.value as number;
	return typeof v === 'number' && v > 0 ? Math.round(v) : DEFAULT_RATE;
}

/// Upsert the reward rate flag.
export async function setRewardRate(chantsPerPoint: number): Promise<void> {
	const rate = Math.max(1, Math.round(chantsPerPoint));
	await prisma.featureFlag.upsert({
		where: { key: FLAG_KEY },
		create: {
			key: FLAG_KEY,
			valueType: 'int',
			value: rate,
			description: 'How many chants equal 1 reward point. Min 1.'
		},
		update: { value: rate }
	});
}
