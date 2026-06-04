/// Recursively convert object keys to snake_case for the public Flutter API.
/// Arrays / primitives / Date values are passed through. Cycles are detected
/// (returns the cycled value as-is) to avoid stack overflows.

const cache = new Map<string, string>();

function toSnake(key: string): string {
	const cached = cache.get(key);
	if (cached !== undefined) return cached;
	const out = key
		.replace(/([a-z0-9])([A-Z])/g, '$1_$2')
		.replace(/([A-Z]+)([A-Z][a-z])/g, '$1_$2')
		.toLowerCase();
	cache.set(key, out);
	return out;
}

export function snakeize<T>(input: T, seen: WeakSet<object> = new WeakSet()): T {
	if (input === null || input === undefined) return input;
	if (typeof input !== 'object') return input;
	if (input instanceof Date) return input as unknown as T;
	if (Array.isArray(input)) {
		return input.map((v) => snakeize(v, seen)) as unknown as T;
	}
	if (seen.has(input as object)) return input;
	seen.add(input as object);

	const out: Record<string, unknown> = {};
	for (const [k, v] of Object.entries(input as Record<string, unknown>)) {
		out[toSnake(k)] = snakeize(v, seen);
	}
	return out as T;
}

/// JSON response with snake_case keys + ISO-8601 dates.
export function snakeJson(data: unknown, init?: ResponseInit): Response {
	const body = JSON.stringify(snakeize(data), (_k, v) => {
		if (v instanceof Date) return v.toISOString();
		return v;
	});
	return new Response(body, {
		...init,
		headers: {
			'content-type': 'application/json; charset=utf-8',
			...(init?.headers ?? {})
		}
	});
}
