# KVL App — Figma Design Audit

_Source: Figma file `KVL-App_14-04-26` — 9 frames reviewed 2026-05-11._
_Companion to `STATUS.md` (engineering status). This doc captures what the design says the product **is**, regardless of current build state._

App name in design: **Koti Vachika Lekhini (KVL)** — _"Your Personal Spiritual Practice Companion · Write God's Name with AI | Chant with Purpose | Track with Pride"_

---

## 1. Scope shift vs. current memory

Memory currently describes the project as an "offline Flutter mantra counter with Hindi Vosk + speaker verification, Android + iOS, screen-off." The Figma reveals a substantially larger product:

| Area | Memory says | Figma shows |
|---|---|---|
| Auth | (none — offline) | Mobile + OTP signup, login by another number, referral codes |
| Profiles | (single user) | Family multi-profile (up to 4 members under one mobile) |
| Modality | Voice only | **Voice chant + Handwriting** (write-on-screen, camera capture, gallery upload, default font) |
| Goals | (just count) | Programs with target writings (e.g. 1 crore) over target days, plus per-day pacing |
| Languages | Hindi | English + Hindi + Telugu visible; language picker on signup; UI quote shown in Telugu |
| Online vs offline | Fully offline | Cloud-backed: rewards, leaderboard, friend invites, social share, "Download Your Data" |
| Mantras | 3 seeded | At least 9 in mockups (Sri Rama, Om Namah Shivaya, Gayatri, Maha Mrityunjaya, Hanuman Chalisa, Shankara, Jai Sri Krishna, Narayana, Om Namo Bhagavate Vasudevaya) + "mantra by need" recommender |
| Gamification | (none) | Reward points, store with redemption, streak leaderboard with friends |
| Counter | (just increment) | Streak, today's count, ring progress vs. lifetime target, session start/pause/finish |

**Voice counting is one feature, not the product.** This must be reflected in scope, planning, and the memory file.

---

## 2. Information architecture

**Bottom nav (5 tabs):** Home · My Programs · Practice · Community · Store

**Top-level flows:**
1. Onboarding → account → profile select → mantra select → voice train → target → practice
2. Daily loop → home → quick start OR pick program → counter session → finish
3. Growth loop → community (leaderboard, invites) → rewards → store
4. Settings loop → profile → preferences / family / data

---

## 3. User flows

27 unique screens compose into 8 distinct flows. The bottom tab bar (Home · My Programs · Practice · Community · Store), top-right avatar (→ Profile), and top-right gear icon (→ settings) are present across most main screens — only the non-obvious transitions are diagrammed below.

### 3.1 First-time onboarding (new user)

```
Welcome
  └─► Profile selection ── "Create a new account" ──► Create Account (OTP)
                                                       │
                                                       ▼
                                              Quick Start Practice
                                                       │
                                                       ▼
                                                Mantra Selection
                                       (or "Mantra by Need" link ──► Mantra by Need)
                                                       │
                                                       ▼
                                                Mantra Details
                                                       │
                                                       ▼
                                                Voice Training
                                          (or "Skip & Use Manual Counter")
                                                       │
                                                       ▼
                                          Submit Your Handwriting (mode picker)
                                ┌───────────────┬──────┴───────┬──────────────────┐
                                ▼               ▼              ▼                  ▼
                         Write on Screen   Capture (cam)   Upload (gallery)   Use Default Font
                                └───────────────┴──────┬───────┴──────────────────┘
                                                       ▼
                                          Set Practice Target — Writings
                                                       ▼
                                          Set Practice Target — Days
                                                       ▼
                                                     Home
                                                       │
                                                       ▼
                                                Main Counter
```

### 3.2 Returning user — daily session

```
Welcome (auto-pass if logged in)
   └─► Profile selection ──► Home
                              │
              ┌───────────────┼────────────────────┐
              ▼               ▼                    ▼
   "Quick Start Practice"   "Select from your   "Create a New Program"
              │              Programs"             (→ Flow 3.3)
              │               │
              ▼               ▼
       Quick Start Practice  My Programs ──► (pick program)
                              │
                              ▼
                       Main Counter ──► (Finish Session) ──► Home
```

