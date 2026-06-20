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
		sm: 'max-w-xl',
		md: 'max-w-2xl',
		lg: 'max-w-3xl',
		xl: 'max-w-4xl',
		'2xl': 'max-w-5xl',
		'3xl': 'max-w-6xl'
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
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
		<!-- backdrop click to close -->
		<button type="button" class="absolute inset-0 -z-10" aria-label="Close" onclick={onClose}></button>

		<div
			role="dialog"
			aria-modal="true"
			aria-labelledby="modal-title"
			class="w-[80vw] {sizes[size]} rounded-2xl flex flex-col max-h-[80vh] transition-all duration-200"
			style="background: rgba(255,255,255,0.92); backdrop-filter: blur(24px); border: 1px solid rgba(255,255,255,0.7); box-shadow: 0 8px 40px rgba(0,0,0,.16), 0 2px 8px rgba(0,0,0,.08), inset 0 1px 0 rgba(255,255,255,.9);"
		>
			<!-- Header -->
			<div class="flex items-center gap-3 px-5 py-3 rounded-t-2xl shrink-0"
				style="background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f1c2e 100%); border-bottom: 1px solid rgba(249,115,22,.15); box-shadow: 0 2px 12px rgba(0,0,0,.2), inset 0 1px 0 rgba(255,255,255,.06);">
				<div class="min-w-0 flex-1">
					<h2 id="modal-title" class="text-sm font-bold text-white tracking-tight truncate">{title}</h2>
					{#if subtitle}<p class="text-[11px] text-slate-400 mt-0.5 truncate">{subtitle}</p>{/if}
				</div>

				<div class="flex items-center gap-2 shrink-0">
					{#if headerLeft}
						{@render headerLeft()}
					{/if}

					{#if formId}
						<button
							type="button"
							onclick={onClose}
							class="px-3 py-1.5 rounded-lg text-xs font-medium text-white/70 hover:text-white hover:bg-white/10 transition-colors"
						>
							Cancel
						</button>
						<button
							type="submit"
							form={formId}
							class="px-4 py-1.5 rounded-lg text-xs font-semibold text-white transition-all"
						style="background: linear-gradient(135deg, #fb923c 0%, #ea580c 100%); box-shadow: 0 2px 8px rgba(234,88,12,.4), inset 0 1px 0 rgba(255,255,255,.2);"
						>
							{saveLabel}
						</button>
					{:else}
						<button
							type="button"
							class="p-1.5 rounded-lg text-white/60 hover:text-white hover:bg-white/10 transition-colors"
							onclick={onClose}
							aria-label="Close"
						>
							<X size={16} />
						</button>
					{/if}
				</div>
			</div>

			<!-- Scrollable content -->
			<div class="px-5 py-4 overflow-y-auto flex-1 min-h-0" style="background: rgba(248,250,255,0.55);">
				{@render children()}
			</div>

			{#if footer}
				<div class="px-5 py-3 border-t border-slate-100 flex justify-end gap-2 shrink-0 bg-white rounded-b-2xl">
					{@render footer()}
				</div>
			{/if}
		</div>
	</div>
{/if}
