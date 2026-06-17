import { DeleteObjectCommand, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { error } from '@sveltejs/kit';
import { env } from '$env/dynamic/private';

type UploadCategory = 'mantra-audio' | 'store-image' | 'mantra-image' | 'mantra-preview';

// All common image formats — browser File API always reports a valid image/* MIME type.
const IMAGE_PREFIX = 'image/';
const AUDIO_TYPES = new Set(['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/x-wav']);

const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
const MAX_AUDIO_BYTES = 20 * 1024 * 1024;

let client: S3Client | null = null;

function s3Client() {
	if (client) return client;
	const region = requiredEnv('AWS_REGION');
	client = new S3Client({
		region,
		credentials: {
			accessKeyId: requiredEnv('AWS_ACCESS_KEY_ID'),
			secretAccessKey: requiredEnv('AWS_SECRET_ACCESS_KEY')
		}
	});
	return client;
}

function requiredEnv(name: string) {
	const value = env[name];
	if (!value) throw error(500, `Missing ${name}`);
	return value;
}

/** S3_PUBLIC_BASE_URL is optional — falls back to the standard bucket URL. */
function publicBaseUrl() {
	if (env['S3_PUBLIC_BASE_URL']) return env['S3_PUBLIC_BASE_URL'].replace(/\/+$/, '');
	const bucket = requiredEnv('S3_BUCKET_NAME');
	const region = requiredEnv('AWS_REGION');
	return `https://${bucket}.s3.${region}.amazonaws.com`;
}

function cleanSegment(value: string, fallback: string) {
	const cleaned = value
		.trim()
		.toLowerCase()
		.replace(/[^a-z0-9_-]+/g, '-')
		.replace(/^-+|-+$/g, '')
		.slice(0, 80);
	return cleaned || fallback;
}

function extensionFor(fileName: string, contentType: string) {
	const fromName = fileName.split('.').pop()?.toLowerCase();
	if (fromName && /^[a-z0-9]{2,5}$/.test(fromName)) return fromName;
	if (contentType === 'image/jpeg') return 'jpg';
	if (contentType === 'image/png') return 'png';
	if (contentType === 'image/webp') return 'webp';
	if (contentType === 'audio/wav' || contentType === 'audio/x-wav') return 'wav';
	return 'mp3';
}

function validateMediaInput(args: {
	category: UploadCategory;
	fileName: string;
	contentType: string;
	size: number;
}) {
	const isImage = args.category === 'store-image' || args.category === 'mantra-image' || args.category === 'mantra-preview';
	const maxBytes = isImage ? MAX_IMAGE_BYTES : MAX_AUDIO_BYTES;

	const typeOk = isImage
		? args.contentType.startsWith(IMAGE_PREFIX)
		: AUDIO_TYPES.has(args.contentType);
	if (!typeOk) {
		throw error(400, isImage ? 'Upload any image file (JPG, PNG, WEBP, GIF, AVIF, etc.).' : 'Upload an MP3 or WAV audio file.');
	}
	if (!args.fileName.trim()) throw error(400, 'File name is required.');
	if (!Number.isFinite(args.size) || args.size <= 0) throw error(400, 'Upload file is empty.');
	if (args.size > maxBytes) {
		throw error(400, isImage ? 'Image must be 5 MB or smaller.' : 'Audio must be 20 MB or smaller.');
	}
}

function keyPrefix(category: UploadCategory, slug: string) {
	const safeSlug = cleanSegment(slug, 'item');
	if (category === 'mantra-audio') return `mantras/audio/${safeSlug}`;
	if (category === 'mantra-image') return `mantras/images/main/${safeSlug}`;
	if (category === 'mantra-preview') return `mantras/images/preview/${safeSlug}`;
	return `store/images/${safeSlug}`;
}

export async function createAdminMediaUpload(args: {
	category: UploadCategory;
	slug: string;
	fileName: string;
	contentType: string;
	size: number;
}) {
	validateMediaInput(args);

	const bucket = requiredEnv('S3_BUCKET_NAME');
	const baseUrl = env['S3_PUBLIC_BASE_URL']?.replace(/\/+$/, '')
		?? `https://${bucket}.s3.${requiredEnv('AWS_REGION')}.amazonaws.com`;
	const baseName = cleanSegment(args.fileName.replace(/\.[^.]+$/, ''), 'upload');
	const ext = extensionFor(args.fileName, args.contentType);
	const key = `${keyPrefix(args.category, args.slug)}/${Date.now()}-${baseName}.${ext}`;
	const cacheControl = 'public, max-age=31536000, immutable';
	const command = new PutObjectCommand({
		Bucket: bucket,
		Key: key,
		ContentType: args.contentType,
		CacheControl: cacheControl
	});

	return {
		key,
		url: `${baseUrl}/${key}`,
		uploadUrl: await getSignedUrl(s3Client(), command, { expiresIn: 300 }),
		headers: {
			'content-type': args.contentType,
			'cache-control': cacheControl
		},
		contentType: args.contentType,
		size: args.size
	};
}

export function isUploadCategory(value: string): value is UploadCategory {
	return value === 'mantra-audio' || value === 'store-image' || value === 'mantra-image' || value === 'mantra-preview';
}

export async function deleteAdminMediaObject(url: string) {
	// Extract key and bucket from the URL.
	// S3 URL format: https://{bucket}.s3.{region}.amazonaws.com/{key}
	// Falls back to parsing bucket from hostname when S3_BUCKET_NAME is not set.
	let key: string;
	let bucket: string;
	try {
		const parsed = new URL(url);
		key = parsed.pathname.replace(/^\/+/, '');
		if (!key) throw new Error('empty key');
		bucket = env['S3_BUCKET_NAME']?.trim() || parsed.hostname.split('.')[0];
		if (!bucket) throw new Error('no bucket');
	} catch {
		throw error(400, 'Invalid media URL.');
	}
	await s3Client().send(new DeleteObjectCommand({ Bucket: bucket, Key: key }));
}
