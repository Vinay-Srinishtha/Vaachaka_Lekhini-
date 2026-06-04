# Deferred work — sync + auth landing

_Written: 2026-05-25 after the Account/Member schema migration and the Flutter sync foundation landed._
_Companion to `STATUS.md` (current build state) and `ROADMAP.md` (phase plan)._

This page lists work that was scoped, designed, and deliberately **not** built in the session that delivered the server-side sync surface + Flutter auth/outbox foundation. Each entry has a "what", a "why deferred", and a "shape of the work" so the next pass can be picked up without re-deriving context.

---

## 1. Deep rename inside Flutter: `Profile` → `Member`, `User` → `Account`

**Status:** server uses the new names everywhere; Flutter still uses the old names internally and maps at the API boundary.

**Why deferred**

- The rename is **mechanical but invasive**: every screen under `lib/features/profiles/**`, `lib/features/auth/**`, the Drift tables, Hive keys, Riverpod providers, and the router constants. Around 60+ files touch one of those identifiers.
- The API contract works **without** the rename — the snake_case API uses `member` / `account` keys, and the Flutter mapping in `MantraDto` (and the planned DTOs for member/program/session) reads from those keys regardless of what the internal Dart type is called.
- Renaming mid-feature would have masked real diffs in a noisy churn. Better to land sync functionality first, ship it, then do a focused cleanup pass with nothing else in flight.

**Shape of the work**

1. Decide: rename the Drift tables too (`profiles` → `members`, etc.) or only the Dart types? A table rename needs a Drift migration since the schema version bumps.
2. `Profile` → `Member`, `User` → `Account` across:
   - `lib/features/profiles/**` → `lib/features/members/**`
   - `lib/features/auth/domain/session.dart` — `userId` → `accountId`
   - `lib/app/providers.dart` — every `*ProfileProvider` rename
   - `lib/core/storage/storage_keys.dart` — `activeProfileId` → `activeMemberId`, box name `kvl_profiles` → `kvl_members`
   - `lib/app/router.dart` — `KvlRoute.profile`, `_titles`, the StatefulShell branch order doesn't change (just the identifier strings).
