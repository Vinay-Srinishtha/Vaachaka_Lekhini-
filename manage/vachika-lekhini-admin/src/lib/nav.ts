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
	BarChart3,
	HelpCircle,
	Sliders,
	Flag,
	MessageCircleHeart,
	Gift,
	ScrollText
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
	// ── Overview ─────────────────────────────────────────────────────────────
	{ href: '/', label: 'Dashboard', icon: LayoutDashboard },
	{ href: '/analytics', label: 'Analytics', icon: BarChart3, minRole: 'viewer' },

	// ── Content — what the app shows ─────────────────────────────────────────
	{ href: '/mantras', label: 'Mantras', icon: BookOpen, minRole: 'viewer', group: 'Content' },
	{ href: '/store', label: 'Store', icon: ShoppingBag, minRole: 'viewer', group: 'Content' },
	{ href: '/faqs', label: 'FAQs', icon: HelpCircle, minRole: 'viewer', group: 'Content' },
	{ href: '/app-settings', label: 'App Settings', icon: Sliders, minRole: 'editor', group: 'Content' },
	{ href: '/config', label: 'Config & Flags', icon: Settings2, minRole: 'viewer', group: 'Content' },

	// ── Practice — user activity ──────────────────────────────────────────────
	{ href: '/accounts', label: 'Accounts', icon: Users, minRole: 'editor', group: 'Practice' },
	{ href: '/programs', label: 'Programs', icon: Layers, minRole: 'editor', group: 'Practice' },
	{ href: '/sessions', label: 'Sessions', icon: Activity, minRole: 'editor', group: 'Practice' },
	{ href: '/enrolments', label: 'Enrolments', icon: Mic2, minRole: 'editor', group: 'Practice' },

	// ── Rewards ───────────────────────────────────────────────────────────────
	{ href: '/rewards', label: 'Rewards Ledger', icon: Coins, minRole: 'editor', group: 'Rewards' },
	{ href: '/invites', label: 'Invites', icon: UserPlus, minRole: 'editor', group: 'Rewards' },

	// ── Support ───────────────────────────────────────────────────────────────
	{ href: '/support', label: 'Issues Reported', icon: Flag, minRole: 'viewer', group: 'Support' },
	{ href: '/feedback', label: 'Feedback', icon: MessageCircleHeart, minRole: 'viewer', group: 'Support' },

	// ── Audit ─────────────────────────────────────────────────────────────────
	{ href: '/otp-log', label: 'OTP Log', icon: MessageSquareDot, minRole: 'editor', group: 'Audit' },
	{ href: '/devices', label: 'Devices', icon: Smartphone, minRole: 'editor', group: 'Audit' },
	{ href: '/admins', label: 'Admins', icon: ShieldCheck, minRole: 'super_admin', group: 'Audit' },
];
