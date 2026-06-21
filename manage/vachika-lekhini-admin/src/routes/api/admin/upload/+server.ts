import { json, error, type RequestHandler } from '@sveltejs/kit';
import { createAdminMediaUpload, deleteAdminMediaObject, isUploadCategory } from '$lib/server/s3';

export const POST: RequestHandler = async ({ locals, request }) => {
	try {
		if (!locals.admin) throw error(401, 'Admin login required.');

		const data = await request.json().catch(() => null);
		if (!data || typeof data !== 'object') throw error(400, 'Invalid upload request.');

		const category = String((data as any).category ?? '');
		const slug = String((data as any).slug ?? '').trim();
		const fileName = String((data as any).fileName ?? '');
		const contentType = String((data as any).contentType ?? '');
		const size = Number((data as any).size ?? 0);
		if (!isUploadCategory(category)) throw error(400, 'Invalid upload category.');

		const uploaded = await createAdminMediaUpload({ category, slug, fileName, contentType, size });
		return json(uploaded);
	} catch (e) {
		return uploadErrorResponse(e);
	}
};

/** Surface the real cause (missing S3 env, unsupported format, size, etc.)
 *  instead of a generic 500 — both for the UI and the server log. */
function uploadErrorResponse(e: unknown) {
	console.error('[admin/upload]', e);
	// SvelteKit error() throws an HttpError with { status, body: { message } }.
	if (e && typeof e === 'object' && 'status' in e && 'body' in e) {
		const he = e as { status: number; body?: { message?: string } };
		return json({ error: he.body?.message ?? 'Upload failed' }, { status: he.status });
	}
	const msg = e instanceof Error ? e.message : 'Upload failed';
	return json({ error: msg }, { status: 500 });
}

export const DELETE: RequestHandler = async ({ locals, request }) => {
	try {
		if (!locals.admin) throw error(401, 'Admin login required.');
		const data = await request.json().catch(() => null);
		const url = typeof data?.url === 'string' ? data.url.trim() : '';
		if (!url) throw error(400, 'Missing url.');
		await deleteAdminMediaObject(url);
		return json({ ok: true });
	} catch (e) {
		return uploadErrorResponse(e);
	}
};
