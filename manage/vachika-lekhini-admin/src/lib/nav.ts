import type { Component } from 'svelte';
import {
	LayoutDashboard,
	BookOpen,
	Medal,
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
	HelpCircle,
	Sliders,
	Flag,
	MessageCircleHeart,
	Gift,
	ScrollText
} from '@lucide/svelte';
export interface NavItem {
	href: string;
	label: string;
	icon: Component;
	/// Section key used for role-based visibility (matches sectionForPath).
	section: string;
	group?: string;
}

/// Sidebar nav. Items are hidden when the admin's role can't access the
/// item's section (see roles.ts ROLE_SECTIONS).
export const NAV_ITEMS: NavItem[] = [
	// ── Overview ─────────────────────────────────────────────────────────────
	{ href: '/',             label: 'Dashboard',   icon: LayoutDashboard, section: 'dashboard' },
	{ href: '/leaderboard',  label: 'Leaderboard', icon: Medal, section: 'leaderboard' },

	// ── Content — what the app shows ─────────────────────────────────────────
	{ href: '/mantras', label: 'Mantras', icon: BookOpen, section: 'mantras', group: 'Content' },
	{ href: '/store', label: 'Store', icon: ShoppingBag, section: 'store', group: 'Content' },
	{ href: '/faqs', label: 'FAQs', icon: HelpCircle, section: 'faqs', group: 'Content' },
	{ href: '/app-settings', label: 'App Settings', icon: Sliders, section: 'app-settings', group: 'Content' },
	{ href: '/config', label: 'Config & Flags', icon: Settings2, section: 'config', group: 'Content' },

	// ── Practice — user activity ──────────────────────────────────────────────
	{ href: '/accounts', label: 'Accounts', icon: Users, section: 'accounts', group: 'Practice' },
	{ href: '/programs', label: 'Programs', icon: Layers, section: 'programs', group: 'Practice' },
	{ href: '/sessions', label: 'Sessions', icon: Activity, section: 'sessions', group: 'Practice' },
	{ href: '/enrolments', label: 'Enrolments', icon: Mic2, section: 'enrolments', group: 'Practice' },

	// ── Rewards ───────────────────────────────────────────────────────────────
	{ href: '/rewards', label: 'Rewards Ledger', icon: Coins, section: 'rewards', group: 'Rewards' },
	{ href: '/invites', label: 'Invites', icon: UserPlus, section: 'invites', group: 'Rewards' },

	// ── Support ───────────────────────────────────────────────────────────────
	{ href: '/support', label: 'Issues Reported', icon: Flag, section: 'support', group: 'Support' },
	{ href: '/feedback', label: 'Feedback', icon: MessageCircleHeart, section: 'feedback', group: 'Support' },

	// ── Audit ─────────────────────────────────────────────────────────────────
	{ href: '/otp-log', label: 'OTP Log', icon: MessageSquareDot, section: 'otp-log', group: 'Audit' },
	{ href: '/devices', label: 'Devices', icon: Smartphone, section: 'devices', group: 'Audit' },
	{ href: '/admins', label: 'Admins', icon: ShieldCheck, section: 'admins', group: 'Audit' },
];
