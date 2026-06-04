<script lang="ts">
	import { AlertTriangle } from '@lucide/svelte';
	import type { Snippet } from 'svelte';

	interface Props {
		open: boolean;
		title: string;
		message: string;
		confirmLabel?: string;
		cancelLabel?: string;
		tone?: 'danger' | 'warning';
		onCancel: () => void;
		onConfirm: () => void;
		submitting?: boolean;
		footer?: Snippet;
	}

	let {
		open,
		title,
		message,
		confirmLabel = 'Confirm',
		cancelLabel = 'Cancel',
		tone = 'danger',
		onCancel,
		onConfirm,
		submitting = false,
		footer
	}: Props = $props();
</script>

{#if open}
	<div class="fixed inset-0 z-50 grid place-items-center bg-black/50 px-4">
		<div role="dialog" aria-modal="true" class="card max-w-md w-full p-6">
			<div class="flex items-start gap-4">
				<div class="w-10 h-10 rounded-full grid place-items-center shrink-0 {tone === 'danger' ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-700'}">
					<AlertTriangle size={20} />
				</div>
				<div class="flex-1">
					<h3 class="font-semibold text-gray-900">{title}</h3>
					<p class="text-sm text-gray-600 mt-1">{message}</p>
				</div>
			</div>
			<div class="mt-5 flex justify-end gap-2">
				{#if footer}
					{@render footer()}
				{:else}
					<button type="button" class="btn-secondary" onclick={onCancel} disabled={submitting}>
						{cancelLabel}
					</button>
					<button
						type="button"
						class={tone === 'danger' ? 'btn-danger' : 'btn-primary'}
						onclick={onConfirm}
						disabled={submitting}
					>
						{submitting ? 'Working…' : confirmLabel}
					</button>
				{/if}
			</div>
		</div>
	</div>
{/if}
