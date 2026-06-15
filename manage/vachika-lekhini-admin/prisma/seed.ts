import 'dotenv/config';
import bcrypt from 'bcryptjs';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { PrismaPg } from '@prisma/adapter-pg';

const prisma = new PrismaClient({
	adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL! })
});

// Mirror of lib/features/mantras/data/mantra_seed.dart — keep in sync until
// the Flutter app pulls catalog from /api/v1/mantras in Phase 9.
// Canonical catalog — exactly these four mantras. Each carries all four
// language scripts (Roman/English, Devanagari/Hindi, Telugu, Kannada) plus
// the recommended count/days so programs can pre-fill targets.
const mantras = [
	{
		slug: 'sri_rama',
		nameDevanagari: 'श्री राम',
		nameRoman: 'Sri Rama',
		nameTelugu: 'శ్రీ రామ',
		nameKannada: 'ಶ್ರೀ ರಾಮ',
		description:
			'The Sri Rama mantra is a sacred chant that invokes the divine energy of Lord Rama, an incarnation of Vishnu. It is revered for its power to bestow peace, righteousness, and spiritual liberation. Chanting this mantra helps purify the mind, body, and soul, and is a cornerstone of the Vaachaka Lekhini practice, guiding devotees on their spiritual journey.',
		deity: 'Rama',
		thumbPalette: 'saffron' as const,
		tags: ['peace', 'righteousness', 'liberation'] as const,
		recommendedCount: 108,
		recommendedDays: 40,
		isActive: true
	},
	{
		slug: 'shankara',
		nameDevanagari: 'शंकर',
		nameRoman: 'Shankara',
		nameTelugu: 'శంకర',
		nameKannada: 'ಶಂಕರ',
		description: 'A simple invocation of Lord Shiva as Shankara — the auspicious one.',
		deity: 'Shiva',
		thumbPalette: 'shiva' as const,
		tags: ['peace', 'devotion'] as const,
		recommendedCount: 108,
		recommendedDays: 40,
		isActive: true
	},
	{
		slug: 'narayana',
		nameDevanagari: 'नारायण',
		nameRoman: 'Narayana',
		nameTelugu: 'నారాయణ',
		nameKannada: 'ನಾರಾಯಣ',
		description:
			'A short, single-word mantra honouring Lord Vishnu (Narayana), the sustainer.',
		deity: 'Vishnu',
		thumbPalette: 'vishnu' as const,
		tags: ['peace', 'devotion', 'protection'] as const,
		recommendedCount: 108,
		recommendedDays: 40,
		isActive: true
	},
	{
		slug: 'govinda',
		nameDevanagari: 'गोविन्द',
		nameRoman: 'Govinda',
		nameTelugu: 'గోవింద',
		nameKannada: 'ಗೋವಿಂದ',
		description:
			'A loving invocation of Lord Krishna as Govinda — protector of cows and the cosmos, who removes sorrow and bestows boundless joy.',
		deity: 'Krishna',
		thumbPalette: 'krishna' as const,
		tags: ['peace', 'devotion'] as const,
		recommendedCount: 108,
		recommendedDays: 40,
		isActive: true
	}
];

// Default reward-store items so the Store tab isn't empty on first run.
const storeItems = [
	{ slug: 'rudraksha_mala', name: 'Rudraksha Mala', description: '108-bead Rudraksha mala blessed at the temple.', pointsCost: 5000 },
	{ slug: 'puja_kit', name: 'Daily Puja Kit', description: 'Curated kit with incense, kumkum, and diya.', pointsCost: 3000 },
	{ slug: 'gita_book', name: 'Bhagavad Gita (Hardcover)', description: 'Sanskrit + English commentary.', pointsCost: 2500 },
	{ slug: 'temple_donation_101', name: '₹101 Temple Donation', description: 'Donate ₹101 to a partner temple in your name.', pointsCost: 1010 }
];

// Default feature flags. Flutter reads from /api/v1/config.
const flags = [
	{ key: 'feature.voice_counting', valueType: 'bool' as const, value: true, description: 'Enable Vosk voice ASR mode in counter.' },
	{ key: 'feature.handwriting_camera', valueType: 'bool' as const, value: true, description: 'Allow camera capture for handwriting enrolment.' },
	{ key: 'feature.handwriting_gallery', valueType: 'bool' as const, value: true, description: 'Allow gallery upload for handwriting enrolment.' },
	{ key: 'feature.community_tab', valueType: 'bool' as const, value: true, description: 'Show Community tab.' },
	{ key: 'feature.store_tab', valueType: 'bool' as const, value: true, description: 'Show Store tab.' },
	{ key: 'config.daily_quote_telugu', valueType: 'string' as const, value: '', description: 'Quote shown on Home screen (Telugu). Leave empty to hide the card.' },
	{ key: 'config.daily_quote_attribution', valueType: 'string' as const, value: '', description: 'Attribution line below the daily quote (e.g. "Ramayana"). Leave empty to hide.' },
	{ key: 'config.max_profiles_per_user', valueType: 'int' as const, value: 4, description: 'Maximum family profiles per registered mobile.' },
	{ key: 'config.min_app_version', valueType: 'string' as const, value: '1.0.0', description: 'Minimum supported Flutter app version — older clients are force-updated.' }
];