### 3.3 Add another program (existing user)

```
Home  ──►  "Create a New Program"
            │
            ▼
       Mantra Selection ◄──► Mantra by Need
            │
            ▼
       Mantra Details
            │
            ▼
       Voice Training  (or Skip — re-enrol uses prior voice if available)
            │
            ▼
       Set Target Writings ──► Set Target Days ──► Main Counter
```

### 3.4 "Mantra by Need" sub-flow

```
Mantra Selection screen
   └─► tap "Select mantra based on your need"
          │
          ▼
      Mantra by Need (dropdown of problems → recommended mantra card)
          │
          ▼
      "Start This Practice" ──► Set Target Writings ──► Set Target Days ──► Main Counter
```

### 3.5 Program tracking

```
Bottom nav → My Programs
   │
   ├─► KPI dashboard (Total Chants / Complete / Daily Avg / Longest Streak)
   ├─► "+ Create New Program" ──► Flow 3.3
   └─► Program card ──► Daily Progress (calendar view)
                          │
                          ├─► Dedicate this program
                          ├─► Edit Program Goal ──► (back to target setup)
                          └─► Share Program ──► Share on Social Media
```

### 3.6 Community

```
Bottom nav → Community
   └─► Streak Leaderboard ──── tabs: Streak Challenge | Total Chants
          │
          ├─► "Invite Friends" ──► Invite Friends screen ──► Share via WhatsApp/FB/Insta
          ├─► "Send Encouragement"
          └─► "View Group Stats"
```

### 3.7 Rewards

```
Bottom nav → Store
   └─► Reward Store (search / filter / product grid)
          │
          ├─► "See History" ──► Reward Points & History (All / Earned / Spent)
          └─► Redeem ──► (transaction added to history)
```

### 3.8 Profile & settings

```
Home → tap avatar (top right)
   └─► Profile
          │
          ├─► Edit Profile
          ├─► "Family Members" ──► Add / Manage Family Members
          ├─► "Invite Friends" ──► Flow 3.6 invite screen
          ├─► Link Facebook / WhatsApp / Instagram (toggles)
          ├─► Practice Settings (Reminder Time, Notification Sound)
          ├─► Voice Settings ──► "Re-train Voice" ──► back to Voice Training
          ├─► Display Settings (Language, Theme, Font Size)
          ├─► Support & Privacy ──► Help & FAQs · Report Issue · Share Feedback · Privacy Policy · Download Your Data · About App
          ├─► Logout
          └─► Delete Account
```

### 3.9 All unique screens (27)

- **Auth & profile**: Welcome · Profile selection · Create Account · Login with Another Number · Add Family Members
- **Mantra selection**: Quick Start Practice · Mantra Selection · Mantra by Need · Mantra Details
- **Onboarding (enrolment)**: Voice Training · Submit Your Handwriting (mode picker) · Write on Screen · Capture Handwriting · Upload Handwriting · Set Practice Target (Writings) · Set Practice Target (Days)
- **Daily use**: Home · Main Counter / Practice
- **Programs**: My Programs (Dashboard) · Daily Progress (calendar)
- **Community**: Streak Leaderboard · Invite Friends · Share on Social Media
- **Rewards**: Reward Store · Reward Points & History
- **Settings**: Profile · About App
- **Reusable component (not a standalone screen)**: "Container" — the active/completed program card

### 3.10 Gaps — referenced but not yet designed

- **Share on Social Media** — marked _"Need to design this screen"_ in Figma.
- **About App** — marked _"Content need to write"_.
- **Edit Profile** — referenced from Profile, no frame.
- **Session Stats** / **View Summary** — referenced from Main Counter and completed program cards, no frames.
- **Help & FAQs / Report Issue / Privacy Policy** — referenced from Profile, no frames.

