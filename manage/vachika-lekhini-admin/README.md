# Vaachaka Lekhini Admin

Admin dashboard + content backend for the **Vaachaka Lekhini** Flutter app.
Everything the Flutter client sees — mantras, store items, feature flags — is controlled from here.

- SvelteKit 2 + Svelte 5 (runes)
- Tailwind CSS v4
- PostgreSQL 18 + Prisma 7 (`@prisma/adapter-pg`)
- JWT-based admin auth (HS256) with `super_admin / editor / viewer` roles
- Bun as the package manager and runtime

## Prerequisites

- [Bun](https://bun.sh) (used for install, dev, and seed scripts)
- A local PostgreSQL 14+ instance reachable at `localhost:5432` with `postgres / postgres` credentials (this is the default in the seeded `.env`)

## First-time setup

```sh
cd manage/vachika-lekhini-admin
bun install

# Create the database
createdb -U postgres vachika_lekhini   # or: psql -U postgres -c "CREATE DATABASE vachika_lekhini;"

# Apply migrations
bunx prisma migrate dev

# Seed mantras, store items, feature flags, and the default admin
bunx prisma db seed
```

The seed creates a `super_admin` named **admin** with password **admin123**. Sign in once and rotate it from the **Admins** page.

## Daily commands

```sh
bun run dev        # vite dev server (default http://localhost:5173)
bun run build      # production build
bun run preview    # preview the production build
bun run check      # typecheck (svelte-check)

# Database
bunx prisma migrate dev    # author + apply a migration
bunx prisma db seed        # re-run the seed (idempotent — upserts)
bunx prisma studio         # GUI for the DB
```

## Environment variables (`.env`)

| Var | Purpose |
|---|---|
| `DATABASE_URL` | Postgres connection string |
| `ADMIN_USERNAME` | Seeded admin's username |
| `ADMIN_BOOTSTRAP_PASSWORD` | Seeded admin's password (only read on first seed) |
| `SESSION_SECRET` | Secret used to sign admin JWTs — must be 16+ chars |

## Architecture

### Admin UI

All admin pages live under the `(admin)` route group, which is gated by `+layout.server.ts` (redirect to `/login` if no JWT cookie).

| Route | Role required | Notes |
|---|---|---|
| `/` | viewer | Dashboard with stat cards + recent users + top mantras |
| `/mantras` | viewer (CRUD: editor) | Catalog served to Flutter |
| `/mantras/new` | editor | Modal overlay over the list |
| `/mantras/:id/edit` | editor | Modal overlay over the list |
| `/store` | viewer (CRUD: editor) | Rewards store |
| `/store/new`, `/store/:id/edit` | editor | Modal overlays |
| `/config` | viewer (CRUD: editor) | Feature flags / remote config |
| `/config/new`, `/config/:key/edit` | editor | Modal overlays |
| `/users` | editor | Registered Flutter users, ban / unban |
| `/admins` | super_admin | Manage admin users + roles |
| `/login`, `/logout` | — | |

URL-driven state (so back-button and shareable links work):

- Lists: `?q=` (search), `?sort=col:dir`, `?page=`
- Modals: real routes (`/new`, `/:id/edit`) — list stays mounted underneath
- Delete confirms: `?delete=<id>` — transient, clears on close

### Roles

Ranked: `viewer` < `editor` < `super_admin`. `hasRole(role, min)` admits everyone at-or-above the minimum. Enforced both in `+page.server.ts` `load`/`actions` (`requireRole(event, 'editor')`) and in nav/visibility (`hasRole(admin.role, 'editor')`).

### JWT auth

- HS256 signed with `SESSION_SECRET`, 12h TTL
- Sent as `httpOnly` cookie named `admin_token` (`SameSite=Lax`)
- `hooks.server.ts` calls `resolveAdmin(cookies)` on every request → `event.locals.admin`
- Logout writes to `RevokedToken` (optional — token would expire anyway)

### Reusable components

Located in `src/lib/components/`. Use these — don't hand-roll equivalents:

- `DataTable` — search + sortable headers + pagination, all URL-bound
- `SearchInput`, `SortableHeader`, `Pagination` — building blocks of DataTable
- `Modal` — esc-to-close, click-outside-to-close, body scroll lock
- `ConfirmDialog` — destructive-action confirmation
- `FormField` — label + hint + per-field error rendering
- `TagMultiSelect` — chip-style multi-select bound to form fields
- `PageHeader`, `Sidebar`, `Topbar`, `StatCard` — layout primitives

## Public API (for the Flutter app)

Public, read-only, no admin auth. All payloads are **snake_case** (Dart-idiomatic).
Each response carries `Cache-Control` and `Last-Modified` headers so the client can poll cheaply.

| Endpoint | Description |
|---|---|
| `GET /api/v1/mantras` | Active mantras (sorted by admin-defined order) |
| `GET /api/v1/store` | Active rewards-store items |
| `GET /api/v1/config` | Flat key → value map for remote config / feature flags |

The Flutter side (Phase 9 of the client roadmap) replaces `MantraRepositoryLocal` etc. with `*RepositoryRemote` that points at these URLs.

## Project layout (key paths)

```
src/
  hooks.server.ts                  ← JWT cookie → event.locals.admin
  app.css                          ← Tailwind v4 + @utility helpers
  lib/
    constants.ts                   ← client-safe enums + helpers (snake-case-friendly)
    roles.ts                       ← hasRole helper
    url.ts                         ← URL query patching, sort parsing
    nav.ts                         ← sidebar nav config
    components/                    ← reusable UI
    server/
      prisma.ts                    ← single Prisma client (driver-adapter pattern)
      auth.ts                      ← loginAdmin, resolveAdmin, requireRole
      jwt.ts                       ← sign/verify admin JWTs
      list-query.ts                ← parse ?q ?sort ?page from URL
      snake-case.ts                ← `snakeize` + `snakeJson` for /api/v1
      mantras.ts, store.ts, flags.ts, users.ts   ← per-resource schema + queries
  routes/
    +layout.svelte                 ← global shell
    login/                         ← public
    logout/                        ← public
    (admin)/                       ← guarded route group (requires JWT)
      +layout.{server.ts,svelte}   ← sidebar + topbar + content slot
      +page.{server.ts,svelte}     ← dashboard
      mantras/  store/  config/    ← resource groups (list lives in +layout)
      users/  admins/
    api/v1/
      mantras/  store/  config/    ← public, snake_case JSON
prisma/
  schema.prisma                    ← source of truth for the DB
  seed.ts                          ← mantras + store + flags + default admin
```

## Security checklist before going live

- [ ] Rotate `SESSION_SECRET` to a long random string
- [ ] Change the default admin password
- [ ] Serve over HTTPS so the JWT cookie can use `Secure` (already conditional on `NODE_ENV`)
- [ ] Restrict access to `/admins` to a small number of `super_admin` accounts
- [ ] Decide who owns the `vachika_lekhini` Postgres database in production
