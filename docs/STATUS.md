# Vaachaka Lekhini — Project Status

_Last updated: 2026-05-12._
_Companion docs: `DESIGN.md` (design audit) · `MOCKUPS.html` (visual reference) · `ROADMAP.md` (phase plan)._

**Snapshot:** v1 client build is feature-complete. Every screen in `MOCKUPS.html` is implemented and wired end-to-end against local storage with a dummy auth backend. Phases 0 through 8 of the roadmap have shipped. What remains is real-backend integration (Phase 9), a handful of polish items, and content for the placeholder support pages.

---

## What ships today

```
8 phases shipped · 27 unique screens implemented · 5 bottom-nav tabs
~6,000 lines of Dart  · Drift (SQLite) + Hive (K/V) · 0 analyzer issues · APK + tests green
Portrait-locked Android + iOS · multi-script (Lexend + Tiro Devanagari/Telugu/Kannada)
Repository pattern from day 0 — backend swap is one file (lib/app/providers.dart)
```

### Phases that shipped

| Phase | Theme | Result |
|---|---|---|
| 0 | Foundation — design system, navigation shell, storage skeleton | App boots into 5-tab shell with theme + fonts |
| 1 | Onboarding + dummy auth | Welcome → Profile pick → Create Account (OTP) → Login |
| 2 | Mantra catalog + enrolment | 9 mantras seeded, voice training, 4 handwriting flows |
| 3 | Programs + targets + calendar | Target writings/days, My Programs dashboard, Daily Progress |
| 4 | Counter loop | Home with live data, animated counter, voice + manual mode |
| 5 | Community | Streak leaderboard, Invite Friends with OS share sheet |
| 6 | Rewards | Drift-backed ledger, store, history, milestone awards |
| 7 | Profile + settings + family | Full settings tree, Add Family, Download Data, Logout, Delete |
| 8 | Polish + portrait lock | Settings hot-wired (theme/font/locale), iOS plist, haptics |

---

## Every screen, mapped to code

The reference is `docs/MOCKUPS.html` (numbered 1.1 → 9.2). For each screen I list the file that implements it and whether the route is reachable end-to-end.

### Flow 1 — Onboarding & Auth

| # | Screen | File | Reachable | Notes |
|---|---|---|---|---|
| 1.1 | Welcome | `features/auth/presentation/welcome_screen.dart` | ✅ `/welcome` | Orange gradient, ॐ logo, Devanagari + Lexend brand |
| 1.2 | Profile Selection | `features/profiles/presentation/profile_select_screen.dart` | ✅ `/profile-select` | 2×2 grid, Add Member tile, max 4 |
| 1.3 | Create Account | `features/auth/presentation/create_account_screen.dart` | ✅ `/create-account` | Real OTP flow (any 6 digits accepted by dummy auth) |
| 1.4 | Login with Another Number | `features/auth/presentation/otp_login_screen.dart` | ✅ `/otp-login` | PinCodeInput + 25s resend timer |

### Flow 2 — Mantra selection

| # | Screen | File | Reachable | Notes |
|---|---|---|---|---|
| 2.1 | Quick Start Practice | `features/mantras/presentation/quick_start_screen.dart` | ✅ `/quick-start` | All 9 mantras listed |
| 2.2 | Mantra Selection | `features/mantras/presentation/mantra_selection_screen.dart` | ✅ `/mantra-selection` | + "Select by need" link |
| 2.3 | Mantra for Your Needs | `features/mantras/presentation/mantra_by_need_screen.dart` | ✅ `/mantra-by-need` | 8 needs → tag-overlap recommender |
| 2.4 | Mantra Details | `features/mantras/presentation/mantra_details_screen.dart` | ✅ `/mantra-details/:id` | Deity hero, pronunciation card, heart toggle |

### Flow 3 — Enrolment (Voice + Handwriting)

| # | Screen | File | Reachable | Notes |
|---|---|---|---|---|
| 3.1 | Voice Training | `features/enrolment/voice/presentation/voice_training_screen.dart` | ✅ `/voice-training/:mantraId` | Pulsing mic + animated waveform + 11-count progress wired to Vosk |
| 3.2 | Submit Handwriting | `features/enrolment/handwriting/presentation/handwriting_submit_screen.dart` | ✅ `/handwriting-submit/:mantraId` | 4 mode picker |
| 3.3 | Write on Screen | `features/enrolment/handwriting/presentation/write_on_screen_screen.dart` | ✅ `/handwriting-write/:mantraId` | `signature` canvas with Devanagari ghost guide |
| 3.4 | Capture Handwriting | `features/enrolment/handwriting/presentation/capture_handwriting_screen.dart` | ✅ `/handwriting-capture/:mantraId` | `camera` plugin live preview |
| 3.5 | Upload Handwriting | `features/enrolment/handwriting/presentation/upload_handwriting_screen.dart` | ✅ `/handwriting-upload/:mantraId` | `image_picker` multi-select |

