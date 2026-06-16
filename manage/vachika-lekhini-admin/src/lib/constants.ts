/// Mirror of Prisma enums — kept manually small so client code doesn't
/// import the generated Prisma types (which would pull `dotenv` etc.
/// into the browser bundle).

export const MANTRA_TAGS = [
	'peace',
	'righteousness',
	'healing',
	'protection',
	'strength',
	'courage',
	'wealth',
	'prosperity',
	'liberation',
	'enlightenment',
	'wisdom',
	'devotion'
] as const;
export type MantraTag = (typeof MANTRA_TAGS)[number];

export const FLAG_TYPES = ['bool', 'int', 'string', 'json'] as const;
export type FlagType = (typeof FLAG_TYPES)[number];

/// Stringify a stored flag value for the edit-form `rawValue` input.
/// Pure — safe to import from server or client.
export function encodeFlagValue(type: FlagType, value: unknown): string {
	switch (type) {
		case 'bool':
			return value ? 'true' : 'false';
		case 'int':
			return String(value ?? 0);
		case 'string':
			return value === null || value === undefined ? '' : String(value);
		case 'json':
			return JSON.stringify(value, null, 2);
	}
}

export const ADMIN_ROLES = [
	'super_admin',
	'main_admin',
	'assets_admin',
	'marketplace_admin'
] as const;
export type AdminRole = (typeof ADMIN_ROLES)[number];

/// Human-readable labels for each role.
export const ROLE_LABELS: Record<AdminRole, string> = {
	super_admin: 'Super Admin',
	main_admin: 'Main Admin',
	assets_admin: 'Assets Admin',
	marketplace_admin: 'Marketplace Admin'
};