3. Migration story for already-installed users: the old Hive box `kvl_profiles` still has data. Either rename the box (Hive doesn't support this directly; copy + delete) or keep the old box name and rename only the Dart symbols. Recommend the latter — names matter for new readers; box names are internal.

**Estimated size:** ~3–4 hours of mechanical edits + a careful `flutter analyze` pass + a smoke test of every profile-touching screen.

---

## 2. Routing existing Drift writes through the sync outbox

**Status:** `SyncOutbox` + `SyncEngine` exist and work. **No write site calls `enqueue()` yet.** That means current local writes (program creates, counter ticks, reward grants) still only land in Drift — they never push to the server.

**Why deferred**

- This is **surgery across multiple repositories**:
  - `ProgramRepositoryDrift.create / .update`
  - `RewardRepositoryDrift.earn / .spend`
  - Session-end paths in `PracticeController` (where a counter run completes)
  - `ProfileRepositoryLocal.create / .update / .delete`
- Each touched method needs an `await syncEngine.enqueue(<kind>, <snake_case_payload>)` plus careful thinking about **what** to enqueue. A session-end isn't one write — it's one `sessions.append` AND probably one `programs.upsert` (the totalWritings cache moved).
- Doing this without first having Flutter login UI means we can't actually test the round trip — the outbox would just queue forever because no JWT exists.
- The right pre-req is **Login UI first** (item #3) → real account → then plumb each write site, verifying end-to-end at each step.

**Shape of the work**

For each repository write, follow this pattern:

```dart
// inside ProgramRepositoryDrift.create
final created = await _db.into(_db.programs).insertReturning(...);
await _syncEngine.enqueue('programs.upsert', {
  'programs': [_toSnakeJson(created)],
});
return created;
```

Mapping table:

| Local write | Outbox kind | Endpoint |
|---|---|---|
| `ProfileRepositoryLocal.create` / `.update` | `members.upsert` | `POST /api/v1/members` |
| `ProgramRepositoryDrift.create` / `.update` | `programs.upsert` | `POST /api/v1/programs` |
| `PracticeController.finishSession` | `sessions.append` (+ `programs.upsert` for the cache bump) | `POST /api/v1/sessions` |
| `RewardRepositoryDrift.earn` / `.spend` | `reward_events.append` | `POST /api/v1/reward-events` |

Idempotency is already handled server-side via client-supplied UUIDs + `skipDuplicates: true`. The outbox retries failed pushes on connectivity restore, so transient offline windows are safe.

**Conflict resolution.** Today's `SyncEngine.pull()` overwrites in-memory state from the `/api/v1/me` payload. The matching Drift-write half is still TODO: reconcile each puller record against local by `updated_at` and keep the newer one. Two phones running the same account is the case that needs this.

**Estimated size:** ~half a day per repository (counting the test pass).

---

## 3. Flutter login + signup UI

**Status:** `AuthService` is ready. No screen in the app calls it. The existing `welcome_screen.dart`, `create_account_screen.dart`, `otp_login_screen.dart` still drive the dummy `AuthRepositoryLocal` flow.

**Why deferred**

- Designing the UX for **OTP + password coexisting** needs a small decision: do we offer "Sign in" with both, or default to OTP and let the user set a password later from Settings? My recommendation is the second — fewer fields on first launch — but it's a product call.
- Hooking up just `AuthService.verifyOtp` to the existing screens is mechanical, but doing it well means handling: OTP resend cooldown, error messages from the server (rate-limited, invalid code, banned account), and the password-set follow-up after first OTP signup.

**Shape of the work**

1. **`create_account_screen.dart`** — replace dummy `AuthRepository.startOtp` with `AuthService.startOtp`.
2. **OTP entry screen** — replace dummy verify with `AuthService.verifyOtp`. On success → navigate to profile-select (which is already the second screen of the existing flow).
3. **New "Set a password" screen** — optional, shown once after first successful OTP signup. Calls `AuthService.setPassword`. Add an entry to **Settings → Security** to change it later.
4. **New "Sign in with password" path** on the welcome screen — small "Use password" link under the mobile-entry form. Routes to a single-page form that calls `AuthService.passwordLogin`.
5. **Logout** — `Settings → Logout` button calls `AuthService.logout` and pops to welcome.
6. Wire the existing `AuthRepository` provider in `lib/app/providers.dart` to delegate to `AuthService` so the rest of the app's `sessionProvider` stays unchanged.

**Estimated size:** ~1 day including the new "Set password" screen + Settings entry.

---

## 4. Firebase Cloud Messaging (push notifications)

**Status:** `Device` table exists server-side with a `pushToken` column. `POST /api/v1/devices` accepts a token. Flutter has nothing FCM-related installed yet.

**Why deferred**

- User confirmed Firebase is **for notifications only** — not auth. So the integration is bounded to one purpose: deliver a daily-practice reminder + milestone-earned notifications.
- Setup is non-trivial: `firebase_core` + `firebase_messaging`, the Android `google-services.json`, the iOS `GoogleService-Info.plist` + APNs setup, AndroidManifest permissions, iOS capabilities. None of this is risky, but it doesn't pay off until at least one notification campaign exists server-side — which we haven't designed.
- Pairing this with **a server-side notification trigger** (cron that picks profiles whose `currentStreak` ≥ 7 + sends a push, or a "you've completed your daily target" check) is a separate piece of work that lives on the admin side.

**Shape of the work**

**Flutter side:**

1. `flutter pub add firebase_core firebase_messaging`
2. `flutterfire configure` to land the platform config files.
3. On app start (after auth), request notification permission + read FCM token via `FirebaseMessaging.instance.getToken()`.
4. POST it via `syncEngine.enqueue('devices.upsert', { id, platform, app_version, push_token, last_member_id })`.
5. Foreground handler: show a Material banner. Background: rely on system notification.

**Server side (later):**

1. Service-account-backed admin SDK for sending pushes from a SvelteKit endpoint or cron worker.
2. Designed campaigns:
   - Daily reminder at the member's `reminderTime` from `Member.preferences`.
   - Milestone push when `Program.totalWritings` crosses a target boundary.

**Estimated size:** ~1 day for the Flutter wiring; another ~1 day for the first server-side campaign.

---

## 5. R2/S3 storage for voice + handwriting blobs

**Status:** `VoiceEnrolment.embeddingUrl` and `HandwritingSample.storageUrl` are `String?` columns in the schema. No upload pipeline exists yet.

**Why deferred**

- Bucket setup is operational (R2 account, CORS, signed URLs) — not a coding task, and the user hasn't picked a provider yet (R2 was my recommendation; not confirmed).
- The existing Flutter voice + handwriting enrolment is local-only; until we have the buckets, members can re-enrol per device. That's a UX regression but not a correctness issue.

**Shape of the work**

1. Pick provider (R2 / S3 / Backblaze B2). All have the same API surface for our needs.
2. Add a signed-upload endpoint to the admin: `POST /api/v1/uploads/sign` → returns `{ upload_url, public_url, headers }`. Bearer-protected so only authed accounts can upload.
3. Flutter side: after enrolment completes, request a signed URL, PUT the blob, then `enqueue('voice_enrolments.upsert', { ..., embedding_url })`.
4. Server validates `embedding_url` belongs to the configured bucket on accept.

**Estimated size:** ~1 day once a provider is chosen and credentials land in the admin's `.env`.

---

## 6. Two-device conflict resolution

**Status:** the schema has `updatedAt` on every mutable row, and the server's `POST` endpoints overwrite local data on upsert. But the Flutter side's `SyncEngine.pull()` currently just emits the server snapshot — it doesn't reconcile field-by-field with local Drift state.

**Why deferred**

- Real conflict resolution requires either (a) field-by-field LWW with explicit conflict handlers, or (b) an operational transform — both meaningful design + test effort.
- The single-device case (one person, one phone) is the 95% case for v1. Two devices on the same account is a "future-you" problem.

**Shape of the work**

LWW (last-write-wins) by `updated_at` is the simplest and right answer for KVL — counter increments are commutative anyway, and program metadata changes are infrequent.

1. `SyncEngine.pull()` → for each member/program/session in the snapshot, compare `updated_at` against the local Drift row. If server is newer, overwrite. If local is newer, schedule a push (it'll re-overwrite on the server).
2. Sessions and reward events are append-only — no conflicts possible.
3. Document the policy in `STATUS.md` so reviewers know the contract.

**Estimated size:** ~1 day once item #2 (write-site plumbing) is in place.

---

## What is NOT deferred (recap)

| Layer | Status |
|---|---|
| Postgres schema (Account/Member/Program/Session/RewardEvent/VoiceEnrolment/HandwritingSample/Device/Invite/OtpChallenge) | ✅ migrated, seeded |
| Admin dashboard (Accounts list, account detail, members, sessions, devices) | ✅ shipped |
| OTP auth (`/api/v1/auth/otp/{start,verify}`) — dev provider | ✅ shipped, tested |
| Password auth (`/api/v1/auth/password/{login,set}`) | ✅ shipped, tested |
| Token refresh (`/api/v1/auth/refresh`) | ✅ shipped |
| Sync endpoints (`/api/v1/me`, `/members`, `/programs`, `/sessions`, `/reward-events`, `/devices`) | ✅ shipped, tested |
| Flutter `AuthService` + secure JWT storage + Bearer/refresh interceptor | ✅ shipped |
| Flutter `SyncOutbox` + `SyncEngine` (drains on sign-in / foreground / connectivity) | ✅ shipped |

## Suggested order for the next pass

1. **Login UI (#3)** — until this exists, nothing else is testable end-to-end.
2. **Plumbing writes through the outbox (#2)** — for one repository at a time, starting with the smallest (Profile/Member) and ending with sessions.
3. **Two-device reconciliation in `pull()` (#6)** — a half-day add-on once writes flow.
4. **FCM (#4)** + **Storage (#5)** — independent of each other and of the above. Pick based on which user-visible feature you want next.
5. **Deep rename (#1)** — last, when nothing else is in flight. Pure cleanup.
