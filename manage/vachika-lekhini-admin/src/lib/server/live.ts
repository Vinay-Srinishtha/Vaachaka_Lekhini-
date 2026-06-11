import { EventEmitter } from 'node:events';

/// In-process pub/sub bus for admin live updates.
/// Every Flutter-facing API endpoint calls `emit(entity)` after a successful
/// write; the SSE endpoint at /api/admin/stream fans it out to all connected
/// admin browsers immediately.

const globalForBus = globalThis as unknown as { __kvlBus?: EventEmitter };

if (!globalForBus.__kvlBus) {
	const bus = new EventEmitter();
	bus.setMaxListeners(200); // allow many open admin tabs
	globalForBus.__kvlBus = bus;
}

export const bus = globalForBus.__kvlBus!;

/// Entity types that trigger a live refresh in the admin.
export type LiveEntity =
	| 'session'
	| 'program'
	| 'member'
	| 'reward_event'
	| 'device'
	| 'account';

const EVENT = 'change';

export function emitChange(entity: LiveEntity) {
	bus.emit(EVENT, entity);
}

/// Subscribe to changes. Returns an unsubscribe function.
export function onchange(handler: (entity: LiveEntity) => void): () => void {
	bus.on(EVENT, handler);
	return () => bus.off(EVENT, handler);
}
