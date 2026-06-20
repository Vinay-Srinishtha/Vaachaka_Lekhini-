import { json, error, type RequestHandler } from '@sveltejs/kit';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { requireAccount } from '$lib/server/user-auth';
import { readJsonBody } from '$lib/server/json-input';

const bodySchema = z.object({
	// Member IDs may be UUIDs (client-created profiles) or cuids (server-created
	// primary members) — accept any non-empty id, matching the rest of the sync API.
	member_id: z.string().min(1),
	voice_training_complete: z.boolean().default(false),
	handwriting_training_complete: z.boolean().default(false)
});

/**
 * POST /api/v1/global-sadhanas/:id/enroll  (Bearer required)
 * Enroll a member into a global sadhana. Idempotent — re-posting updates
 * training flags (useful when training completes after initial enrollment).
 */
export const POST: RequestHandler = async (event) => {
	const account = await requireAccount(event);
	const { id } = event.params;
	const body = await readJsonBody(event, bodySchema);

	// Validate member belongs to this account.
	const member = await prisma.member.findFirst({
		where: { id: body.member_id, accountId: account.id },
		select: { id: true }
	});
	if (!member) throw error(403, 'Member not owned by this account');

	// Validate the sadhana exists and is joinable.
	const sadhana = await prisma.globalSadhana.findUnique({
		where: { id },
		select: { id: true, status: true, targetCount: true, currentCount: true }
	});
	if (!sadhana) throw error(404, 'Global Sadhana not found');
	if (!['published', 'active'].includes(sadhana.status)) {
		throw error(409, 'This Global Sadhana is not open for enrollment');
	}
	if (sadhana.currentCount >= sadhana.targetCount) {
		throw error(409, 'This Global Sadhana has already reached its target');
	}

	// Upsert enrollment — idempotent so the app can re-post after training.
	const enrollment = await prisma.globalSadhanaEnrollment.upsert({
		where: { globalSadhanaId_memberId: { globalSadhanaId: id, memberId: body.member_id } },
		create: {
			globalSadhanaId: id,
			memberId: body.member_id,
			voiceTrainingComplete: body.voice_training_complete,
			handwritingTrainingComplete: body.handwriting_training_complete
		},
		update: {
			voiceTrainingComplete: body.voice_training_complete,
			handwritingTrainingComplete: body.handwriting_training_complete
		}
	});

	return json({
		enrollment: {
			global_sadhana_id: enrollment.globalSadhanaId,
			member_id: enrollment.memberId,
			enrolled_at: enrollment.enrolledAt.toISOString(),
			voice_training_complete: enrollment.voiceTrainingComplete,
			handwriting_training_complete: enrollment.handwritingTrainingComplete
		}
	});
};
