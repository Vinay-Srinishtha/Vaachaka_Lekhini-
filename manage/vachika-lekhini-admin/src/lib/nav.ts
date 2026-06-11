import type { Component } from 'svelte';
import {
	LayoutDashboard,
	BookOpen,
	ShoppingBag,
	Settings2,
	Users,
	ShieldCheck,
	Layers,
	Activity,
	Coins,
	MessageSquareDot,
	Mic2,
	UserPlus,
	Smartphone,
	BarChart3
} from '@lucide/svelte';
import type { AdminRole } from './roles';

export interface NavItem {
	href: string;
	label: string;
	icon: Component;
	minRole?: AdminRole;
	group?: string;
}

/// Sidebar nav. Items with minRole are hidden for admins below that rank.
export const NAV_ITEMS: NavItem[] = [
	{ href: '/', label: 'Dashboard', icon: LayoutDashboard },
	{ href: '/analytics', label: 'Analytics', icon: BarChart3, minRole: 'viewer' },

	{ href: '/mantras', label: 'Mantras', icon: BookOpen, minRole: 'viewer', group: 'Catalog' },
	{ href: '/store', label: 'Store', icon: ShoppingBag, minRole: 'viewer', group: 'Catalog' },
	{ href: '/config', label: 'Config & Flags', icon: Settings2, minRole: 'viewer', group: 'Catalog' },

	{ href: '/accounts', label: 'Accounts', icon: Users, minRole: 'editor', group: 'Users' },
	{ href: '/programs', label: 'Programs', icon: Layers, minRole: 'editor', group: 'Users' },
	{ href: '/sessions', label: 'Sessions', icon: Activity, minRole: 'editor', group: 'Users' },
	{ href: '/rewards', label: 'Rewards Ledger', icon: Coins, minRole: 'editor', group: 'Users' },
	{ href: '/enrolments', label: 'Enrolments', icon: Mic2, minRole: 'editor', group: 'Users' },
	{ href: '/invites', label: 'Invites', icon: UserPlus, minRole: 'editor', group: 'Users' },

	{ href: '/otp-log', label: 'OTP Log', icon: MessageSquareDot, minRole: 'editor', group: 'Audit' },
	{ href: '/devices', label: 'Devices', icon: Smartphone, minRole: 'editor', group: 'Audit' },
	{ href: '/admins', label: 'Admins', icon: ShieldCheck, minRole: 'super_admin', group: 'Audit' },
];
