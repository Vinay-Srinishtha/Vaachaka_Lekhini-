/**
 * clear-quote-images.mjs
 *
 * Sets "imageUrl" = NULL on every Quote row so images can be re-uploaded.
 *
 * Usage:
 *   node scripts/clear-quote-images.mjs            # dry run — shows count only
 *   node scripts/clear-quote-images.mjs --apply    # commits the change
 *
 * Requires DATABASE_URL in environment (same as the app uses).
 */

import pg from 'pg';
import { createRequire } from 'module';

// Load .env if present (dev convenience — production uses real env vars)
const require = createRequire(import.meta.url);
try {
  const dotenv = require('dotenv');
  dotenv.config({ path: new URL('../.env', import.meta.url).pathname });
} catch { /* dotenv optional */ }

const apply = process.argv.includes('--apply');

const url = process.env.DATABASE_URL;
if (!url) {
  console.error('ERROR: DATABASE_URL is not set.');
  process.exit(1);
}

const client = new pg.Client({ connectionString: url });

async function main() {
  await client.connect();

  const { rows: [{ count }] } = await client.query(
    `SELECT COUNT(*) AS count FROM "Quote" WHERE "imageUrl" IS NOT NULL`
  );
  const total = Number(count);

  if (total === 0) {
    console.log('No quotes have an imageUrl set — nothing to do.');
    return;
  }

  console.log(`Found ${total} quote(s) with imageUrl set.`);

  if (!apply) {
    console.log('\nDRY RUN — no changes made.');
    console.log('Re-run with --apply to clear them:\n');
    console.log('  node scripts/clear-quote-images.mjs --apply\n');
    return;
  }

  const { rowCount } = await client.query(
    `UPDATE "Quote" SET "imageUrl" = NULL WHERE "imageUrl" IS NOT NULL`
  );
  console.log(`✓ Cleared imageUrl on ${rowCount} quote(s).`);
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => client.end());
