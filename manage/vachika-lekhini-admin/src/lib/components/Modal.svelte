<script lang="ts">
	import { X } from '@lucide/svelte';
	import type { Snippet } from 'svelte';
	import { onMount } from 'svelte';

	interface Props {
		open: boolean;
		title: string;
		subtitle?: string;
		size?: 'sm' | 'md' | 'lg' | 'xl' | '2xl';
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
		'2xl': 'max-w-6xl'
	};

	onMount(() => {
		function onKey(e: KeyboardEvent) {
			if (e.key === 'Escape' && open) onClose();
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
	<div class="fixed inset-0 z-50 flex items-start sm:items-center justify-center p-0 sm:p-4 bg-black/50 overflow-y-auto">
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
			class="bg-white w-full {sizes[size]} sm:rounded-xl shadow-xl my-0 sm:my-8 flex flex-col max-h-screen sm:max-h-[calc(100vh-4rem)]"
		>
			<div class="flex items-start justify-between gap-3 px-5 py-4 border-b border-gray-200 shrink-0">
				<div class="min-w-0">
					<h2 id="modal-title" class="font-semibold text-gray-900 truncate">{title}</h2>
					{#if subtitle}<p class="text-xs text-gray-500 mt-0.5 truncate">{subtitle}</p>{/if}
				</div>
				<button
					type="button"
					class="p-1 rounded text-gray-400 hover:text-gray-700 hover:bg-gray-100"
					onclick={onClose}
					aria-label="Close"
				>
					<X size={20} />
				</button>
			</div>
			<div class="px-5 py-5 overflow-y-auto flex-1">
				{@render children()}
			</div>
			{#if footer}
				<div class="px-5 py-3 border-t border-gray-200 flex justify-end gap-2 shrink-0">
					{@render footer()}
				</div>
			{/if}
		</div>
	</div>
{/if}
