import 'dotenv/config';
import bcrypt from 'bcryptjs';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { PrismaPg } from '@prisma/adapter-pg';

const prisma = new PrismaClient({
	adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL! })
});

// Mirror of lib/features/mantras/data/mantra_seed.dart — keep in sync until
// the Flutter app pulls catalog from /api/v1/mantras in Phase 9.
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
		tags: ['peace', 'righteousness', 'liberation'] as const
	},
	{
		slug: 'om_namah_shivaya',
		nameDevanagari: 'ॐ नमः शिवाय',
		nameRoman: 'Om Namah Shivaya',
		nameTelugu: 'ఓం నమః శివాయ',
		nameKannada: 'ಓಂ ನಮಃ ಶಿವಾಯ',
		description:
			'A popular five-syllable mantra dedicated to Lord Shiva. Chanting it is believed to cleanse the heart of impurities and bring inner stillness.',
		deity: 'Shiva',
		thumbPalette: 'shiva' as const,
		tags: ['peace', 'liberation', 'devotion'] as const
	},
	{
		slug: 'gayatri',
		nameDevanagari: 'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं',
		nameRoman: 'Gayatri Mantra',
		nameTelugu: 'గాయత్రీ మంత్రం',
		nameKannada: 'ಗಾಯತ್ರೀ ಮಂತ್ರ',
		description:
			'One of the most sacred mantras in the Vedas — a prayer for the awakening of intellect and wisdom through the radiance of the divine Savitr.',
		thumbPalette: 'gayatri' as const,
		tags: ['wisdom', 'enlightenment'] as const
	},
	{
		slug: 'maha_mrityunjaya',
		nameDevanagari: 'ॐ त्र्यम्बकं यजामहे',
		nameRoman: 'Maha Mrityunjaya',
		nameTelugu: 'మహా మృత్యుంజయ',
		nameKannada: 'ಮಹಾ ಮೃತ್ಯುಂಜಯ',
		description:
			'A powerful mantra of healing and protection, dedicated to Lord Shiva. Traditionally recited to overcome fear, illness, and adversity.',
		deity: 'Shiva',
		thumbPalette: 'maha' as const,
		tags: ['healing', 'protection', 'strength'] as const
	},
	{
		slug: 'hanuman_chalisa',
		nameDevanagari: 'हनुमान चालीसा',
		nameRoman: 'Hanuman Chalisa',
		nameTelugu: 'హనుమాన్ చాలీసా',
		nameKannada: 'ಹನುಮಾನ್ ಚಾಲೀಸಾ',
		description:
			'A devotional hymn of forty verses extolling Hanuman, invoked for strength, courage, and steadfast devotion.',
		deity: 'Hanuman',
		thumbPalette: 'hanuman' as const,
		tags: ['strength', 'courage', 'devotion', 'protection'] as const
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
		tags: ['peace', 'devotion'] as const
	},
	{
		slug: 'jai_sri_krishna',
		nameDevanagari: 'जय श्री कृष्ण',
		nameRoman: 'Jai Sri Krishna',
		nameTelugu: 'జై శ్రీ కృష్ణ',
		nameKannada: 'ಜೈ ಶ್ರೀ ಕೃಷ್ಣ',
		description: 'A joyful greeting to Lord Krishna — a mantra of devotion and deliverance.',
		deity: 'Krishna',
		thumbPalette: 'krishna' as const,
		tags: ['devotion', 'liberation'] as const
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
		tags: ['peace', 'devotion', 'protection'] as const
	},
	{
		slug: 'om_namo_bhagavate_vasudevaya',
		nameDevanagari: 'ॐ नमो भगवते वासुदेवाय',
		nameRoman: 'Om Namo Bhagavate Vasudevaya',
		nameTelugu: 'ఓం నమో భగవతే వాసుదేవాయ',
		nameKannada: 'ಓಂ ನಮೋ ಭಗವತೇ ವಾಸುದೇವಾಯ',
		description:
			'Chanting this mantra is believed to attract wealth, prosperity, and resolve financial difficulties by invoking the grace of Lord Vishnu.',
		deity: 'Vishnu',
		thumbPalette: 'vishnu' as const,
		tags: ['wealth', 'prosperity', 'devotion'] as const,
		recommendedCount: 108,
		recommendedDays: 40
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
	{ key: 'config.daily_quote_telugu', valueType: 'string' as const, value: 'ధర్మో రక్షతి రక్షితః', description: 'Quote shown on Home screen.' },
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
	const username = process.env.ADMIN_USERNAME ?? 'admin';
	const defaultPassword = process.env.ADMIN_BOOTSTRAP_PASSWORD ?? 'admin123';
	const passwordHash = await bcrypt.hash(defaultPassword, 10);
	await prisma.adminUser.upsert({
		where: { username },
		create: { username, passwordHash, role: 'super_admin' },
		update: {}
	});
	console.log(`  ✔ admin "${username}" ready (password: ${defaultPassword} — change immediately)`);

	// No demo accounts — real users register via the Flutter app.
}

main()
	.catch((e) => {
		console.error(e);
		process.exit(1);
	})
	.finally(() => prisma.$disconnect());
