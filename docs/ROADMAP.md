# Vaachaka Lekhini Build Roadmap

_Plan written: 2026-05-11_ · companion to `STATUS.md` (current state), `DESIGN.md` (design audit), `MOCKUPS.html` (visual target).

This is the phased plan to take Vaachaka Lekhini from the current ASR prototype to all 22 screens shown in `MOCKUPS.html`, with **offline storage + dummy auth** now and **cloud/API integration deferred** to the final phase.

---

## Ground rules (apply to every phase)

1. **DRY** — shared logic factored into reusable widgets / repositories / utilities. Same colors, fonts, spacing tokens used everywhere via a single theme.
2. **Modular** — code organised by feature, not by layer. Each feature has its own `data/`, `domain/`, `presentation/` sub-folders. Features import each other only through public barrel files.
3. **Latest verified libraries** — versions checked on pub.dev 2026-05-11 (see table below). Pinned lower only when transitive constraints force it.
4. **Repository pattern from day one** — every data domain has an abstract `Repository` with a local implementation now and a remote implementation later. UI never imports storage or HTTP directly.
5. **Dummy auth is real** — OTP screens persist a fake session via the same `AuthRepository` interface a real backend will use.
6. **Responsive by default** — every screen built with `LayoutBuilder` + breakpoints so phone and tablet share one widget tree.
7. **Accessibility** — semantic labels, dynamic font scaling, AA contrast on first build, not retrofitted.

## Verified package versions (pub.dev, 2026-05-11)

| Purpose | Package | Version |
|---|---|---|
| State management | `flutter_riverpod` | 3.3.1 |
| Riverpod codegen | `riverpod_annotation` / `riverpod_generator` | 4.0.2 / 4.0.3 |
| Navigation | `go_router` | 17.2.3 |
| Fonts | `google_fonts` | 8.1.0 |
| SQL storage | `drift` / `drift_dev` | 2.33.0 |
| K/V storage | `hive_ce` / `hive_ce_flutter` | 2.19.3 / 2.3.4 |
| Data classes | `freezed` / `freezed_annotation` | 3.2.5 / 3.1.0 |
| JSON | `json_serializable` / `json_annotation` | 6.13.2 / 4.11.0 |
| Theme system | `flex_color_scheme` | 8.4.0 |
| Responsive helper | `flutter_screenutil` | 5.9.3 |
| Handwriting canvas | `signature` | 6.3.0 |
| Camera | `camera` | 0.12.0+1 |
| Gallery picker | `image_picker` | 1.2.2 |
| Notifications | `flutter_local_notifications` | 21.0.0 |
| Sharing | `share_plus` | 13.1.0 |
| Date/locale | `intl` | 0.20.2 |
| IDs | `uuid` | 4.5.3 |
| Equality | `equatable` | 2.0.8 |
| Collections | `collection` | 1.19.1 |
| SVG | `flutter_svg` | 2.3.0 |
| **Voice (kept)** | `vosk_flutter_2` | 1.0.5 |
| Audio capture (kept) | `record` | 6.2.0 |
| **Permissions** | `permission_handler` | **11.4.0** (pinned — vosk transitive) |
| **Archive** | `archive` | **3.6.1** (pinned — vosk transitive) |

> The two pinned lower (permission_handler, archive) are blocked by `vosk_flutter_2 1.0.5`. Revisit when a new vosk_flutter_2 release ships.

---

