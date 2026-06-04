// See https://svelte.dev/docs/kit/types#app.d.ts
import type { AdminRole } from '$lib/roles';

declare global {
	namespace App {
		interface Locals {
			admin: {
				id: string;
				username: string;
				role: AdminRole;
			} | null;
		}
		interface PageData {
			admin?: Locals['admin'];
		}
	}
}

export {};