### Flow 4 — Target setup

| # | Screen | File | Reachable | Notes |
|---|---|---|---|---|
| 4.1 | Set Target — Writings | `features/programs/presentation/set_target_writings_screen.dart` | ✅ `/set-target-writings/:mantraId` | 3 presets + live pacing |
| 4.2 | Set Target — Days | `features/programs/presentation/set_target_days_screen.dart` | ✅ `/set-target-days/:mantraId/:writings` | 4 presets + custom slider, **creates the Program in Drift** |

### Flow 5 — Daily loop

| # | Screen | File | Reachable | Notes |
|---|---|---|---|---|
| 5.1 | Home | `features/home/presentation/home_screen.dart` | ✅ `/` | Live profile, programs count, reward points, daily reminder card |
| 5.2 | Main Counter | `features/practice/presentation/counter_screen.dart` (+ `counter_ring.dart`) | ✅ `/practice/:programId` | Animated ring, stat strip, manual+voice modes, Finish → toast → home |

### Flow 6 — Programs & Progress

| # | Screen | File | Reachable | Notes |
|---|---|---|---|---|
| 6.1 | My Programs (Dashboard) | `features/programs/presentation/programs_screen.dart` | ✅ `/programs` | KPI tiles, overall ring, program cards with per-program rings |
| 6.2 | Daily Progress | `features/programs/presentation/daily_progress_screen.dart` | ✅ `/daily-progress/:programId` | Month calendar with active-day dots, day detail card |

### Flow 7 — Community

| # | Screen | File | Reachable | Notes |
|---|---|---|---|---|
| 7.1 | Streak Leaderboard | `features/community/presentation/community_screen.dart` | ✅ `/community` | 5 mocked friends + user, Streak/Total Chants sort |
| 7.2 | Invite Friends | `features/community/presentation/invite_friends_screen.dart` | ✅ `/invite-friends` | OS share sheet for all 3 channels |
| —   | Share on Social Media | _intentionally not built_ | n/a | Figma marked _"Need to design this screen"_ — current invite flow uses OS share sheet |

### Flow 8 — Rewards & Store

| # | Screen | File | Reachable | Notes |
|---|---|---|---|---|
| 8.1 | Reward Store | `features/rewards/presentation/store_screen.dart` | ✅ `/store` | 6 seeded items, filter chips, redeem with real Drift-backed deduction |
| 8.2 | Reward Points & History | `features/rewards/presentation/reward_history_screen.dart` | ✅ `/reward-history` | All/Earned/Spent filter, live points stream |

### Flow 9 — Profile, Settings, Family

| # | Screen | File | Reachable | Notes |
|---|---|---|---|---|
| 9.1 | Profile | `features/settings/presentation/profile_screen.dart` | ✅ `/profile` (tap avatar) | All settings sections; Logout + Delete Account work end-to-end |
| 9.2 | Add Family Members | `features/profiles/presentation/add_family_screen.dart` | ✅ `/add-family` | Shows existing members + form, respects max 4 |
| —   | About App / Help / Privacy / Report / Feedback | `features/settings/presentation/info_screen.dart` | ✅ `/info/:topic` | One reusable screen, friendly placeholder copy until content is supplied |

**Net:** every screen in the design is reachable. The only Figma frame not built is "Share on Social Media", which the design itself flagged as TBD — and the OS share sheet covers it functionally.

---

## What's actually remaining

Sorted by what would block dogfood vs. what's nice-to-have.

### Tier A — Must-have before real users (small, ~1 week)

1. **Pronunciation guide audio** — Mantra Details has the play button but no audio playback wired. Add a per-mantra audio asset and an `AudioPlayer` (use `just_audio`). 9 short clips needed.
2. **Real daily reminders** — `flutter_local_notifications` is in pubspec but not scheduled. Wire `settings.reminderTime` to a daily recurring local notification when it changes.
3. **Edit Profile screen** — Figma references it; right now the "Edit" link in Profile is a no-op. Quick form screen that updates `Profile` + `Session.username`.
4. **Empty/error polish** — Daily Progress when selected day has no data should show a friendlier card ("No sessions on this day yet — go practise"). Mic-permission-denied on Voice Training currently shows raw exception text; needs a friendly retry CTA.
5. **About / Help / Privacy copy** — `InfoScreen` exists with placeholder text. Drop final copy in, ideally with a markdown renderer (`flutter_markdown`) so they're editable without rebuilding.

