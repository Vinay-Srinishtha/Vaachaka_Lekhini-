import { S3Client, ListObjectsV2Command } from '@aws-sdk/client-s3';
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
try { require('dotenv').config({ path: new URL('../.env', import.meta.url).pathname }); } catch {}

const region = process.env.AWS_REGION;
const bucket = process.env.S3_BUCKET_NAME;

const s3 = new S3Client({
  region,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  }
});

const res = await s3.send(new ListObjectsV2Command({ Bucket: bucket, Prefix: 'quotations/' }));
if (!res.Contents?.length) {
  console.log('No objects found under quotations/ in S3.');
} else {
  console.log(`Found ${res.Contents.length} object(s) under quotations/:\n`);
  res.Contents.forEach(o => console.log(' ', o.Key, `(${o.Size} bytes)`));
}
