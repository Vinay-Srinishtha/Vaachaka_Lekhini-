# Vaachaka Lekhini Deployment

## Production structure

- Vercel hosts the SvelteKit admin dashboard and `/api/v1/*` API.
- Neon (or another managed PostgreSQL provider) stores production data.
- 2Factor.in sends and verifies mobile OTPs.
- The Flutter APK is distributed separately and calls the Vercel API over HTTPS.

## 1. Create the production database

Create a PostgreSQL database in a region close to the users. Keep both URLs:

- pooled URL: Vercel runtime `DATABASE_URL`
- direct URL: schema migrations and one-time seeding

Apply the committed migrations:

```bash
cd manage/vachika-lekhini-admin
DATABASE_URL="<direct-url>" bun run db:deploy
```

Seed the catalogs, feature flags, and first administrator once:

```bash
DATABASE_URL="<direct-url>" \
ADMIN_USERNAME="<admin-name>" \
ADMIN_BOOTSTRAP_PASSWORD="<strong-password>" \
bun run db:seed
```

Do not automatically seed on every deployment.

## 2. Configure the Vercel project

Import the Git repository and use:

- Base directory: `manage/vachika-lekhini-admin`
- Framework preset: SvelteKit
- Install command: read from `vercel.json` (`bun install`)
- Build command: read from `vercel.json` (`bun run build`)
- Production branch: the branch selected for releases

Add these production environment variables:

```text
DATABASE_URL=<pooled-postgres-url>
SESSION_SECRET=<random-32-byte-secret>
USER_JWT_SECRET=<different-random-32-byte-secret>
OTP_PROVIDER=2factor
TWO_FACTOR_API_KEY=<provider-api-key>
TWO_FACTOR_TEMPLATE=OTPONLY
```

Generate JWT secrets with:

```bash
openssl rand -hex 32
```

Never deploy with `OTP_PROVIDER=dev`.

## 3. Verify the deployment

Production hostname:

```bash
curl -f https://vaachaka-lekhini.vercel.app/api/v1/health
curl -f https://vaachaka-lekhini.vercel.app/api/v1/mantras
curl -f https://vaachaka-lekhini.vercel.app/api/v1/store
curl -f https://vaachaka-lekhini.vercel.app/api/v1/config
curl -f https://vaachaka-lekhini.vercel.app/api/v1/stats
```

Then verify:

1. `/login` accepts the seeded administrator.
2. Admin catalog changes appear in the public APIs.
3. OTP start and verify use the production SMS provider.
4. A Flutter registration appears in the admin accounts view.
5. Member, program, session, device, and reward synchronization reaches PostgreSQL.

## 4. Configure the production hostname

Attach a custom hostname such as:

```text
admin.example.com
```

Vercel provisions HTTPS. Use only the HTTPS hostname in mobile builds.

## 5. Connect the Flutter APK

For a production APK:

```bash
flutter build apk --release \
  --dart-define=KVL_API_BASE=https://vaachaka-lekhini.vercel.app
```

Do not append `/api/v1`; the Flutter client adds endpoint paths.

For a production-like device test:

```bash
flutter run \
  --dart-define=KVL_API_BASE=https://vaachaka-lekhini.vercel.app
```

Native Android and iOS clients do not require browser CORS headers.

## 6. Release procedure

For every backend release:

1. Back up the production database.
2. Run `DATABASE_URL="<direct-url>" bun run db:deploy`.
3. Deploy the matching Git commit to Vercel.
4. Check `/api/v1/health` and public endpoints.
5. Test admin login and one authenticated Flutter request.
6. Review Vercel function logs for errors.

Do not rotate `USER_JWT_SECRET` during a normal deployment. Rotating it invalidates
all Flutter access and refresh tokens.

## 7. Operations

- Enable database backups and point-in-time recovery.
- Restrict production database credentials to Vercel and deployment operators.
- Monitor Vercel function errors, latency, and usage limits.
- Apply OTP rate limiting and provider spend alerts before a public launch.
- Use a separate staging database and Vercel preview environment for pre-production tests.
- Change the bootstrap administrator password immediately after the first login.
