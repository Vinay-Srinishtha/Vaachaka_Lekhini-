import pg from 'pg';
const client = new pg.Client({ connectionString: process.env.DATABASE_URL });
await client.connect();
const { rows } = await client.query(`SELECT id, slug, "imageUrl", "isActive" FROM "Quote" ORDER BY "createdAt" DESC LIMIT 20`);
console.table(rows);
await client.end();
