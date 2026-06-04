import { z } from 'zod';
import { error } from '@sveltejs/kit';
import { prisma } from './prisma';

const slugRegex = /^[a-z][a-z0-9_]{1,40}$/;

export const storeItemFormSchema = z.object({
	slug: z.string().regex(slugRegex, 'Slug: lowercase letters, digits, underscores; 2–41 chars.'),
	name: z.string().min(1).max(120),
	description: z.string().min(1).max(2000),
	pointsCost: z.coerce.number().int().min(0).max(10_000_000),
	imageUrl: z.string().url().max(500).nullable().optional(),
	stock: z.coerce.number().int().min(0).nullable().optional(),
	isActive: z.coerce.boolean().default(true),
	sortOrder: z.coerce.number().int().default(0)
});
export type StoreItemFormInput = z.infer<typeof storeItemFormSchema>;

export function parseStoreItemForm(data: FormData): StoreItemFormInput {
	const raw = {
		slug: String(data.get('slug') ?? '').trim(),
		name: String(data.get('name') ?? '').trim(),
		description: String(data.get('description') ?? '').trim(),
		pointsCost: Number(data.get('pointsCost') ?? 0),
		imageUrl: emptyToNull(data.get('imageUrl')),
		stock: emptyToNull(data.get('stock')),
		isActive: data.get('isActive') === 'on' || data.get('isActive') === 'true',
		sortOrder: Number(data.get('sortOrder') ?? 0)
	};
	const parsed = storeItemFormSchema.safeParse(raw);
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

export const STORE_SORT_COLS = ['name', 'pointsCost', 'sortOrder', 'isActive', 'updatedAt'] as const;

export const storeSummarySelect = {
	id: true,
	slug: true,
	name: true,
	pointsCost: true,
	stock: true,
	imageUrl: true,
	isActive: true,
	sortOrder: true,
	updatedAt: true
} as const;

export interface ListStoreArgs {
	q: string;
	skip: number;
	take: number;
	sort: { col: string; dir: 'asc' | 'desc' };
}

export async function listStoreItems(args: ListStoreArgs) {
	const where = args.q
		? {
				OR: [
					{ name: { contains: args.q, mode: 'insensitive' as const } },
					{ slug: { contains: args.q, mode: 'insensitive' as const } },
					{ description: { contains: args.q, mode: 'insensitive' as const } }
				]
			}
		: {};

	const orderBy = { [args.sort.col]: args.sort.dir };

	const [rows, total] = await prisma.$transaction([
		prisma.storeItem.findMany({
			where,
			select: storeSummarySelect,
			orderBy,
			skip: args.skip,
			take: args.take
		}),
		prisma.storeItem.count({ where })
	]);

	return { rows, total };
}