---

## 4. Screens (by frame)

### 4.1 Onboarding & Auth
- **Welcome** — Brand mark, tagline, "Continue to App", "Know our App" link.
- **Profile selection** — _"Who is Practicing?"_ avatars (Me / Son / Daughter / Add Member). Links: Manage Profiles, Login with another number, Create a new account.
- **Create Account** — Username, Mobile (+91), Referral Code (optional), Select Language, **Send OTP**, Register. "Already have an account? Login", "Need help?".
- **Login with Another Number** — Mobile entry → 6-digit OTP boxes → Resend in 25s → Login.

### 4.2 Mantra selection
- **Quick Start Practice** — Scrollable list of mantras with thumbnail + 1-line description + radio. CTA: **Quick Start**.
- **Mantra Selection** — Same pattern, but bottom shows _"Select mantra based on your need"_ link + **Confirm Selection** CTA.
- **Mantra Details** — Hero image of deity, large mantra name, multi-paragraph description, **Pronunciation Guide** audio card, **Start Practice with [Mantra]** CTA, heart icon (favorites).
- **Mantra for Your Needs** — Dropdown: _"Select your need or problem"_ → recommended mantra card (e.g. _Om Namo Bhagavate Vasudevaya_ for wealth/prosperity) with suggested cadence ("108 times daily / for 40 days") + Learn More + **Start This Practice**.

### 4.3 Voice training
- **Train Your Voice** — Mic visual, prompt _"Say 'Sri Rama' Eleven times clearly · Speak naturally at your normal pace and volume"_, live waveform + "Recording..." indicator. CTAs: **Start Recording** / **Skip & Use Manual Counter** (manual counter is a first-class fallback).

### 4.4 Handwriting (the second modality)
- **Submit Your Handwriting** — 4 mode cards: **Write on Screen** · **Capture from Camera** · **Upload from Gallery** · **Use Default Font**. _"Upload your handwriting for personalized PDF mantra recitations. Our AI will randomly select samples to feature."_ → **Confirm selection**.
- **Write Your Mantra Sample** — Full-screen canvas, _"Begin writing here…"_, toolbar (pen, color, eraser, undo, redo). CTA: **Save Handwriting**. Header: Clear.
- **Capture Your Handwriting** — Camera viewfinder with corner frame guide, gallery picker, shutter button, flip camera.
- **Upload Your Handwriting** — Image grid (3 across), multi-select with check, _Deselect All_. CTA: **Upload Selected**.

### 4.5 Target setup
- **Set Your Practice Target (Writings)** — Preset cards: **1,00,00,000 writings** (Most Popular), **1,000,000 writings**, **Set a custom target** (Total Writings + Completion Time inputs, with live "≈ 1.5 hours/day" computation). **Confirm Target** / Cancel.
- **Set Your Practice Target (Days)** — Preset cards with tags: 100 Days _Fastest_, 180 Days _Balanced_, 365 Days _Gentle_, 500 Days _Sustainable_ (each shows chants/day + minutes/day). Plus **Set a Custom Duration** (number + slider with live "≈ 45 minutes/day"). CTA: **Confirm & Begin**.

### 4.6 Home & Practice
- **Home** — "Welcome, Rakesh!", "You're doing great! 2 Programs Active", Total Reward Points 1,250, **Daily Practice Reminder** card (current goal), hero image with Telugu quote, **Quick Start Practice** / **Select from your Programs** / **Create a New Program**.
- **Main Counter / Practice** — Header: date + "Day 15". Stat strip (scrollable): **Streak 15 Days**, **Today's Count 5,487**, Daily target …. Big ring counter `27,934 / 10,000,000`. **START** / **PAUSE** / **Finish Session** (teal). _Today's Progress_ bar `5,487 / 10,000`. Footer chips: **Change Mantra** · **Session Stats**.

