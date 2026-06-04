import { z } from 'zod';
import { error } from '@sveltejs/kit';
import { prisma } from './prisma';
import { FLAG_TYPES, type FlagType } from '$lib/constants';

const keyRegex = /^[a-z][a-z0-9_]*(?:\.[a-z0-9_]+)*$/;

/// Form input — the raw form will always submit `value` as a string;
/// we decode it according to `valueType`.
const flagBaseSchema = z.object({
	key: z.string().regex(keyRegex, 'Key: lowercase, digits, underscores, optional dot-separated namespaces.'),
	valueType: z.enum(FLAG_TYPES),
	rawValue: z.string(),
	description: z.string().max(1000).nullable().optional()
});
type FlagBaseInput = z.infer<typeof flagBaseSchema>;

export interface FlagFormResult {
	key: string;
	valueType: FlagType;
	value: unknown; // decoded
	description: string | null;
}

export function parseFlagForm(data: FormData): FlagFormResult {
	const raw = {
		key: String(data.get('key') ?? '').trim(),
		valueType: String(data.get('valueType') ?? 'bool'),
		rawValue: String(data.get('rawValue') ?? ''),
		description: emptyToNull(data.get('description'))
	};
	const parsed = flagBaseSchema.safeParse(raw);
	if (!parsed.success) {
		const fieldErrors: Record<string, string> = {};
		for (const issue of parsed.error.issues) {
			const k = issue.path.join('.') || '_';
			if (!fieldErrors[k]) fieldErrors[k] = issue.message;
		}
		throw error(400, { message: 'Validation failed', fieldErrors } as any);
	}

	const { valueType, rawValue } = parsed.data;
	let value: unknown;
	try {
		value = decodeFlagValue(valueType, rawValue);
	} catch (e: any) {
		throw error(400, {
			message: 'Invalid value',
			fieldErrors: { rawValue: e?.message ?? 'Invalid value for the chosen type.' }
		} as any);
	}

	return {
		key: parsed.data.key,
		valueType,
		value,
		description: parsed.data.description ?? null
	};
}

function decodeFlagValue(type: FlagType, raw: string): unknown {
	switch (type) {
		case 'bool': {
			const v = raw.toLowerCase().trim();
			if (v === 'true' || v === 'on' || v === '1') return true;
			if (v === 'false' || v === '' || v === '0') return false;
			throw new Error('Expected true/false.');
		}
		case 'int': {
			const n = parseInt(raw, 10);
			if (!Number.isFinite(n) || String(n) !== raw.trim()) throw new Error('Expected an integer.');
			return n;
		}
		case 'string':
			return raw;
		case 'json':
			try {
				return JSON.parse(raw);
			} catch {
				throw new Error('Not valid JSON.');
			}
	}
}

// `encodeFlagValue` lives in `$lib/constants` (client-safe).

function emptyToNull(v: FormDataEntryValue | null): string | null {
	if (v === null) return null;
	const s = String(v).trim();
	return s === '' ? null : s;
}

export const FLAG_SORT_COLS = ['key', 'valueType', 'updatedAt'] as const;

export interface ListFlagsArgs {
	q: string;
	skip: number;
	take: number;
	sort: { col: string; dir: 'asc' | 'desc' };
}

export async function listFlags(args: ListFlagsArgs) {
	const where = args.q
		? {
				OR: [
					{ key: { contains: args.q, mode: 'insensitive' as const } },
					{ description: { contains: args.q, mode: 'insensitive' as const } }
				]
			}
		: {};
	const orderBy = { [args.sort.col]: args.sort.dir };
	const [rows, total] = await prisma.$transaction([
		prisma.featureFlag.findMany({
			where,
			orderBy,
			skip: args.skip,
			take: args.take
		}),
		prisma.featureFlag.count({ where })
	]);
	return { rows, total };
}
