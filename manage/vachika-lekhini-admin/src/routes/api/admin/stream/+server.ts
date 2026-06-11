import type { RequestHandler } from './$types';
import { requireRole } from '$lib/server/auth';
import { onchange } from '$lib/server/live';

/// GET /api/admin/stream  (admin session required)
/// Server-Sent Events endpoint. Each connected admin browser gets a stream;
/// when any Flutter API endpoint writes to the DB it emits on the in-process
/// bus and every open stream sends an "change" event — the admin layout calls
/// invalidateAll() and SvelteKit re-runs all page load functions immediately.
export const GET: RequestHandler = async (event) => {
	requireRole(event, 'editor');

	let unsub: (() => void) | null = null;
	let controller: ReadableStreamDefaultController<Uint8Array>;

	const send = (entity: string) => {
		try {
			const data = `event: change\ndata: ${entity}\n\n`;
			controller.enqueue(new TextEncoder().encode(data));
		} catch {
			// client disconnected — unsubscribe
			unsub?.();
		}
	};

	const stream = new ReadableStream<Uint8Array>({
		start(ctrl) {
			controller = ctrl;
			// Send a heartbeat immediately so the browser knows the stream is alive.
			send('connected');
			// Subscribe to the in-process change bus.
			unsub = onchange(send);
		},
		cancel() {
			unsub?.();
		}
	});

	return new Response(stream, {
		headers: {
			'Content-Type': 'text/event-stream',
			'Cache-Control': 'no-cache',
			Connection: 'keep-alive',
			'X-Accel-Buffering': 'no' // disable nginx buffering
		}
	});
};
