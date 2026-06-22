import pg from 'pg';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
try { require('dotenv').config({ path: new URL('../.env', import.meta.url).pathname }); } catch {}

const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();

const { rows: quotes } = await client.query(`SELECT id, slug, "imageUrl" FROM "Quote" WHERE "imageUrl" IS NOT NULL`);
const { rows: sadhanas } = await client.query(`SELECT id, title, "imageUrl" FROM "GlobalSadhana" WHERE "imageUrl" IS NOT NULL`);
const { rows: mantras } = await client.query(`SELECT id, slug, "imageUrl", "previewImageUrl", "shareImageUrl", "pronunciationUrl" FROM "Mantra"`);
const { rows: store } = await client.query(`SELECT id, slug, "imageUrl" FROM "StoreItem" WHERE "imageUrl" IS NOT NULL`);

console.log('\n=== QUOTES ===');
console.table(quotes);
console.log('\n=== GLOBAL SADHANAS ===');
console.table(sadhanas);
console.log('\n=== MANTRAS ===');
console.table(mantras);
console.log('\n=== STORE ITEMS ===');
console.table(store);

await client.end();
