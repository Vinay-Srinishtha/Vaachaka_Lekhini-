import 'dart:async';
import 'dart:typed_data';

import '../../../../core/asr/vosk_model_loader.dart';
import '../../../../core/asr/vosk_recognizer.dart';
import '../../../../core/audio/audio_capture.dart';
import '../../../mantras/domain/mantra.dart';
import '../../../settings/domain/settings_repository.dart';

/// Drives a voice-enrolment / counting session.
///
/// ## Continuous-chanting strategy
///
/// Vosk only emits a final result when it detects silence. Rapid continuous
/// chanting has no silence → no final → no count. We fix this with
/// **timed-window forced finalisation**:
///
/// Every [_windowMs] a [Timer] calls `finalize()` on the recognizer. Vosk's
/// `getFinalResult()` both returns whatever it has accumulated AND resets its
/// internal state for the next window — so we never need to recreate the
/// recognizer (which caused a race condition in a prior version).
///
/// A `_finalizing` boolean serialises the two async paths (stream listener
/// and timer) so they never call into the recognizer concurrently.
///
/// Occurrence counting: the final-result text is scanned for how many times
/// the mantra phrase appears, so two rapid chants that land in the same
/// window are both counted.
class VoiceEnrolmentService {
  VoiceEnrolmentService({
    VoskModelLoader? modelLoader,
    VoskRecognizer? recognizer,
    AudioCapture? audio,
  })  : _modelLoader = modelLoader ?? VoskModelLoader(),
        _recognizer = recognizer,
        _audio = audio ?? AudioCapture();

  final VoskModelLoader _modelLoader;
  VoskRecognizer? _recognizer;
  final AudioCapture _audio;

  StreamSubscription<Uint8List>? _sub;
  Timer? _windowTimer;
  final _events = StreamController<VoiceTrainingEvent>.broadcast();

  int _matches = 0;
  bool _running = false;
  /// True while the timer is flushing — chunk callbacks skip to avoid
  /// calling into the recognizer concurrently.
  bool _finalizing = false;
  /// True once the window timer has been started (deferred until first
  /// real audio arrives so the first chant is never cut mid-word).
  bool _timerStarted = false;
  int _target = 11;
  Mantra? _mantra;

  /// How often (ms) we force a finalisation regardless of silence.
  ///
  /// 1500 ms is the sweet spot across all chanting speeds:
  /// • Slow / with gaps  → Vosk's own silence-detection fires first (this timer
  ///   is just a safety net — it fires on an already-empty buffer, returns "").
  /// • Medium (~1 s/chant) → timer catches it cleanly within one chant duration.
  /// • Fast continuous   → two chants can land in one window; _countOccurrences
  ///   counts both from the same result text.
  /// • Staccato / jotted → holdover gate keeps inter-chant dips from looking
  ///   like silence, so the full word accumulates before the window fires.
  ///
  /// Do NOT go below 1200 ms — shorter windows risk cutting mid-syllable for
  /// slower speakers, producing partial-word results that score 0.
  static const int _windowMs = 1500;

  Stream<VoiceTrainingEvent> get events => _events.stream;

  /// Ensure model is loaded (idempotent). Call once before [start].
  Future<void> warmUp() async {
    if (_recognizer != null) return;
    final path = await _modelLoader.ensureExtracted();
    _recognizer = await VoskRecognizer.create(modelPath: path);
  }

  /// Begin a session. Emits [VoiceTrainingEvent]s on [events].
  /// Stops automatically once [target] matches are observed.
  Future<void> start(
    Mantra mantra, {
    int target = 11,
    MicSensitivity sensitivity = MicSensitivity.medium,
  }) async {
    if (_running) return;
    _running = true;
    _finalizing = false;
    _timerStarted = false;
    _matches = 0;
    _target = target;
    _mantra = mantra;

    await warmUp();
    await _recognizer!.setGrammar([mantra.name.devanagari]);

    final stream = await _audio.start(
      minAmplitude: sensitivity.minAmplitudeThreshold,
      // 400 ms holdover: covers brief inter-syllable and inter-chant dips for
      // all chanting styles (slow, fast, staccato, jotted, continuous).
      // The decoder sees a smooth audio stream without artificial silence gaps.
      holdoverMs: 400,
    );

    // ── PCM stream → Vosk ──────────────────────────────────────────────────
    // The window timer is NOT started here. It is deferred until the first
    // non-silence audio chunk arrives so the very first chant always gets a
    // full 1500 ms window regardless of how long the user waits before
    // speaking. Without this, a user who starts chanting ~1 s after tapping
    // "Start" would have their first word cut mid-syllable by the timer.
    _sub = stream.listen(
      (chunk) async {
        // Skip chunk processing while the timer is flushing to avoid
        // calling acceptChunk and finalize/getFinalResult concurrently.
        if (!_running || _finalizing) return;

        // Start the window timer on the first real (non-silence) chunk.
        // Silence chunks from the amplitude gate are all-zero bytes; real
        // audio always has at least one non-zero byte.
        if (!_timerStarted && chunk.any((b) => b != 0)) {
          _timerStarted = true;
          _windowTimer = Timer.periodic(
            const Duration(milliseconds: _windowMs),
            (_) => _forceFinalize(),
          );
        }

        final r = await _recognizer?.acceptChunk(chunk);
        if (r == null) return;

        if (r.isFinal && r.text.trim().isNotEmpty) {
          // Natural silence-based final — count it immediately.
          await _handleText(r.text);
        } else if (!r.isFinal && r.text.isNotEmpty) {
          _events.add(VoiceTrainingEvent.partial(_matches, r.text));
        }
      },
      onError: (Object e) =>
          _events.add(VoiceTrainingEvent.error(_matches, e)),
    );
  }

