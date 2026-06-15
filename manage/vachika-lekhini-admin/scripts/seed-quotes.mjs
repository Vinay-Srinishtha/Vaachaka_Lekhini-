import { createRequire } from 'module';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';

// Load .env manually
const envPath = new URL('../.env', import.meta.url);
const envContent = readFileSync(fileURLToPath(envPath), 'utf8');
for (const line of envContent.split('\n')) {
  const m = line.match(/^([^#=]+)=(.*)$/);
  if (m) process.env[m[1].trim()] = m[2].trim().replace(/^["']|["']$/g, '');
}

const { PrismaClient } = await import('../src/generated/prisma/client.js');
const prisma = new PrismaClient();

const flags = [
  {
    key: 'config.daily_quote_telugu',
    valueType: 'string',
    value: 'ధర్మో రక్షతి రక్షితః',
    description: 'Quote shown on Home screen (Telugu). Leave empty to hide the card.',
  },
  {
    key: 'config.daily_quote_attribution',
    valueType: 'string',
    value: 'మహాభారతం',
    description: 'Attribution line below the daily quote (e.g. "Ramayana"). Leave empty to hide.',
  },
];

for (const f of flags) {
  await prisma.featureFlag.upsert({
    where: { key: f.key },
    create: { key: f.key, valueType: f.valueType, value: f.value, description: f.description },
    update: { value: f.value, description: f.description },
  });
  console.log(`✓ ${f.key} = ${f.value}`);
}

await prisma.$disconnect();
console.log('Done.');
