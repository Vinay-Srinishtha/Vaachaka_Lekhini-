import { json, error, type RequestHandler } from '@sveltejs/kit';
import { createAdminMediaUpload, deleteAdminMediaObject, isUploadCategory } from '$lib/server/s3';

export const POST: RequestHandler = async ({ locals, request }) => {
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
};

export const DELETE: RequestHandler = async ({ locals, request }) => {
	if (!locals.admin) throw error(401, 'Admin login required.');
	const data = await request.json().catch(() => null);
	const url = typeof data?.url === 'string' ? data.url.trim() : '';
	if (!url) throw error(400, 'Missing url.');
	await deleteAdminMediaObject(url);
	return json({ ok: true });
};