These are content + connecting-existing-pieces. No new architecture. Doable in a few days.

### Tier B — v1 feature parity gaps (well-scoped, 2–4 weeks)

6. **Speaker verification (TFLite ECAPA-TDNN)** — currently the voice training stores only a "trained" marker. The audio is heard by Vosk but the speaker isn't verified. To finish: bundle the ECAPA TFLite model (~17 MB), wire `tflite_flutter`, capture a mean embedding per enrolment, compute cosine similarity per Vosk match, reject below threshold. **Where it slots in:** `VoiceEnrolmentService` already streams the audio chunks — add an embedding step inline; `PracticeController` already calls `_bump` only on matched events — add a similarity guard.
7. **Background mic on Android** — `flutter_foreground_task` was decided on but not integrated. Without it, mic stops when the screen sleeps. Wire it into the counter session lifecycle (start FG service on START, stop on Finish).
8. **iOS background mic acceptability** — Info.plist allows `audio` background mode but Apple may push back during review. **This is the riskiest unknown** in the whole project. Worth testing with a TestFlight submission before investing more in iOS-specific work.
9. **Stub buttons that do nothing** — "Send Encouragement", "View Group Stats", "Dedicate this program", "Edit Program Goal", "Share Program" all render but are no-op. Either implement (mostly tiny screens) or hide them with a "coming soon" toast.
10. **Pronunciation Guide play & Re-train Voice** — both reachable but the audio piece is missing for the former; Re-train works but only deep-links to the most recent mantra, not the one the user expects.

Doable, well-scoped. Each can be picked up independently.

### Tier C — Worth doing for v1.1 (substantial)

11. **ARB-based localization** — locale is wired (you can switch to हिन्दी / తెలుగు / ಕನ್ನಡ via Profile → Display → Language) but the UI strings stay English because there are no ARB files. Adding them is mechanical but covers every string — probably 1–2 weeks for full coverage across 4 languages with translation review.
12. **Tablet-native layouts** — the app currently shows a centred phone-sized canvas on tablets via `CenteredPhoneCanvas`. Acceptable for v1; a tablet pass would build two-pane "My Programs + Daily Progress" and similar designs.
13. **Dark theme audit** — Light theme is the primary. The toggle works (Profile → Display → Theme → Dark) but cards/contrast pairings haven't been QA'd against AA in dark.
14. **Custom mantras** — catalog is read-only (`MantraRepositoryLocal`). Users can't add their own mantra. Needs a "Create Mantra" flow + an `editableMantras` table.
15. **Real Vosk threshold tuning** — short mantras like "राम" can false-match. Add a min-word-confidence threshold + dedup against repeated finals from the same utterance.

### Tier D — Phase 9, the big one (4–8 weeks depending on backend)

16. **Real backend integration.** Per memory, this was always deferred but committed-to. To start, only one decision needs to be made: **Supabase / Firebase / custom Node**. Once chosen, each repository gets a `*Remote` implementation alongside the existing `*Local`. UI/controllers don't change.
17. **AI handwriting PDF generation** — Submit Handwriting promises "personalised PDF mantra recitations" generated by AI. That's a server-side render (or on-device with `printing`). Open design question — likely server-side.
18. **Real OTP via backend SMS** — replace the dummy 6-digit accept with the chosen backend's SMS verification.
19. **Real friend leaderboard, store inventory, referral codes** — all currently seeded mock data; replace with backend queries.
20. **Sync model + delta queue** — schemas already have `updatedAt` and `syncedAt` columns ready. Add a queue that flushes deltas to the backend when online; conflict-resolve via `updatedAt`.

---

## How each remaining item integrates with the screens

The point of the repository pattern is that almost nothing has to move when we add backend or real services. Map of where each Tier-A/B/C/D item plugs in:

