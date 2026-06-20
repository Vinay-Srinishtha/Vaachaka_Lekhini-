// See https://svelte.dev/docs/kit/types#app.d.ts
import type { AdminRole } from '$lib/roles';

declare global {
	namespace App {
		interface Error {
			message: string;
			/// Machine-readable error code the mobile app maps to a localized message.
			code?: string;
		}
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
