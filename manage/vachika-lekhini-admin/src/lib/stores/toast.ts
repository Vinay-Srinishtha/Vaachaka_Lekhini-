import { writable } from 'svelte/store';

export type ToastType = 'success' | 'error' | 'info';

export interface Toast {
	id: string;
	message: string;
	type: ToastType;
}

const { subscribe, update } = writable<Toast[]>([]);

function show(message: string, type: ToastType = 'success', duration = 3500) {
	const id = crypto.randomUUID();
	update((ts) => [...ts, { id, message, type }]);
	setTimeout(() => dismiss(id), duration);
}

function dismiss(id: string) {
	update((ts) => ts.filter((t) => t.id !== id));
}

export const toasts = { subscribe, show, dismiss };
