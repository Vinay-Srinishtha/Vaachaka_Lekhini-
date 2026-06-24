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
	UserPlus,
	Smartphone,
	HelpCircle,
	Sliders,
	Flag,
	MessageCircleHeart,
	Gift,
	KeyRound,
	Quote,
	Globe,
	GlobeLock,
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
	// ── Home ─────────────────────────────────────────────────────────────────
	{ href: '/', label: 'Dashboard', icon: LayoutDashboard, section: 'dashboard' },

	// ── Users — accounts, community, invites ─────────────────────────────────
	{ href: '/accounts',    label: 'Accounts',    icon: Users,     section: 'accounts',    group: 'Users' },
	{ href: '/leaderboard', label: 'Leaderboard', icon: Medal,     section: 'leaderboard', group: 'Users' },
	{ href: '/invites',     label: 'Invites',     icon: UserPlus,  section: 'invites',     group: 'Users' },

	// ── Content — what the app shows ─────────────────────────────────────────
	{ href: '/mantras',       label: 'Mantras',       icon: BookOpen,    section: 'mantras',       group: 'Content' },
	{ href: '/quotes',        label: 'Quotes',         icon: Quote,       section: 'quotes',        group: 'Content' },
	{ href: '/global-sadhana',label: 'Global Sadhana', icon: Globe,       section: 'global-sadhana',group: 'Content' },
	{ href: '/store',         label: 'Store',          icon: ShoppingBag, section: 'store',         group: 'Content' },
	{ href: '/faqs',          label: 'FAQs',           icon: HelpCircle,  section: 'faqs',          group: 'Content' },
	{ href: '/tnc',           label: 'Terms & Cond.',  icon: ScrollText,  section: 'tnc',           group: 'Content' },

	// ── Activity — user practice data ────────────────────────────────────────
	{ href: '/global-sadhana-dashboard', label: 'Sadhana Progress', icon: GlobeLock, section: 'global-sadhana-dashboard', group: 'Activity' },
	{ href: '/programs', label: 'Programs', icon: Layers,   section: 'programs', group: 'Activity' },
	{ href: '/sessions', label: 'Sessions', icon: Activity, section: 'sessions', group: 'Activity' },

	// ── Rewards ───────────────────────────────────────────────────────────────
	{ href: '/rewards',      label: 'Ledger',       icon: Coins, section: 'rewards',      group: 'Rewards' },
	{ href: '/reward-rules', label: 'Reward Rules', icon: Gift,  section: 'reward-rules', group: 'Rewards' },

	// ── Settings ──────────────────────────────────────────────────────────────
	{ href: '/app-settings', label: 'App Settings',  icon: Sliders,   section: 'app-settings', group: 'Settings' },
	{ href: '/config',       label: 'Config & Flags', icon: Settings2, section: 'config',       group: 'Settings' },

	// ── Support ───────────────────────────────────────────────────────────────
	{ href: '/support',  label: 'Issues',   icon: Flag,               section: 'support',  group: 'Support' },
	{ href: '/feedback', label: 'Feedback', icon: MessageCircleHeart, section: 'feedback', group: 'Support' },

	// ── System ────────────────────────────────────────────────────────────────
	{ href: '/otp-log', label: 'OTP Log', icon: MessageSquareDot, section: 'otp-log', group: 'System' },
	{ href: '/devices', label: 'Devices', icon: Smartphone,       section: 'devices', group: 'System' },
	{ href: '/admins',  label: 'Admins',  icon: ShieldCheck,      section: 'admins',  group: 'System' },
	{ href: '/roles',   label: 'Roles',   icon: KeyRound,         section: 'roles',   group: 'System' },
];
