import type { Component } from 'svelte';
import {
	LayoutDashboard,
	BookOpen,
	ShoppingBag,
	Settings2,
	Users,
	ShieldCheck
} from '@lucide/svelte';
import type { AdminRole } from './roles';

export interface NavItem {
	href: string;
	label: string;
	icon: Component;
	minRole?: AdminRole;
}

/// Sidebar nav. Items with minRole are hidden for admins below that rank.
export const NAV_ITEMS: NavItem[] = [
	{ href: '/', label: 'Dashboard', icon: LayoutDashboard },
	{ href: '/mantras', label: 'Mantras', icon: BookOpen, minRole: 'viewer' },
	{ href: '/store', label: 'Store', icon: ShoppingBag, minRole: 'viewer' },
	{ href: '/config', label: 'Config & Flags', icon: Settings2, minRole: 'viewer' },
	{ href: '/accounts', label: 'Accounts', icon: Users, minRole: 'editor' },
	{ href: '/admins', label: 'Admins', icon: ShieldCheck, minRole: 'super_admin' }
];
