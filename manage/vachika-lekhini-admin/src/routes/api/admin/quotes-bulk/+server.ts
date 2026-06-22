import { json, error, type RequestHandler } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import { uploadBufferToS3 } from '$lib/server/s3';
import * as XLSX from 'xlsx';
import AdmZip from 'adm-zip';

const MAX_ROWS = 500;
const IMAGE_EXTENSIONS = new Set(['jpg', 'jpeg', 'png', 'webp', 'gif', 'avif']);
const IMAGE_MIME: Record<string, string> = {
	jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png',
	webp: 'image/webp', gif: 'image/gif', avif: 'image/avif'
};

interface QuoteRow {
	image?: string;
	slug?: string;
	text_roman?: string;
	source_roman?: string;
	text_telugu?: string;
	source_telugu?: string;
	text_devanagari?: string;
	source_devanagari?: string;
	text_kannada?: string;
	source_kannada?: string;
	text?: string;
	source?: string;
	mantra_slug?: string;
	image_url?: string;
}

function normalizeRow(raw: Record<string, unknown>): QuoteRow {
	const out: Record<string, string> = {};
	for (const [k, v] of Object.entries(raw)) {
		const key = k.trim().toLowerCase().replace(/[\s\-]+/g, '_').replace(/[^a-z0-9_]/g, '');
		out[key] = String(v ?? '').trim();
	}
	return out as QuoteRow;
}

function mimeForFile(name: string): string {
	const ext = name.split('.').pop()?.toLowerCase() ?? '';
	return IMAGE_MIME[ext] ?? 'image/jpeg';
}

function isImageFile(name: string): boolean {
	const ext = name.split('.').pop()?.toLowerCase() ?? '';
	return IMAGE_EXTENSIONS.has(ext);
}

export const POST: RequestHandler = async ({ locals, request }) => {
	if (!locals.admin) throw error(401, 'Admin login required.');

	const contentType = request.headers.get('content-type') ?? '';
	if (!contentType.includes('multipart/form-data')) throw error(400, 'Expected multipart/form-data.');

	const form = await request.formData();
	const file = form.get('file');
	if (!file || typeof file === 'string') throw error(400, 'Missing file.');

	const arrayBuffer = await file.arrayBuffer();
	const buffer = Buffer.from(arrayBuffer);
	const fileName = (file as File).name ?? 'upload';
	const isZip = fileName.endsWith('.zip') || (file as File).type === 'application/zip';

	// Images extracted from ZIP: filename → Buffer
	const imageBuffers = new Map<string, Buffer>();
	let csvBuffer: Buffer | null = null;

	if (isZip) {
		try {
			const zip = new AdmZip(buffer);
			for (const entry of zip.getEntries()) {
				if (entry.isDirectory) continue;
				const name = entry.name;
				if (name.endsWith('.csv') || name.endsWith('.xlsx')) {
					csvBuffer = entry.getData();
				} else if (isImageFile(name)) {
					imageBuffers.set(name, entry.getData());
					const base = name.split('/').pop()!;
					if (base !== name) imageBuffers.set(base, entry.getData());
				}
			}
		} catch {
			throw error(400, 'Could not read ZIP file.');
		}
		if (!csvBuffer) throw error(400, 'ZIP must contain a .csv or .xlsx file.');
	} else {
		csvBuffer = buffer;
	}

	let rows: QuoteRow[];
	try {
		const workbook = XLSX.read(csvBuffer, { type: 'buffer', raw: false });
		const sheet = workbook.Sheets[workbook.SheetNames[0]];
		const raw = XLSX.utils.sheet_to_json<Record<string, unknown>>(sheet, { defval: '', raw: false });
		rows = raw
			.filter((r) => !String(Object.values(r)[0] ?? '').trim().startsWith('#'))
			.map(normalizeRow)
			.filter((r) => Object.values(r).some((v) => v && String(v).trim()))
			.slice(0, MAX_ROWS);
	} catch {
		throw error(400, 'Could not parse file — upload a .xlsx, .csv, or .zip containing one of those.');
	}

	if (rows.length === 0) throw error(400, 'File contains no data rows.');

	const mantras = await prisma.mantra.findMany({ select: { id: true, slug: true } });
	const slugToId = new Map(mantras.map((m) => [m.slug, m.id]));

	let created = 0;
	let skipped = 0;
	const errors: string[] = [];

	for (let i = 0; i < rows.length; i++) {
		const row = rows[i];
		const rowLabel = `Row ${i + 2}`;

		const textRoman = row.text_roman?.trim() || null;
		const textTelugu = row.text_telugu?.trim() || null;
		const textDevanagari = row.text_devanagari?.trim() || null;
		const textKannada = row.text_kannada?.trim() || null;
		const legacyText = row.text?.trim() || null;
		const primaryText = textRoman ?? textTelugu ?? textDevanagari ?? textKannada ?? legacyText;

		if (!primaryText) {
			errors.push(`${rowLabel}: no text in any language — skipped`);
			skipped++;
			continue;
		}

		const slug = row.slug?.trim() || null;

		let mantraId: string | null = null;
		const mantraSlug = row.mantra_slug?.trim() ?? '';
		if (mantraSlug) {
			const id = slugToId.get(mantraSlug);
			if (!id) {
				errors.push(`${rowLabel}: unknown mantra_slug "${mantraSlug}" — created without mantra link`);
			} else {
				mantraId = id;
			}
		}

		// Only accept image_url values that are already on our S3 bucket under
		// the correct quotations/ prefix. Anything else (wrong bucket, old path,
		// external CDN) is discarded so the admin can re-upload via the UI.
		const rawImageUrl = row.image_url?.trim() || null;
		let imageUrl: string | null =
			rawImageUrl && /\/quotations\//.test(rawImageUrl) ? rawImageUrl : null;
		const imageRef = row.image?.trim();
		if (imageRef && !imageUrl) {
			const imgBuf = imageBuffers.get(imageRef) ?? imageBuffers.get(imageRef.split('/').pop()!);
			if (imgBuf) {
				try {
					imageUrl = await uploadBufferToS3({
						category: 'quote-image',
						slug: slug ?? `quote-${i + 1}`,
						fileName: imageRef,
						contentType: mimeForFile(imageRef),
						buffer: imgBuf
					});
				} catch (e) {
					errors.push(`${rowLabel}: image upload failed — ${e instanceof Error ? e.message : 'unknown'}`);
				}
			} else {
				errors.push(`${rowLabel}: image "${imageRef}" not found in ZIP — created without image`);
			}
		}

		try {
			await prisma.quote.create({
				data: {
					slug,
					text: primaryText,
					source: row.source_roman?.trim() || row.source?.trim() || null,
					textRoman,
					sourceRoman: row.source_roman?.trim() || null,
					textTelugu,
					sourceTelugu: row.source_telugu?.trim() || null,
					textDevanagari,
					sourceDevanagari: row.source_devanagari?.trim() || null,
					textKannada,
					sourceKannada: row.source_kannada?.trim() || null,
					imageUrl,
					mantraId,
					isActive: true
				}
			});
			created++;
		} catch (e) {
			errors.push(`${rowLabel}: DB error — ${e instanceof Error ? e.message : 'unknown'}`);
			skipped++;
		}
	}

	return json({ created, skipped, errors: errors.slice(0, 30) });
};
