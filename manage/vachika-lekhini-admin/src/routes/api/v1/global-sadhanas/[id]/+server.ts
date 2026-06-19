import { json, error, type RequestHandler } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { requireAccount } from '$lib/server/user-auth';

/**
 * GET /api/v1/global-sadhanas/:id
 * Returns full detail of one sadhana, including enrollment status and
 * personal contribution count if the caller is authenticated.
 */
export const GET: RequestHandler = async (event) => {
	const { id } = event.params;

	// Auth is optional — unauthenticated callers get public fields only.
	let memberId: string | null = null;
	try {
		const account = await requireAccount(event);
		// Use the first member for now; the Flutter app passes member_id via query.
		memberId = event.url.searchParams.get('member_id') ?? null;
		// Validate member belongs to this account.
		if (memberId) {
			const member = await prisma.member.findFirst({
				where: { id: memberId, accountId: account.id },
				select: { id: true }
			});
			if (!member) memberId = null;
		}
	} catch {
		// Unauthenticated — continue with public data.
	}

	const sadhana = await prisma.globalSadhana.findUnique({
		where: { id },
		select: {
			id: true,
			title: true,
			description: true,
			mantraId: true,
			mantraText: true,
			mantraLanguage: true,
			imageUrl: true,
			targetCount: true,
			currentCount: true,
			startAt: true,
			endAt: true,
			status: true,
			participationMode: true,
			instructions: true,
			isSponsored: true,
			completedAt: true,
			_count: { select: { enrollments: true } }
		}
	});

	if (!sadhana) throw error(404, 'Global Sadhana not found');

	// Optional: enrollment + personal contribution for authenticated member.
	let enrollment = null;
	let myContribution = 0;
	if (memberId) {
		const [enr, contrib] = await Promise.all([
			prisma.globalSadhanaEnrollment.findUnique({
				where: { globalSadhanaId_memberId: { globalSadhanaId: id, memberId } }
			}),
			prisma.globalSadhanaContribution.aggregate({
				where: { globalSadhanaId: id, memberId },
				_sum: { countAdded: true }
			})
		]);
		enrollment = enr;
		myContribution = contrib._sum.countAdded ?? 0;
	}

	return json({
		sadhana: {
			id: sadhana.id,
			title: sadhana.title,
			description: sadhana.description,
			mantra_id: sadhana.mantraId,
			mantra_text: sadhana.mantraText ?? null,
			mantra_language: sadhana.mantraLanguage,
			image_url: sadhana.imageUrl ?? null,
			target_count: sadhana.targetCount,
			current_count: sadhana.currentCount,
			start_at: sadhana.startAt.toISOString(),
			end_at: sadhana.endAt?.toISOString() ?? null,
			status: sadhana.status,
			participation_mode: sadhana.participationMode,
			instructions: sadhana.instructions ?? null,
			is_sponsored: sadhana.isSponsored,
			completed_at: sadhana.completedAt?.toISOString() ?? null,
			participant_count: sadhana._count.enrollments,
			enrollment: enrollment
				? {
						global_sadhana_id: enrollment.globalSadhanaId,
						member_id: enrollment.memberId,
						enrolled_at: enrollment.enrolledAt.toISOString(),
						voice_training_complete: enrollment.voiceTrainingComplete,
						handwriting_training_complete: enrollment.handwritingTrainingComplete,
						my_contribution: myContribution
					}
				: null
		}
	});
};
