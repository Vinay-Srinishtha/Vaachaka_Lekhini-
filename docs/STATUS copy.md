# Vachika Lekhini — Project Status

_Last updated: 2026-05-11_

Offline Flutter app for counting mantra chants (nama-japa). Counts increment only when **(a)** the utterance exactly matches the selected mantra and **(b)** the speaker matches the enrolled voice. Targets Android + iOS, must work fully offline and with the screen off.

---

## Architecture (current)

```
lib/
├── main.dart                              # ProviderScope + MaterialApp
├── app/
│   ├── app.dart                           # Root widget
│   └── providers.dart                     # Riverpod providers (Vosk, audio, model loader)
├── core/
│   ├── asr/
│   │   ├── vosk_model_loader.dart         # Unzips bundled Hindi model to app dir
│   │   └── vosk_recognizer.dart           # DRY wrapper: setGrammar / acceptChunk / finalize
│   ├── audio/
│   │   └── audio_capture.dart             # 16 kHz PCM stream via `record`
│   └── mantras/
│       ├── mantra.dart                    # Mantra model
│       └── mantra_catalog.dart            # Seed list of 3 mantras
└── features/
    └── chanting/
        └── prototype_screen.dart          # Pick mantra → listen → show ASR output

assets/models/
└── vosk-model-small-hi-0.22.zip           # ~44 MB, bundled
```

**Key dependencies** (pubspec.yaml):
- `vosk_flutter_2 ^1.0.5` — Hindi ASR
- `record ^6.2.0` — mic capture
- `permission_handler ^11.4.0` — pinned by vosk_flutter_2 transitive constraint
- `archive ^3.6.1` — same pinning constraint
- `flutter_riverpod ^3.3.1` — state
- `path_provider ^2.1.5`

---

## ✅ Done

### ASR foundation
- Hindi Vosk small model (`vosk-model-small-hi-0.22`) bundled as asset and unpacked on first launch.
- `VoskRecognizer` DRY wrapper exposes `setGrammar(phrases)`, `acceptChunk(pcm16)`, `finalize()`. Returns `RecognitionResult` with full text, per-word confidences, and `isFinal` flag.
- **Per-session grammar** = `[selected mantra, "[unk]"]` — implements the binary match/no-match design decided 2026-05-08.
- Audio capture streams 16 kHz mono PCM through `record`.

### Mantra catalog (seed)
- `जय श्री राम` (Jai Sri Rama)
- `ॐ नमः शिवाय` (Om Namah Shivaya)
- `श्री राम` (Sri Rama)

### Prototype screen
- Pick a mantra → Start → live partial text + final text + per-word confidence list → Stop.
- Useful for eyeballing Vosk accuracy; **not** the production UI.

### Dependency hygiene
- Latest pub.dev versions used everywhere they don't conflict with `vosk_flutter_2`'s transitive pins.

---

## ⏳ Pending

Roughly ordered by build sequence.

### 1. Match logic + counter (no speaker verification yet)
- Decide "utterance == selected mantra" from `RecognitionResult` (exact-text match + min word-confidence threshold).
- Increment a counter on each match; debounce against repeated final results.
- Display live count on screen.
- **Why first**: smallest useful increment — a working single-speaker counter to dogfood while speaker verification is layered in.

### 2. Speaker verification (TFLite ECAPA-TDNN)
- Bundle the ECAPA-TDNN TFLite model (~17 MB) as an asset.
- **Enrolment flow**: new screen — user chants the selected mantra 5–10 times; app extracts embeddings, stores the mean as the enrolled voiceprint per mantra/user.
- **Per-utterance verification**: on each Vosk final match, extract embedding from that audio segment, cosine-similarity against enrolled embedding, threshold to accept/reject.
- **Decision (2026-05-08)**: Picovoice Eagle rejected to stay free/offline-only with no licence keys.

### 3. Persistence
- Per-mantra running count.
- Optional session history (start time, duration, count).
- Local-only storage (Hive / sqflite / shared_preferences — TBD).

### 4. Background / screen-off support
- **Android**: integrate `flutter_foreground_task`; foreground service with persistent notification; verify mic continues when screen is off.
- **iOS**: enable `audio` background mode in Info.plist; **verify App Store acceptability** for a mic-always-on chant counter (this is the riskiest unknown for iOS).

### 5. Platform setup
- **Android manifest**: `RECORD_AUDIO`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MICROPHONE` permissions; runtime permission request flow.
- **iOS Info.plist**: `NSMicrophoneUsageDescription`, background modes, capabilities.

### 6. UI polish
- Replace prototype screen with a real home screen (mantra picker → enrolment status → big count → start/stop).
- Mantra add/remove flow (user-supplied custom mantras).
- Accessibility (large counter, high contrast).

### 7. Tests
- Only the default `widget_test.dart` placeholder exists.
- Unit tests for match logic, speaker-verification scorer, persistence.

---

## Known constraints / risks

| Area | Constraint |
|---|---|
| `vosk_flutter_2` 1.0.5 | Transitively pins `permission_handler ^11` and `archive ^3` — blocks upgrades. Revisit when a new release ships. |
| iOS background mic | Apple background-audio mode is for playback; chant-counter use may face App Store review pushback. Validate early. |
| Vosk grammar | Single-mantra grammar gives binary match/no-match, but very short mantras (e.g. just "राम") may still false-match — confidence thresholds need tuning. |
| Speaker verification | ECAPA-TDNN cosine threshold is dataset-dependent; will need on-device calibration during enrolment. |

---

## Next step (recommended)

Start with **(1) match logic + counter** on top of the existing prototype. Gives a working single-speaker counter end-to-end, then layer **(2) speaker verification** on top.