async function main() {
	console.log('▶ Seeding mantras…');
	for (let i = 0; i < mantras.length; i++) {
		const m = mantras[i];
		await prisma.mantra.upsert({
			where: { slug: m.slug },
			create: { ...m, tags: m.tags as unknown as any[], sortOrder: i },
			update: { ...m, tags: m.tags as unknown as any[], sortOrder: i }
		});
	}
	console.log(`  ✔ ${mantras.length} mantras seeded`);

	console.log('▶ Seeding store items…');
	for (let i = 0; i < storeItems.length; i++) {
		const s = storeItems[i];
		await prisma.storeItem.upsert({
			where: { slug: s.slug },
			create: { ...s, sortOrder: i },
			update: { ...s, sortOrder: i }
		});
	}
	console.log(`  ✔ ${storeItems.length} store items seeded`);

	console.log('▶ Seeding feature flags…');
	for (const f of flags) {
		await prisma.featureFlag.upsert({
			where: { key: f.key },
			create: { key: f.key, valueType: f.valueType, value: f.value as any, description: f.description },
			update: { valueType: f.valueType, value: f.value as any, description: f.description }
		});
	}
	console.log(`  ✔ ${flags.length} flags seeded`);

	console.log('▶ Seeding default admin user…');
	const username = process.env.ADMIN_USERNAME;
	const defaultPassword = process.env.ADMIN_BOOTSTRAP_PASSWORD;
	if (!username || !defaultPassword) {
		console.warn('  ⚠ ADMIN_USERNAME or ADMIN_BOOTSTRAP_PASSWORD not set — skipping admin seed.');
	} else {
		const passwordHash = await bcrypt.hash(defaultPassword, 10);
		await prisma.adminUser.upsert({
			where: { username },
			create: { username, passwordHash, role: 'super_admin' },
			update: {}
		});
		console.log(`  ✔ admin "${username}" created`);
	}

		// No demo accounts — real users register via the Flutter app.

	console.log('▶ Seeding FAQs…');
	const faqs = [
		{
			question: 'How do I start a new mantra program?',
			answer: 'Go to My Programs → tap "Add Program" → choose a mantra → set your daily target and number of days → tap Start. Your program begins immediately.',
			sortOrder: 1
		},
		{
			question: 'How does voice counting work?',
			answer: 'On the Practice screen, tap the microphone icon and chant aloud. The app listens and counts each chant automatically using voice recognition. Make sure to chant clearly and at a normal pace.',
			sortOrder: 2
		},
		{
			question: 'How does handwriting counting work?',
			answer: 'On the Practice screen, select Writing mode. Write the mantra in your own handwriting on paper, take a photo or upload from gallery. The app recognises your handwriting and counts the writings.',
			sortOrder: 3
		},
		{
			question: 'Can I add family members to my account?',
			answer: 'Yes. Go to Profile → Family Members → Add Member. Enter the name and relationship. Each member has their own separate practice counter, streaks, and reward points. Up to 4 family members can be added.',
			sortOrder: 4
		},
		{
			question: 'How do I switch between family members?',
			answer: 'Go to Profile → Switch User. The "Who is Practicing?" screen appears — tap any name to switch to that member\'s view. All data updates instantly for the selected person.',
			sortOrder: 5
		},
		{
			question: 'What are reward points and how do I earn them?',
			answer: 'Reward points are earned for every chant and writing you complete. Milestones (e.g. 1 000, 10 000 chants) give bonus points. Points can be redeemed in the Reward Store for spiritual items and donations.',
			sortOrder: 6
		},
		{
			question: 'How do I redeem points in the Reward Store?',
			answer: 'Go to Reward Store, browse items, and tap Redeem on anything you can afford. Once redeemed, the button changes to "Redeemed ✓" and the item is recorded under your account.',
			sortOrder: 7
		},
		{
			question: 'What is a streak and how is it calculated?',
			answer: 'A streak counts consecutive days you practised. Each calendar day you log at least one chant or writing keeps your streak alive. Missing a day resets the streak to zero. The Leaderboard ranks members by streak.',
			sortOrder: 8
		},
		{
			question: 'How do I retrain the app to recognise my handwriting or voice?',
			answer: 'Go to Profile → Retrain Voice or Retrain Writing Style. You must have at least one active program first. Select the mantra program you want to retrain, then follow the on-screen steps.',
			sortOrder: 9
		},
		{
			question: 'How do I report a problem or contact support?',
			answer: 'Go to Profile → Report Issue. Fill in the subject and describe what happened. Tap Send — our team reads every report and responds within 48 hours. You can also write to support@vaachikalekhini.com.',
			sortOrder: 10
		}
	];
	for (const faq of faqs) {
		const existing = await prisma.faq.findFirst({ where: { question: faq.question } });
		if (!existing) {
			await prisma.faq.create({ data: { ...faq, isActive: true } });
		}
	}
	console.log(`  ✔ ${faqs.length} FAQs seeded`);
}

main()
	.catch((e) => {
		console.error(e);
		process.exit(1);
	})
	.finally(() => prisma.$disconnect());