### 4.7 Programs & Progress
- **My Programs (Dashboard)** — Inspirational quote card, KPI grid: Total Chants 3.1M, Complete 31%, Daily Average 28,500, Longest Streak 67 days. **Overall Progress** ring (31%). **+ Create New Program**. Program list cards (e.g. Sri Rama 50% 500k/1M, Gayatri 100% 108/108 _Completed_, Maha Mrityunjaya 50% 500k/1M).
- **Program card variants (Container)** — Active card with progress bar + **View Progress**; Completed card with green check + **View Summary**.
- **Daily Progress** — Calendar (month nav), dot per practiced day, selected day highlighted. Day detail card: Daily Target / Actual Achieved (green) / Handwriting Used (Yes/No). Buttons: **Dedicate this program** (primary), **Edit Program Goal** / **Share Program**.

### 4.8 Community
- **Streak Leaderboard** — "5 Friends Joined", invite-up-to-5 banner, tabs: **Streak Challenge** | **Total Chants**. Podium top-3 with day counts. List with current user row highlighted ("You · 85 Days · #4"). CTAs: **Send Encouragement**, **View Group Stats**.
- **Invite Friends** — Branded illustration, invite link `https://kvl.app/invite/JANE123` with copy, **Share via WhatsApp / Facebook / Instagram** buttons.
- **Share on Social Media** — Targets: WhatsApp (Status), Facebook, Instagram. CTA: **Share**. _(Frame marked "Need to design this screen")._

### 4.9 Rewards & Store
- **Reward Store** — Header shows current points + **See History**. Promo banner (Special Offer · Guided Meditation Series). Search. Filter chips (All / Frames / Books / Tools / Meditation). Product grid (Digital Mala Beads 500 pts, Spiritual E-books 800 pts, Guided Meditations 1000 pts, …) with **Redeem** buttons.
- **Reward Points & History** — Total points hero, **Visit Reward Store**. Tabs (All / Earned / Spent). Transaction list: _Daily Mantra Completion +50_, _Milestone: 10 Lakh Chants +500_, _Store Redemption: E-book –200_, _Friend Referral +…_, _Donation to Charity –50_.

### 4.10 Profile & Settings
- **Profile** — Avatar + name + email, KPI tiles (Total Chants 3.1M / Current Streak 15 days / Milestones 3/5). **Reward Points** card with **Visit Store**.
  - **Family & Community**: Family Members, Invite Friends.
  - **Link Social**: Facebook, WhatsApp, Instagram (toggles).
  - **Practice Settings**: Reminder Time (06:00 AM), Notification Sound (Bell).
  - **Voice Settings**: Re-train Voice, Microphone Sensitivity.
  - **Display Settings**: Language (English), Theme (System), Font Size (Default).
  - **Support & Privacy**: Help & FAQs, Report Issue, Share Feedback, Privacy Policy, **Download Your Data**.
  - **Logout** (outlined), **Delete Account** (destructive). Version footer.
- **Add Family Members** — _"Add up to 4 family members under your registered mobile number. Each member will have their own practice counter."_ Form: Registered Mobile (read-only), Family Member Name, Relationship dropdown.
- **About App** — _Placeholder (Content need to write)._

---

## 5. Visual / interaction language

- **Palette**: warm cream/ivory background (`#FBF3E2`-ish), saffron/orange primary CTAs, deep teal for "Finish Session" success state, soft pastel surfaces for cards.
- **Typography**: large serif for mantra/feature names; sans-serif for body & UI.
- **Cards** with generous radius (~16–20 px), subtle shadow, full-width primary CTAs at the bottom.
- **Bottom nav** consistent across main flows; selected item shown with orange icon + label.
- **CTA hierarchy**: filled saffron (primary) → outlined saffron (secondary) → text link.
- **Number formatting**: Indian comma grouping (`1,00,00,000`, `5,487`, `3.1M`).
- **Locale-aware content**: mantras shown in Devanagari + Roman transliteration; sample quote in Telugu — design assumes Hindi + Telugu + English at minimum.