| Item | Screen(s) it touches | Where the code change lives |
|---|---|---|
| Pronunciation audio | Mantra Details (2.4) | New `MantraAudioPlayer` widget; add `pronunciationAsset` to seeded `Mantra` rows |
| Daily reminders | Home reminder card (5.1) + Profile reminder picker (9.1) | New `RemindersService` listens to `settingsProvider` and (re)schedules a `flutter_local_notifications` job on every change |
| Edit Profile | Profile (9.1) | New screen + `ProfileRepository.update` (already exists) |
| Speaker verification | Voice Training (3.1) + Counter (5.2) | Inject embedding step inside `VoiceEnrolmentService` — already where Vosk lives |
| Background mic | Counter (5.2) | `PracticeController.start/finish` calls a new `BackgroundMicService` that boots/stops the FG service |
| Send Encouragement | Leaderboard (7.1) | Tiny `EncouragementRepository` (local-only nudge stream) until backend |
| Group Stats | Leaderboard (7.1) | New `/group-stats` screen aggregating mock + (later) real friend data |
| Dedicate / Edit Goal / Share Program | Daily Progress (6.2) | Dedicate = TextField + saved string per program; Edit Goal = reuses target setup pre-filled; Share = uses existing `share_plus` |
| ARB localization | Every screen | No screen code changes — translations sit in `lib/l10n/` and the `Text(...)` calls swap to `AppLocalizations.of(context).homeWelcome` |
| Dark theme | Every screen | Mostly already works; per-card-variant tweaks in `core/theme/app_theme.dart` |
| Custom mantras | Mantra Selection (2.2) + Mantra Details (2.4) | New `EditableMantraRepository` over a Drift table; "Add Custom" tile in the list |
| Backend (Phase 9) | None | Only `lib/app/providers.dart` changes — every `*RepositoryLocal()` becomes `*RepositoryRemote(httpClient)` |

This is the dividend on the architecture discipline up front — every remaining item lands in code that already exists with no UI rewrites.

---

## Is it doable? My honest read

**Yes.** The hard architectural decisions were made and built around (repository pattern, Drift schemas with sync columns, multi-script typography, settings wired through MaterialApp). The remaining work splits cleanly into three buckets:

1. **A few days of polish** to make v1 dogfood-ready (Tier A) — content, missing audio playback, a real reminder scheduler. Low risk.
2. **2–4 weeks of focused engineering** for speaker verification + background mic + the no-op buttons (Tier B). Each task is self-contained, no rewrites required. The single biggest unknown is **iOS App Store acceptability of background mic for a chant counter** — I'd validate this with a TestFlight submission before sinking effort into iOS-specific work.
3. **Phase 9 (backend)** is the only sizeable unknown. Two-pronged decision: **which backend** (Supabase = fastest path, Firebase = familiar but lock-in, custom Node = most control), and **what to sync vs. keep local** (the design audit recommends voice/handwriting/counter local; everything else cloud). Either way, the code change surface is constrained to `*Remote` repository implementations and `lib/app/providers.dart`. Estimate: 2–4 weeks with Supabase, longer for custom.

**Two real risks worth naming, not to hide them:**
- **iOS background mic** as above. Likely needs at least one App Store rejection cycle to negotiate framing.
- **AI handwriting PDF generation** — the design promised it but the technical approach is undefined. This is a backend concern (Phase 9). Worth a separate design conversation before implementation: server-render with templated PDF + handwriting samples? On-device with `printing` package? Hybrid?

Everything else is execution, not invention.

---

## Quick reference — repos and storage

| Domain | Abstract | Local impl (today) | Remote impl (Phase 9) |
|---|---|---|---|
| Auth (Session) | `AuthRepository` | `AuthRepositoryLocal` (Hive) | `AuthRepositoryRemote` |
| Profiles | `ProfileRepository` | `ProfileRepositoryLocal` (Hive) | `ProfileRepositoryRemote` |
| Mantras | `MantraRepository` | `MantraRepositoryLocal` (seeded const) | `MantraRepositoryRemote` (admin-managed catalog) |
| Voice enrolment | `VoiceEnrolmentRepository` | `VoiceEnrolmentRepositoryLocal` (Hive cache) | _stays local_ |
| Handwriting | `HandwritingRepository` | `HandwritingRepositoryLocal` (files + Hive) | _local + AI PDF upload_ |
| Programs / Sessions | `ProgramRepository` | `ProgramRepositoryDrift` (SQLite) | `ProgramRepositoryRemote` (with sync queue) |
| Rewards | `RewardRepository` | `RewardRepositoryDrift` (SQLite) | `RewardRepositoryRemote` |
| Leaderboard | `LeaderboardRepository` | `LeaderboardRepositoryLocal` (seeded mock) | `LeaderboardRepositoryRemote` |
| Settings | `SettingsRepository` | `SettingsRepositoryLocal` (Hive) | _stays local_ |
| Invite | `InviteService` | `InviteService` (link + share sheet) | extended with backend-issued codes |

`AppDatabase` (Drift): `Programs`, `Sessions`, `RewardEvents` — all with `updatedAt` + `syncedAt` columns ready for delta sync.

`HiveBoxes`: `session`, `profiles`, `settings`, `cache`.