## Target folder structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart                       # Root MaterialApp, theme, router
│   ├── router.dart                    # go_router config, route guards
│   └── providers.dart                 # Top-level Riverpod providers
├── core/
│   ├── theme/                         # Colors, typography, spacing, shadows
│   ├── widgets/                       # Reusable: KvlButton, KvlCard, MantraThumb, RingCounter, BotNav, ...
│   ├── localization/                  # i18n strings + locale switching
│   ├── responsive/                    # Breakpoints, layout helpers
│   ├── storage/                       # Drift database, Hive boxes, file paths
│   ├── errors/                        # Failure types, error mapper
│   └── utils/                         # Formatters (Indian numbers, dates), validators
├── features/
│   ├── auth/                          # Auth flow (welcome, profile select, OTP)
│   │   ├── data/                      # AuthRepositoryLocalImpl, models
│   │   ├── domain/                    # AuthRepository abstract, entities
│   │   └── presentation/              # Screens + controllers
│   ├── profiles/                      # Family member profiles
│   ├── mantras/                       # Catalog, selection, detail, by-need
│   ├── enrolment/                     # Voice training, handwriting capture
│   ├── programs/                      # Create, list, daily progress, targets
│   ├── practice/                      # Main counter, session lifecycle
│   ├── community/                     # Leaderboard, invite
│   ├── rewards/                       # Store, points, history
│   ├── settings/                      # Profile, preferences, support
│   └── home/                          # Home screen aggregator
└── shared/
    └── (cross-feature reusables that don't belong to core)
```

---

# Phases

Each phase ships a runnable build. No phase is "scaffolding only" — every phase produces user-visible value on top of the previous one.

## Phase 0 — Foundation (design system + shell)

**Outcome:** Empty app that boots, navigates between 5 stub tabs, and looks like Vaachaka Lekhini.

- [ ] `pubspec.yaml` — replace deps with the verified version table above
- [ ] `core/theme/` — color tokens, typography (Lexend + Tiro Devanagari/Telugu/Kannada + Noto fallbacks via `google_fonts`), spacing scale, shadow tokens, light theme (dark theme deferred)
- [ ] `core/widgets/` — first pass: `KvlButton` (primary/secondary/ghost/teal/danger variants), `KvlCard`, `KvlScaffold`, `KvlBottomNav`, `KvlTopBar`, `KvlInput`, `KvlChip`, `MantraThumb`, `IndianNumberFormat`
- [ ] `core/responsive/` — `Breakpoints` (phone < 600, tablet 600–1024, desktop > 1024), `ResponsiveBuilder`, `AdaptiveLayout`
- [ ] `core/storage/` — Drift DB skeleton, Hive setup, schema for users/profiles/mantras/programs/sessions
- [ ] `app/router.dart` — go_router with 5 tab shell route + nested routes per feature
- [ ] Stub each tab page (Home / My Programs / Practice / Community / Store) with placeholder + bottom nav working

**Definition of done:** App boots, tabs switch, theme & fonts render correctly, no real features yet.

---

## Phase 1 — Onboarding & Auth (dummy)

**Outcome:** User can complete the full sign-up + profile-select flow, end-to-end, with state persisted locally.

Screens: **Welcome · Profile Selection · Create Account · OTP Login** (mockups 1.1–1.4)

- [ ] `features/auth/domain/auth_repository.dart` — abstract: `sendOtp`, `verifyOtp`, `currentSession`, `logout`
- [ ] `features/auth/data/auth_repository_local.dart` — accepts any OTP "123456" by default, stores `Session` in Hive
- [ ] `features/profiles/` — `Profile` entity, `ProfileRepository`, list/add/select up to 4 per user
- [ ] Welcome screen (animated gradient, hero text in Devanagari + English)
- [ ] Profile Selection screen (avatar grid, switch active profile)
- [ ] Create Account screen (form, validation, language picker stub)
- [ ] OTP Login screen (6-box OTP input, auto-advance, resend timer)
- [ ] Router guards: unauthenticated → Welcome; no profile selected → Profile Selection; otherwise → Home
- [ ] Persist: session, active profile, last-used language

**Definition of done:** Cold start → Welcome. After dummy OTP → profile pick → Home. Kill app, reopen → lands on Home with same profile.

---

## Phase 2 — Mantra catalog, selection & enrolment

**Outcome:** User can browse mantras, pick one, see details, train their voice, and submit handwriting samples.

Screens: **Quick Start · Mantra Selection · Mantra by Need · Mantra Details · Voice Training · Submit Handwriting · Write on Screen · Capture Handwriting · Upload Handwriting** (mockups 2.1–2.4, 3.1–3.4)

- [ ] `features/mantras/` — seeded catalog (the 9 mantras in mockups) with Devanagari + Roman + Telugu + Kannada names, description, need-tags, deity image asset
- [ ] `features/mantras/by_need.dart` — tag → mantra recommendation rules
- [ ] `features/enrolment/voice/` — keep existing Vosk + audio pipeline; wrap in a re-usable `VoiceEnrolment` widget; show 11-count progress
- [ ] `features/enrolment/handwriting/` — three sub-flows:
  - Write on Screen: `signature` package canvas with ghost-text guide, color picker, eraser, undo/redo
  - Capture: `camera` preview with frame overlay
  - Upload: `image_picker` multi-select grid
- [ ] Per-profile `VoiceModelStore` and `HandwritingAssetStore` in local storage
- [ ] "Skip & Use Manual Counter" wired up as a real path (sets profile's preferred modality)

**Definition of done:** Onboarding flows continuously from auth → mantra pick → voice trained (or skipped) → handwriting saved → ready for target setup.

---

## Phase 3 — Programs (target setup + tracking)

**Outcome:** Programs exist as a first-class concept. User can create programs with writings + days targets and see daily progress.

Screens: **Set Target — Writings · Set Target — Days · My Programs · Daily Progress** (mockups 4.1–4.2, 6.1–6.2)

- [ ] `features/programs/domain/program.dart` — entity: profileId, mantraId, targetWritings, targetDays, startDate, dailyTarget, status, totals
- [ ] `features/programs/data/program_repository.dart` — Drift-backed CRUD, list-by-profile, computed fields
- [ ] `Session` entity (program_id, started_at, ended_at, count, modality)
- [ ] Target setup screens with live "≈ N hours/day" computation
- [ ] My Programs dashboard with KPI tiles + ring + list
- [ ] Daily Progress: month calendar with practice-dot overlay, per-day detail card
- [ ] Streak computation utility (rolling, breaks on missed days)

**Definition of done:** User creates a program, sees it on Programs tab, opens Daily Progress, navigates by month.

---

## Phase 4 — Counter (the daily loop)

**Outcome:** Real counting session — voice/manual/handwriting modes — with session persistence and live UI feedback.

Screens: **Home · Main Counter / Practice** (mockups 5.1–5.2)

- [ ] Home screen aggregator pulling from auth/profiles/programs/rewards repositories
- [ ] Daily reminder card driven by `flutter_local_notifications`
- [ ] Main Counter screen
  - Animated ring (CustomPainter, lerps to target on count change)
  - Stat strip (streak / today / target)
  - START / PAUSE / Finish Session state machine via Riverpod controller
  - Live counter increments from `VoskRecognizer` match events (Phase 2 code)
  - Manual tap-to-count fallback when modality = manual
  - Today's Progress bar
- [ ] `SessionRecorder` writes sessions to Drift on Finish
- [ ] Programs tab auto-refreshes after a session

**Definition of done:** Open a program, hit Start, chant or tap, watch the count rise, hit Finish, see the session in Daily Progress.

---

## Phase 5 — Community (offline mock)

**Outcome:** Community tab shows a believable mocked leaderboard and a working invite-link flow.

Screens: **Streak Leaderboard · Invite Friends · Share on Social Media** (mockups 7.1–7.2)

- [ ] `features/community/data/leaderboard_repository_local.dart` — seeded mock friends with deterministic streaks
- [ ] `InviteService` — generates `kvl.app/invite/<code>` deep link (code from local store)
- [ ] `share_plus` integration for WhatsApp / Facebook / Instagram / generic share sheet
- [ ] Leaderboard screen with tabs (Streak / Total Chants), podium top-3, list with current-user row highlighted

**Definition of done:** Community tab works visually identical to mockup; sharing a link via the share sheet works on a real device.

---

## Phase 6 — Rewards (offline economy)

**Outcome:** Reward points are earned by completing sessions and reaching milestones; user can browse a mock store and view a transaction history.

Screens: **Reward Store · Reward Points & History** (mockups 8.1–8.2)

- [ ] `features/rewards/domain/reward_event.dart` — earn/spend ledger entry
- [ ] `RewardRules` — pure functions: `pointsForDailyTarget()`, `pointsForMilestone(count)`, `pointsForReferral()`
- [ ] `RewardLedger` writes events on session finish, milestone crossing, redemption
- [ ] Mock store inventory in `assets/store_items.json` (Digital Mala Beads, Spiritual E-books, Guided Meditations, etc.)
- [ ] Store screen with filter chips, product grid, Redeem flow (deducts points, writes spend event)
- [ ] History screen with All/Earned/Spent tabs

**Definition of done:** Finish a session → points appear on Home and in history. Redeem an item → points deducted, event logged.

---

## Phase 7 — Profile, family, settings

**Outcome:** Full Profile screen with all settings sections; Add Family Members works.

Screens: **Profile · Add Family Members · About App** (mockups 9.1–9.2)

- [ ] Profile screen composing all settings sections from the mockup
- [ ] Add Family Members screen (writes to `ProfileRepository`)
- [ ] Settings persistence: reminder time, notification sound, language, theme, font size, mic sensitivity, social-link toggles
- [ ] "Re-train Voice" deep-links into Phase 2 enrolment
- [ ] Logout (clears session) + Delete Account (clears all local data)
- [ ] Stubs for Help / FAQ / Privacy / Download Data screens (open WebView or show "coming in v1.1")
- [ ] "Download Your Data" exports a JSON of all local repositories (preview of future GDPR export)

**Definition of done:** Every settings row does something (even if just persists to Hive); family-member counter is fully independent.

---

## Phase 8 — Polish & accessibility pass

**Outcome:** Production-feeling app on phone and tablet.

- [ ] Tablet layouts via `LayoutBuilder` (two-pane Programs+Daily Progress, two-column Reward Store)
- [ ] All animations from `MOCKUPS.html`: mic pulse, ring breathing, waveform, progress bar easing, counter tick (subtle scale + haptic)
- [ ] Haptic feedback on counter increment, milestone crossing, Finish Session
- [ ] Skeleton loaders for any list that hits storage
- [ ] Empty states (no programs, no friends, no rewards yet)
- [ ] Error states (mic permission denied, storage write failure)
- [ ] Localization pass: Hindi + Telugu + Kannada + English (ARB files)
- [ ] Dynamic font size honoured
- [ ] AA color contrast verified on every screen
- [ ] Background mic on Android via `flutter_foreground_task`; iOS background-audio mode + Info.plist
- [ ] Performance: const-correctness pass, `flutter analyze` clean, no janky frames on a low-end Android

**Definition of done:** Built APK + IPA. Internal dogfood-ready.

---

## Phase 9 — API integration (deferred)

**Outcome:** The same app, with a real backend behind every repository.

Not started until backend is chosen. Per memory `project_api_integration_deferred.md`:

- [ ] Choose backend (Supabase / Firebase / custom Node — separate decision doc)
- [ ] Implement `*RepositoryRemoteImpl` for every domain
- [ ] Wire repositories behind a `RepositorySource` Riverpod provider (local-first with remote sync)
- [ ] Sync queue: deltas → server when online; conflict resolution via `updated_at`
- [ ] Real OTP via backend SMS provider
- [ ] Move handwriting PDF generation to a server endpoint (or on-device with `printing` package — TBD)
- [ ] Real friend leaderboard, real store inventory, real referral codes

**Definition of done:** Two devices logged in as the same user see synchronized programs and counts.

---

## Risks / open questions tracked outside the phases

These don't block Phase 0 starting, but need answers before the phases marked.

| Item | Blocks |
|---|---|
| Backend choice (Supabase / Firebase / custom) | Phase 9 |
| Telugu / Kannada ASR strategy (Vosk has no Telugu small model) | Mid-Phase 2 |
| iOS background-mic App Store viability | Phase 8 |
| Handwriting "AI PDF generation" pipeline (server-side render? which model?) | Phase 9 |
| Reward economy rates + abuse prevention | Phase 6 |

---

## Confirmation checklist before I start Phase 0

- [x] User confirmed: build all screens from `MOCKUPS.html`
- [x] User confirmed: offline storage + dummy auth for now
- [x] User confirmed: API integration is deferred but mandatory later (saved to memory)
- [x] User confirmed: DRY, modular, latest verified libraries
- [ ] **User confirms this phase plan** → start Phase 0