---

## 6. Implied data model (rough)

- **User**: id, mobile, username, email?, referral_code, language, created_at.
- **Profile** (family member, child of User): id, name, relationship, avatar; up to 4 per User.
- **Mantra**: id, name (Devanagari, Roman, Telugu?), description, deity_image, pronunciation_audio, recommended_count, recommended_days, need_tags.
- **Program** (per Profile): id, profile_id, mantra_id, target_writings, target_days, started_at, daily_target, status (active/completed), totals (chants, handwriting_used).
- **Session**: id, program_id, started_at, ended_at, count, modality (voice/manual/handwriting), used_handwriting_bool.
- **HandwritingAsset**: id, profile_id, source (screen/camera/gallery/default_font), image_blob/ref, created_at.
- **VoiceModel** (speaker print): per Profile · per Mantra embedding.
- **RewardEvent**: id, profile_id, type (earn/spend), amount, source, created_at.
- **StoreItem**: id, title, category, price_points, image, stock.
- **Friend / Invite**: invite code, joined_friends list, leaderboard entries.

---

## 7. Online vs. offline split

The current memory says fully offline. The Figma requires cloud for: OTP auth, family profiles (cross-device), referral codes, rewards points + store redemption, social share/invite, friend leaderboard, "Download Your Data", and likely AI-generated PDF from handwriting.

**Suggested split:**
- **Local-first (offline-capable):** voice ASR + speaker verification, session counting, handwriting capture, on-device program progress, daily reminders. Queues sync deltas when online.
- **Cloud-required:** account/OTP, family profiles, rewards ledger, friends/leaderboard, store, social share, AI handwriting PDF generation, data export.

This needs an explicit decision before backend choice (Supabase / Firebase / custom).

---

## 8. Open questions surfaced by the design

1. **"AI will randomly select samples to feature"** in handwriting submit — is this generating a printable PDF of `N` mantra repetitions stylised in the user's handwriting? Server-side render? Which model?
2. **Counter ↔ writings**: does the lifetime target `10,000,000` count both spoken chants and written instances together, or are they separate program types?
3. **Speaker verification scope** — the design says "Skip & Use Manual Counter" is acceptable, so voice match is not mandatory. Confirm fallback behavior.
4. **Children's profiles** — voice training for a 10-year-old vs. an adult: same model? Re-enrol per profile?
5. **Multi-language ASR** — Telugu sample present; Vosk small-hi only covers Hindi. Need a model strategy if Telugu / Sanskrit chants are in scope.
6. **Backend choice** — Supabase, Firebase, custom Node, or other? Drives auth/OTP, sync model, file storage for handwriting.
7. **Reward economy** — earn/spend rates, store inventory source (admin tool needed?), abuse prevention.
8. **App Store viability** — iOS background mic + spiritual content rewards may need review-team framing.
9. **Privacy of voice & handwriting** — explicit consent + storage policy; "Download Your Data" implies GDPR-style export.
10. **Welcome screen** uses both _"Koti Vachika Lekhini"_ and the working title _"Vachika Lekhini"_ — confirm final brand.

---

## 9. Implication for engineering plan

The existing `STATUS.md` "next step = match logic + counter on the prototype" is still valid as a thin slice — but the **overall plan needs to expand** beyond the offline voice counter:

1. Decide online vs. offline split (#6 above) — blocks backend, auth, sync.
2. Pick state architecture for multi-profile + multi-program (Riverpod + local store + sync queue).
3. Re-baseline the build plan around the 5 nav tabs (Home / Programs / Practice / Community / Store), not the prototype screen.
4. Define the handwriting pipeline as a separate workstream from voice — it has its own UX, storage, and (likely) server-side AI work.
5. Treat voice ASR + speaker verification as **one** of three counting modalities (voice / handwriting / manual), not the whole product.

A revised roadmap should live in a new `docs/ROADMAP.md` once these decisions are made.
