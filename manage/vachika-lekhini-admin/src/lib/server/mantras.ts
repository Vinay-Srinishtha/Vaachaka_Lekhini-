import { z } from 'zod';
import { error } from '@sveltejs/kit';
import { prisma } from './prisma';
import { MANTRA_TAGS, THUMB_PALETTES } from '$lib/constants';

const slugRegex = /^[a-z][a-z0-9_]{1,40}$/;

export const mantraFormSchema = z.object({
	slug: z.string().regex(slugRegex, 'Slug: lowercase letters, digits, underscores; 2–41 chars.'),
	nameDevanagari: z.string().min(1).max(200),
	nameRoman: z.string().min(1).max(120),
	nameTelugu: z.string().max(200).nullable().optional(),
	nameKannada: z.string().max(200).nullable().optional(),
	description: z.string().min(1).max(2000),
	deity: z.string().max(60).nullable().optional(),
	thumbPalette: z.enum(THUMB_PALETTES),
	tags: z.array(z.enum(MANTRA_TAGS)).default([]),
	recommendedCount: z.coerce.number().int().positive().nullable().optional(),
	recommendedDays: z.coerce.number().int().positive().nullable().optional(),
	pronunciationUrl: z.string().url().max(500).nullable().optional(),
	isActive: z.coerce.boolean().default(true),
	sortOrder: z.coerce.number().int().default(0)
});

export type MantraFormInput = z.infer<typeof mantraFormSchema>;

/// Parse a FormData payload from a mantra form (create or edit).
/// Throws a 400 with a flat field-error map on validation failure.
export function parseMantraForm(data: FormData): MantraFormInput {
	const raw = {
		slug: String(data.get('slug') ?? '').trim(),
		nameDevanagari: String(data.get('nameDevanagari') ?? '').trim(),
		nameRoman: String(data.get('nameRoman') ?? '').trim(),
		nameTelugu: emptyToNull(data.get('nameTelugu')),
		nameKannada: emptyToNull(data.get('nameKannada')),
		description: String(data.get('description') ?? '').trim(),
		deity: emptyToNull(data.get('deity')),
		thumbPalette: String(data.get('thumbPalette') ?? 'saffron'),
		tags: data.getAll('tags').map((v) => String(v)),
		recommendedCount: emptyToNull(data.get('recommendedCount')),
		recommendedDays: emptyToNull(data.get('recommendedDays')),
		pronunciationUrl: emptyToNull(data.get('pronunciationUrl')),
		isActive: data.get('isActive') === 'on' || data.get('isActive') === 'true',
		sortOrder: Number(data.get('sortOrder') ?? 0)
	};
	const parsed = mantraFormSchema.safeParse(raw);
	if (!parsed.success) {
		const fieldErrors: Record<string, string> = {};
		for (const issue of parsed.error.issues) {
			const k = issue.path.join('.') || '_';
			if (!fieldErrors[k]) fieldErrors[k] = issue.message;
		}
		throw error(400, { message: 'Validation failed', fieldErrors } as any);
	}
	return parsed.data;
}

function emptyToNull(v: FormDataEntryValue | null): string | null {
	if (v === null) return null;
	const s = String(v).trim();
	return s === '' ? null : s;
}

export const mantraSummarySelect = {
	id: true,
	slug: true,
	nameDevanagari: true,
	nameRoman: true,
	deity: true,
	thumbPalette: true,
	isActive: true,
	sortOrder: true,
	updatedAt: true
} as const;

export const MANTRA_SORT_COLS = ['nameRoman', 'sortOrder', 'isActive', 'updatedAt', 'deity'] as const;

export interface ListMantrasArgs {
	q: string;
	skip: number;
	take: number;
	sort: { col: string; dir: 'asc' | 'desc' };
}

/// List + total in one round trip. `q` matches roman name, devanagari, slug,
/// or deity (case-insensitive). Optimised: selects only summary columns.
export async function listMantras(args: ListMantrasArgs) {
	const where = args.q
		? {
				OR: [
					{ nameRoman: { contains: args.q, mode: 'insensitive' as const } },
					{ nameDevanagari: { contains: args.q } },
					{ slug: { contains: args.q, mode: 'insensitive' as const } },
					{ deity: { contains: args.q, mode: 'insensitive' as const } }
				]
			}
		: {};

	const orderBy = { [args.sort.col]: args.sort.dir };

	const [rows, total] = await prisma.$transaction([
		prisma.mantra.findMany({
			where,
			select: mantraSummarySelect,
			orderBy,
			skip: args.skip,
			take: args.take
		}),
		prisma.mantra.count({ where })
	]);

	return { rows, total };
}
