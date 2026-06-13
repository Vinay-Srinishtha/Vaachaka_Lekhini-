import type { InputJsonValue } from '../../generated/prisma/internal/prismaNamespace.js';
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

export interface RewardEarnConfig {
	dailyTarget: number;
	milestoneCross: number;
	friendReferral: number;
	charityDonation: number;
	milestoneThresholds: number[];
}

/// Read all earn rates and milestone thresholds from FeatureFlag.
/// Used by sync.ts when creating earn/milestone reward events server-side.
export async function getRewardEarnConfig(): Promise<RewardEarnConfig> {
	const keys = [
		'reward_daily_points',
		'reward_milestone_points',
		'reward_friend_referral',
		'reward_charity_donation',
		'reward_milestone_thresholds'
	];
	const flags = await prisma.featureFlag.findMany({ where: { key: { in: keys } } });
	const map = new Map(flags.map((f) => [f.key, f.value]));

	const int = (key: string, fallback: number) => {
		const v = map.get(key);
		return typeof v === 'number' && v > 0 ? Math.round(v) : fallback;
	};

	const rawThresholds = map.get('reward_milestone_thresholds');
	const thresholds: number[] =
		Array.isArray(rawThresholds) && rawThresholds.length > 0
			? (rawThresholds as unknown[]).filter((n): n is number => typeof n === 'number')
			: [100000, 500000, 1000000, 2500000, 5000000, 10000000];

	return {
		dailyTarget: int('reward_daily_points', 50),
		milestoneCross: int('reward_milestone_points', 500),
		friendReferral: int('reward_friend_referral', 100),
		charityDonation: int('reward_charity_donation', 50),
		milestoneThresholds: thresholds
	};
}

/// Seed default reward and config flags. Safe to call multiple times — uses
/// upsert with update:{} so existing admin-set values are never overwritten.
export async function seedDefaultFlags(): Promise<void> {
	const entries: Array<{ key: string; valueType: 'int' | 'json' | 'string'; value: unknown; description: string }> = [
		{ key: 'reward_daily_points', valueType: 'int', value: 50, description: 'Points earned when daily target is hit.' },
		{ key: 'reward_milestone_points', valueType: 'int', value: 500, description: 'Points earned when a lifetime-count milestone is crossed.' },
		{ key: 'reward_friend_referral', valueType: 'int', value: 100, description: 'Points earned when a referred friend signs up.' },
		{ key: 'reward_charity_donation', valueType: 'int', value: 50, description: 'Points spent on a charity donation.' },
		{
			key: 'reward_milestone_thresholds',
			valueType: 'json',
			value: [100000, 500000, 1000000, 2500000, 5000000, 10000000],
			description: 'Lifetime chant counts that trigger milestone rewards (ascending).'
		},
		{
			key: 'program_day_presets',
			valueType: 'json',
			value: [
				{ days: 100, label: 'Fastest' },
				{ days: 180, label: 'Balanced' },
				{ days: 365, label: 'Gentle' },
				{ days: 500, label: 'Sustainable' }
			],
			description: 'Quick-pick duration chips shown when setting a program target.'
		}
	];

	await Promise.all(
		entries.map((e) =>
			prisma.featureFlag.upsert({
				where: { key: e.key },
				create: { key: e.key, valueType: e.valueType, value: e.value as InputJsonValue, description: e.description, updatedAt: new Date() },
				update: {}
			})
		)
	);
}