  /// Forced finalisation: flush accumulated audio, count, let Vosk reset.
  ///
  /// Vosk's `getFinalResult()` (called inside `finalize()`) both returns
  /// the best result AND resets the internal decoder state — ready to
  /// accept audio for the next utterance without any recognizer recreation.
  Future<void> _forceFinalize() async {
    if (!_running || _finalizing) return;
    _finalizing = true;
    try {
      final r = await _recognizer?.finalize();
      if (r != null && r.text.trim().isNotEmpty) {
        await _handleText(r.text);
      }
      // Vosk state is now reset — no setGrammar / recreate needed.
    } finally {
      _finalizing = false;
    }
  }

  /// Count how many times the mantra appears in [text] and emit events.
  Future<void> _handleText(String text) async {
    final mantra = _mantra;
    if (mantra == null) return;

    final count = _countOccurrences(text, mantra);
    if (count == 0) {
      _events.add(VoiceTrainingEvent.miss(_matches, text));
      return;
    }

    for (int i = 0; i < count; i++) {
      _matches++;
      _events.add(VoiceTrainingEvent.matched(_matches));
      if (_matches >= _target) {
        await stop();
        return;
      }
    }
  }

  /// Count how many times [mantra]'s Devanagari form appears in [text].
  int _countOccurrences(String text, Mantra mantra) =>
      VoicePhraseMatcher.countOccurrences(text, mantra.name.devanagari);

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _windowTimer?.cancel();
    _windowTimer = null;
    await _sub?.cancel();
    _sub = null;
    await _audio.stop();
    // Flush any final audio left in the buffer.
    final r = await _recognizer?.finalize();
    if (r != null && r.text.trim().isNotEmpty) {
      await _handleText(r.text);
    }
    _events.add(VoiceTrainingEvent.done(_matches));
  }

  Future<void> dispose() async {
    await stop();
    await _audio.dispose();
    await _recognizer?.dispose();
    await _events.close();
  }
}

/// Public static helper for counting mantra occurrences in ASR output.
/// Exposed separately so it can be unit-tested without a running audio session.
abstract final class VoicePhraseMatcher {
  /// Returns how many non-overlapping whole-word times [phrase] appears in
  /// [text]. Both are normalised (trimmed, lowercased) before comparison so
  /// punctuation and capitalisation in Vosk output don't affect the count.
  ///
  /// A match is accepted only when the phrase is surrounded by word
  /// boundaries: start/end of string, whitespace, or common punctuation
  /// (comma, period, exclamation, question mark). This prevents "राम" from
  /// matching inside "सीताराम" even if the grammar constraint fails to
  /// exclude that token.
  static int countOccurrences(String text, String phrase) {
    final needle   = phrase.trim().toLowerCase();
    final haystack = text.trim().toLowerCase();
    if (needle.isEmpty || haystack.isEmpty) return 0;
    int count = 0;
    int start = 0;
    while (true) {
      final idx = haystack.indexOf(needle, start);
      if (idx == -1) break;
      // Check left boundary
      final leftOk = idx == 0 || _isBoundary(haystack.codeUnitAt(idx - 1));
      // Check right boundary
      final endIdx = idx + needle.length;
      final rightOk =
          endIdx == haystack.length || _isBoundary(haystack.codeUnitAt(endIdx));
      if (leftOk && rightOk) count++;
      start = endIdx;
    }
    return count;
  }

  /// Returns true for characters that constitute a word boundary:
  /// ASCII whitespace or common punctuation marks.
  static bool _isBoundary(int codeUnit) {
    // space, tab, newline, comma, period, !, ?, ;, :
    const boundaries = {0x20, 0x09, 0x0A, 0x0D, 0x2C, 0x2E, 0x21, 0x3F, 0x3B, 0x3A};
    return boundaries.contains(codeUnit);
  }
}

/// Discriminated event union emitted during voice training.
sealed class VoiceTrainingEvent {
  const VoiceTrainingEvent(this.count);
  final int count;

  factory VoiceTrainingEvent.matched(int count) = _Matched;
  factory VoiceTrainingEvent.partial(int count, String text) = _Partial;
  factory VoiceTrainingEvent.miss(int count, String heard) = _Miss;
  factory VoiceTrainingEvent.done(int count) = _Done;
  factory VoiceTrainingEvent.error(int count, Object error) = _Error;
}

final class _Matched extends VoiceTrainingEvent {
  const _Matched(super.count);
}

final class _Partial extends VoiceTrainingEvent {
  const _Partial(super.count, this.text);
  final String text;
}

final class _Miss extends VoiceTrainingEvent {
  const _Miss(super.count, this.heard);
  final String heard;
}

final class _Done extends VoiceTrainingEvent {
  const _Done(super.count);
}

final class _Error extends VoiceTrainingEvent {
  const _Error(super.count, this.error);
  final Object error;
}
