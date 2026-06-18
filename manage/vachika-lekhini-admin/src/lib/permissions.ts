/// Granular permission keys for the admin panel.
/// Format: "<resource>.<action>"
/// Used by the Roles page to assign permissions to each AdminRole.

export const PERMISSION_GROUPS = [
	{
		label: 'Dashboard & Leaderboard',
		key: 'overview',
		permissions: [
			{ key: 'dashboard.view',    label: 'View' },
			{ key: 'leaderboard.view',  label: 'View' },
		]
	},
	{
		label: 'Mantras',
		key: 'mantras',
		permissions: [
			{ key: 'mantras.view',   label: 'View' },
			{ key: 'mantras.create', label: 'Create' },
			{ key: 'mantras.edit',   label: 'Edit' },
			{ key: 'mantras.delete', label: 'Delete' },
		]
	},
	{
		label: 'Store',
		key: 'store',
		permissions: [
			{ key: 'store.view',   label: 'View' },
			{ key: 'store.create', label: 'Create' },
			{ key: 'store.edit',   label: 'Edit' },
			{ key: 'store.delete', label: 'Delete' },
		]
	},
	{
		label: 'FAQs',
		key: 'faqs',
		permissions: [
			{ key: 'faqs.view',   label: 'View' },
			{ key: 'faqs.create', label: 'Create' },
			{ key: 'faqs.edit',   label: 'Edit' },
			{ key: 'faqs.delete', label: 'Delete' },
		]
	},
	{
		label: 'App Settings & Config',
		key: 'config',
		permissions: [
			{ key: 'app-settings.view', label: 'App Settings View' },
			{ key: 'app-settings.edit', label: 'App Settings Edit' },
			{ key: 'config.view',       label: 'Config View' },
			{ key: 'config.edit',       label: 'Config Edit' },
		]
	},
	{
		label: 'Accounts & Members',
		key: 'accounts',
		permissions: [
			{ key: 'accounts.view', label: 'View' },
			{ key: 'accounts.edit', label: 'Edit' },
			{ key: 'accounts.ban',  label: 'Ban/Unban' },
		]
	},
	{
		label: 'Practice',
		key: 'practice',
		permissions: [
			{ key: 'programs.view',    label: 'Programs View' },
			{ key: 'sessions.view',    label: 'Sessions View' },
			{ key: 'sessions.delete',  label: 'Sessions Delete' },
		]
	},
	{
		label: 'Rewards',
		key: 'rewards',
		permissions: [
			{ key: 'rewards.view',        label: 'Ledger View' },
			{ key: 'reward-rules.view',   label: 'Rules View' },
			{ key: 'reward-rules.edit',   label: 'Rules Edit' },
			{ key: 'invites.view',        label: 'Invites View' },
		]
	},
	{
		label: 'Support & Feedback',
		key: 'support',
		permissions: [
			{ key: 'support.view',   label: 'Issues View' },
			{ key: 'feedback.view',  label: 'Feedback View' },
			{ key: 'feedback.delete', label: 'Feedback Delete' },
		]
	},
	{
		label: 'Audit',
		key: 'audit',
		permissions: [
			{ key: 'otp-log.view', label: 'OTP Log View' },
			{ key: 'devices.view', label: 'Devices View' },
		]
	},
	{
		label: 'Admin Management',
		key: 'admins',
		permissions: [
			{ key: 'admins.view',   label: 'View' },
			{ key: 'admins.create', label: 'Create' },
			{ key: 'admins.edit',   label: 'Edit' },
			{ key: 'admins.delete', label: 'Delete' },
			{ key: 'roles.view',    label: 'Roles View' },
			{ key: 'roles.edit',    label: 'Roles Edit' },
		]
	},
] as const;

export type PermissionKey = (typeof PERMISSION_GROUPS)[number]['permissions'][number]['key'];

/// All permission keys flat.
export const ALL_PERMISSIONS: string[] = PERMISSION_GROUPS.flatMap((g) =>
	g.permissions.map((p) => p.key)
);

/// Default permissions per role (used for seed and first-time setup).
export const DEFAULT_PERMISSIONS: Record<string, string[]> = {
	super_admin: ALL_PERMISSIONS,
	main_admin: ALL_PERMISSIONS.filter(
		(p) =>
			!p.startsWith('admins.') &&
			!p.startsWith('roles.') &&
			!p.startsWith('support.') &&
			!p.startsWith('otp-log.') &&
			!p.startsWith('devices.')
	),
	assets_admin: ALL_PERMISSIONS.filter(
		(p) => p.startsWith('config.') || p.startsWith('app-settings.') || p === 'dashboard.view'
	),
	marketplace_admin: ALL_PERMISSIONS.filter(
		(p) => p.startsWith('store.') || p === 'dashboard.view'
	)
};
