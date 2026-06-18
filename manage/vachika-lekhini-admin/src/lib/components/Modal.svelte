<script lang="ts">
	import { X } from '@lucide/svelte';
	import type { Snippet } from 'svelte';

	interface Props {
		open: boolean;
		title: string;
		subtitle?: string;
		size?: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl';
		onClose: () => void;
		children: Snippet;
		footer?: Snippet;
	}

	let { open, title, subtitle, size = 'lg', onClose, children, footer }: Props = $props();

	const sizes: Record<NonNullable<Props['size']>, string> = {
		sm: 'max-w-md',
		md: 'max-w-lg',
		lg: 'max-w-2xl',
		xl: 'max-w-4xl',
		'2xl': 'max-w-6xl',
		'3xl': 'max-w-[86vw]'
	};

	$effect(() => {
		if (!open) return;
		function onKey(e: KeyboardEvent) {
			if (e.key === 'Escape') onClose();
		}
		window.addEventListener('keydown', onKey);
		return () => window.removeEventListener('keydown', onKey);
	});

	$effect(() => {
		if (open) {
			document.body.style.overflow = 'hidden';
		} else {
			document.body.style.overflow = '';
		}
		return () => {
			document.body.style.overflow = '';
		};
	});
</script>

{#if open}
	<div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm overflow-y-auto">
		<button
			type="button"
			class="absolute inset-0 -z-10"
			aria-label="Close"
			onclick={onClose}
		></button>
		<div
			role="dialog"
			aria-modal="true"
			aria-labelledby="modal-title"
			class="bg-white w-full {sizes[size]} rounded-2xl shadow-2xl ring-1 ring-black/5 my-auto flex flex-col max-h-[calc(100svh-2rem)] transition-all duration-200"
		>
			<!-- Header -->
			<div class="flex items-start justify-between gap-3 px-5 py-4 bg-gradient-to-r from-slate-900 to-slate-800 rounded-t-2xl shrink-0">
				<div class="min-w-0">
					<h2 id="modal-title" class="text-base font-bold text-white tracking-tight truncate">{title}</h2>
					{#if subtitle}<p class="text-xs text-slate-400 mt-0.5 truncate">{subtitle}</p>{/if}
				</div>
				<button
					type="button"
					class="p-1.5 rounded-lg text-white/70 hover:text-white hover:bg-white/10 transition-colors shrink-0"
					onclick={onClose}
					aria-label="Close"
				>
					<X size={18} />
				</button>
			</div>

			<!-- Content -->
			<div class="px-6 py-5 overflow-hidden flex-1 flex flex-col min-h-0 bg-slate-50/50">
				{@render children()}
			</div>

			{#if footer}
				<div class="px-5 py-3 border-t border-gray-100 flex justify-end gap-2 shrink-0 bg-white rounded-b-2xl">
					{@render footer()}
				</div>
			{/if}
		</div>
	</div>
{/if}
