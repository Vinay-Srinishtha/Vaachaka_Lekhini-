import { error } from '@sveltejs/kit';
import type { RequestEvent } from '@sveltejs/kit';
import type { ZodSchema } from 'zod';

/// Parse + validate a JSON body. Throws 400 with field-level errors on bad input.
/// Public API requests use snake_case keys so the schema should describe those.
export async function readJsonBody<T>(event: RequestEvent, schema: ZodSchema<T>): Promise<T> {
	const ct = event.request.headers.get('content-type') ?? '';
	if (!ct.toLowerCase().includes('application/json')) {
		throw error(415, 'Expected application/json');
	}
	let raw: unknown;
	try {
		raw = await event.request.json();
	} catch {
		throw error(400, 'Malformed JSON');
	}
	const parsed = schema.safeParse(raw);
	if (!parsed.success) {
		const issues = parsed.error.issues.map((i) => ({
			path: i.path.join('.'),
			message: i.message
		}));
		throw error(400, { message: 'Validation failed', issues } as any);
	}
	return parsed.data;
}
