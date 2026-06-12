<script lang="ts">
	import { CheckCircle, XCircle, Info, X } from '@lucide/svelte';
	import { toasts } from '$lib/stores/toast';

	const styles = {
		success: 'bg-green-50 border-green-200 text-green-800',
		error: 'bg-red-50 border-red-200 text-red-800',
		info: 'bg-blue-50 border-blue-200 text-blue-800'
	};
	const iconStyles = {
		success: 'text-green-600',
		error: 'text-red-600',
		info: 'text-blue-600'
	};
</script>

<div class="fixed bottom-6 right-6 z-[100] flex flex-col gap-2 pointer-events-none" aria-live="polite">
	{#each $toasts as toast (toast.id)}
		<div
			class="flex items-start gap-3 px-4 py-3 rounded-xl border shadow-lg backdrop-blur-sm pointer-events-auto
				max-w-sm w-full animate-toast-in {styles[toast.type]}"
			role="alert"
		>
			{#if toast.type === 'success'}<CheckCircle size={18} class="shrink-0 mt-0.5 {iconStyles.success}" />
			{:else if toast.type === 'error'}<XCircle size={18} class="shrink-0 mt-0.5 {iconStyles.error}" />
			{:else}<Info size={18} class="shrink-0 mt-0.5 {iconStyles.info}" />{/if}
			<p class="flex-1 text-sm font-medium leading-snug">{toast.message}</p>
			<button
				type="button"
				onclick={() => toasts.dismiss(toast.id)}
				class="shrink-0 p-0.5 rounded hover:bg-black/10 transition-colors"
				aria-label="Dismiss"
			>
				<X size={14} />
			</button>
		</div>
	{/each}
</div>

<style>
	@keyframes toast-in {
		from {
			opacity: 0;
			transform: translateY(8px) scale(0.97);
		}
		to {
			opacity: 1;
			transform: translateY(0) scale(1);
		}
	}
	.animate-toast-in {
		animation: toast-in 180ms ease-out both;
	}
</style>
