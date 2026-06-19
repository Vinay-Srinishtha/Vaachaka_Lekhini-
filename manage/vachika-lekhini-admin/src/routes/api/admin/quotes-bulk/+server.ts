import { json, error, type RequestHandler } from '@sveltejs/kit';
import { prisma } from '$lib/server/prisma';
import * as XLSX from 'xlsx';

const MAX_ROWS = 500;
const REQUIRED_COLUMNS = ['text'];

interface QuoteRow {
	text?: string;
	source?: string;
	mantra_slug?: string;
	image_url?: string;
}

function normalizeRow(raw: Record<string, unknown>): QuoteRow {
	// Normalize keys: trim, lowercase, replace spaces/dashes with underscores
	const out: Record<string, string> = {};
	for (const [k, v] of Object.entries(raw)) {
		const key = k.trim().toLowerCase().replace(/[\s-]+/g, '_').replace(/^#+\s*/, '');
		out[key] = String(v ?? '').trim();
	}
	return out as QuoteRow;
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

	let rows: QuoteRow[];
	try {
		const workbook = XLSX.read(buffer, { type: 'buffer', raw: false });
		const sheetName = workbook.SheetNames[0];
		const sheet = workbook.Sheets[sheetName];
		const raw = XLSX.utils.sheet_to_json<Record<string, unknown>>(sheet, {
			defval: '',
			raw: false,
			// Skip rows that start with # (comment rows in our CSV template)
		});
		rows = raw
			.filter((r) => {
				// Skip comment rows (first cell starts with #)
				const firstVal = String(Object.values(r)[0] ?? '').trim();
				return !firstVal.startsWith('#');
			})
			.map(normalizeRow)
			.slice(0, MAX_ROWS);
	} catch {
		throw error(400, 'Could not parse file — upload a valid .xlsx or .csv file.');
	}

	if (rows.length === 0) throw error(400, 'File contains no data rows.');

	// Build mantra slug → id lookup
	const mantras = await prisma.mantra.findMany({ select: { id: true, slug: true } });
	const slugToId = new Map(mantras.map((m) => [m.slug, m.id]));

	let created = 0;
	let skipped = 0;
	const errors: string[] = [];

	for (let i = 0; i < rows.length; i++) {
		const row = rows[i];
		const rowLabel = `Row ${i + 2}`; // +2 because row 1 is headers

		const text = (row.text ?? '').trim();
		if (!text) {
			errors.push(`${rowLabel}: missing "text" — skipped`);
			skipped++;
			continue;
		}

		let mantraId: string | null = null;
		const slug = (row.mantra_slug ?? '').trim();
		if (slug) {
			const id = slugToId.get(slug);
			if (!id) {
				errors.push(`${rowLabel}: unknown mantra_slug "${slug}" — quote created without mantra link`);
			} else {
				mantraId = id;
			}
		}

		const imageUrl = (row.image_url ?? '').trim() || null;
		const source = (row.source ?? '').trim() || null;

		try {
			await prisma.quote.create({ data: { text, source, mantraId, imageUrl, isActive: true } });
			created++;
		} catch (e) {
			errors.push(`${rowLabel}: database error — ${e instanceof Error ? e.message : 'unknown'}`);
			skipped++;
		}
	}

	return json({ created, skipped, errors: errors.slice(0, 20) });
};
