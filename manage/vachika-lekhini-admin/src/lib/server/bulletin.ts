import { prisma } from './prisma';

/**
 * Builds the auto "stats" bulletin string shown in the app's scrolling banner.
 * Aggregates app-wide totals + per-mantra global chant counts. Only ACTIVE
 * mantras are included; inactive mantras are never displayed.
 */
export async function computeBulletinText(): Promise<string> {
	const [chantAgg, writeAgg, programs, redeemed, users, perMantra] = await Promise.all([
		prisma.session.aggregate({
			where: { modality: { in: ['voice', 'manual'] } },
			_sum: { countAdded: true }
		}),
		prisma.session.aggregate({
			where: { modality: 'handwriting' },
			_sum: { countAdded: true }
		}),
		prisma.program.count(),
		prisma.rewardEvent.aggregate({ where: { kind: 'spend' }, _sum: { amount: true } }),
		prisma.account.count(),
		prisma.$queryRaw<{ name: string; count: number }[]>`
			SELECT m."nameRoman" AS name, COALESCE(SUM(s."countAdded"), 0)::int AS count
			FROM "Mantra" m
			JOIN "Program" p ON p."mantraId" = m.id
			JOIN "Session" s ON s."programId" = p.id
			WHERE m."isActive" = true
			GROUP BY m.id, m."nameRoman"
			ORDER BY count DESC
		`
	]);

	const nf = new Intl.NumberFormat('en-IN');
	const chants = chantAgg._sum.countAdded ?? 0;
	const writings = writeAgg._sum.countAdded ?? 0;
	const redeem = redeemed._sum.amount ?? 0;

	const parts: string[] = [
		`🙏 ${nf.format(chants)} chants`,
		`📿 ${nf.format(programs)} programs`,
		`✍️ ${nf.format(writings)} writings`,
		`🎁 ${nf.format(redeem)} rewards redeemed`,
		`👥 ${nf.format(users)} devotees`
	];
	for (const m of perMantra) {
		if (m.count > 0) parts.push(`🕉 ${m.name}: ${nf.format(m.count)} global chants`);
	}
	return parts.join('   •   ');
}
