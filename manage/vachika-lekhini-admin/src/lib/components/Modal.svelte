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
		/** If set, the header renders Cancel + Save buttons that submit this form id. */
		formId?: string;
		saveLabel?: string;
		/** Snippet rendered left of Cancel in the header (e.g. a Delete button). */
		headerLeft?: Snippet;
	}

	let {
		open, title, subtitle, size = 'xl', onClose,
		children, footer, formId, saveLabel = 'Save Changes', headerLeft
	}: Props = $props();

	const sizes: Record<NonNullable<Props['size']>, string> = {
		sm: 'max-w-lg',
		md: 'max-w-3xl',
		lg: 'max-w-5xl',
		xl: 'max-w-6xl',
		'2xl': 'max-w-[92vw]',
		'3xl': 'max-w-[98vw]'
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
	<div class="fixed inset-0 z-50 flex items-center justify-center p-2 bg-black/40 backdrop-blur-sm overflow-hidden">
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
			class="bg-white w-full {sizes[size]} max-w-[calc(100vw-1rem)] rounded-xl shadow-2xl ring-1 ring-black/5 flex flex-col max-h-[calc(100svh-1rem)] {size === '3xl' ? 'h-[calc(100svh-1rem)]' : ''} transition-all duration-200"
		>
			<!-- Header — title left, actions right -->
			<div class="flex items-center gap-3 px-4 py-2 bg-gradient-to-r from-slate-900 to-slate-800 rounded-t-xl shrink-0">
				<div class="min-w-0 flex-1">
					<h2 id="modal-title" class="text-base font-bold text-white tracking-tight truncate">{title}</h2>
					{#if subtitle}<p class="text-xs text-slate-400 mt-0.5 truncate">{subtitle}</p>{/if}
				</div>

				<!-- Header action row -->
					<div class="flex items-center gap-2 shrink-0">
						{#if headerLeft}
							{@render headerLeft()}
						{/if}

						{#if formId}
							<!-- Cancel -->
							<button
								type="button"
								onclick={onClose}
								class="px-2.5 py-1 rounded-lg text-sm font-medium text-white/70 hover:text-white hover:bg-white/10 transition-colors"
							>
								Cancel
							</button>
							<!-- Save -->
							<button
								type="submit"
								form={formId}
								class="px-3 py-1 rounded-lg text-sm font-semibold bg-brand-500 hover:bg-brand-600 text-white transition-colors shadow-sm"
							>
								{saveLabel}
							</button>
						{:else}
							<!-- No form — just close X -->
							<button
							type="button"
							class="p-1.5 rounded-lg text-white/70 hover:text-white hover:bg-white/10 transition-colors"
							onclick={onClose}
							aria-label="Close"
							>
								<X size={18} />
							</button>
						{/if}
					</div>
				</div>

				<!-- Content -->
			<div class="px-3 py-3 overflow-hidden flex-1 flex flex-col min-h-0 bg-slate-50/50">
				{@render children()}
			</div>

			{#if footer}
				<div class="px-4 py-2 border-t border-gray-100 flex justify-end gap-2 shrink-0 bg-white rounded-b-xl">
					{@render footer()}
				</div>
			{/if}
		</div>
	</div>
{/if}
