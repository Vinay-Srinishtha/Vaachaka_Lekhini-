import type { RequestHandler } from './$types';
import { z } from 'zod';
import { prisma } from '$lib/server/prisma';
import { snakeJson } from '$lib/server/snake-case';
import { readJsonBody } from '$lib/server/json-input';
import { requireAccount } from '$lib/server/user-auth';
import { assertOwnsMembers, assertOwnsPrograms, sessionCreateSchema } from '$lib/server/sync';

const bodySchema = z.object({
	sessions: z.array(sessionCreateSchema).min(1).max(100)
});

/// POST /api/v1/sessions  (Bearer) — batch create. Sessions are append-only;
/// re-posting the same id is a no-op (idempotent thanks to client-supplied UUID).
export const POST: RequestHandler = async (event) => {
	const account = await requireAccount(event);
	const body = await readJsonBody(event, bodySchema);

	await assertOwnsMembers(account.id, body.sessions.map((s) => s.member_id));
	await assertOwnsPrograms(account.id, body.sessions.map((s) => s.program_id));

	const inserted = await prisma.session.createMany({
		data: body.sessions.map((s) => ({
			id: s.id,
			memberId: s.member_id,
			programId: s.program_id,
			startedAt: new Date(s.started_at),
			endedAt: s.ended_at ? new Date(s.ended_at) : null,
			durationSec: s.duration_sec,
			countAdded: s.count_added,
			modality: s.modality,
			voiceMatchScore: s.voice_match_score ?? null
		})),
		skipDuplicates: true
	});

	return snakeJson({ created: inserted.count, requested: body.sessions.length });
};
