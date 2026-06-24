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
  }) : _modelLoader = modelLoader ?? VoskModelLoader(),
       _recognizer = recognizer,
       // A recognizer passed in is shared (warmed once, reused across
       // sessions) — this service must NOT dispose it. It only owns a
       // recognizer it builds itself in [warmUp].
       _ownsRecognizer = recognizer == null,
       _audio = audio ?? AudioCapture();

  final VoskModelLoader _modelLoader;
  VoskRecognizer? _recognizer;
  bool _ownsRecognizer;
  final AudioCapture _audio;

  StreamSubscription<Uint8List>? _sub;
  Timer? _windowTimer;
  final _events = StreamController<VoiceTrainingEvent>.broadcast();
  // Live normalised mic level (0..1) for reactive UI (voice waves).
  final _levels = StreamController<double>.broadcast();

  int _matches = 0;
  bool _running = false;

  /// True while the timer is flushing — chunk callbacks buffer instead of
  /// calling into the recognizer concurrently.
  bool _finalizing = false;

  /// Audio chunks received during a forced-finalize are buffered here and
  /// replayed immediately after so no speech is ever silently dropped.
  final _bufferedChunks = <Uint8List>[];

  bool _timerStarted = false;
  int _target = 11;
  Mantra? _mantra;

  /// How often (ms) we force a finalisation regardless of silence.
  /// 800 ms: at fast-chanting pace (~1 chant/600 ms) this means at most one
  /// chant lands per window, making recognition reliable. Vosk's own
  /// silence-detection fires first for slower chants.
  static const int _windowMs = 800;

  Stream<VoiceTrainingEvent> get events => _events.stream;

  /// Live mic level (0..1), emitted per audio chunk. Drives reactive UI.
  Stream<double> get levels => _levels.stream;

  /// Ensure model is loaded (idempotent). Call once before [start].
  Future<void> warmUp() async {
    if (_recognizer != null) return;
    final path = await _modelLoader.ensureExtracted();
    _recognizer = await VoskRecognizer.create(modelPath: path);
    _ownsRecognizer = true;
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
    // Wider grammar = higher recall: the small model can land on the full
    // phrase OR an individual word of it (e.g. "राम" when "श्री" was missed),
    // instead of being forced to nail the whole phrase. [unk] still absorbs
    // noise, so precision holds.
    await _recognizer!.setGrammar(_grammarPhrases(mantra));

    final stream = await _audio.start(
      minAmplitude: 0, // gate disabled — let Vosk handle silence; hardware gate
                       // threshold at 2000 was blocking all audio without AGC
      holdoverMs: 450,
      calibrateMs: 0,
      noiseMultiplier: 1.5,
    );

    // ── Start window timer immediately ─────────────────────────────────────
    // Previously the timer was deferred until speech onset (peak ≥ threshold).
    // That caused the first 1–3 chants to be lost: they accumulated in Vosk
    // but were never force-finalized because the threshold was never crossed
    // (quiet room, mic warmup, etc.). Starting the timer right away means
    // the first chant always gets finalized within one window.
    _timerStarted = true;
    _windowTimer = Timer.periodic(
      const Duration(milliseconds: _windowMs),
      (_) => _forceFinalize(),
    );

    _sub = stream.listen(
      (chunk) async {
        final peak = AudioCapture.peakAmplitude(chunk);
        if (!_levels.isClosed) {
          _levels.add((peak / 6000.0).clamp(0.0, 1.0));
        }

        if (!_running) return;

        // Buffer incoming audio while a forced-finalize is in progress.
        // Replaying these chunks after the finalize ensures the start of the
        // next chant is never silently discarded (the main cause of skips at
        // fast chanting pace).
        if (_finalizing) {
          _bufferedChunks.add(chunk);
          return;
        }

        final r = await _recognizer?.acceptChunk(chunk);
        if (r == null) return;

        if (r.isFinal && r.text.trim().isNotEmpty) {
          // Natural silence-based final — count and reset the forced-finalize
          // timer so it re-aligns to the next chant start, preventing the
          // window from cutting the next word mid-syllable.
          await _handleText(r.text);
          _restartWindowTimer();
        } else if (!r.isFinal && r.text.isNotEmpty) {
          _events.add(VoiceTrainingEvent.partial(_matches, r.text));
        }
      },
      onError: (Object e) => _events.add(VoiceTrainingEvent.error(_matches, e)),
    );
  }

  /// Cancel and restart the periodic window timer from now.
  /// Called after Vosk fires a natural silence-based final so the next
  /// forced-finalize window starts fresh, never cutting the next chant
  /// mid-syllable due to a fixed-phase periodic offset.
  void _restartWindowTimer() {
    if (!_running) return;
    _windowTimer?.cancel();
    _windowTimer = Timer.periodic(
      const Duration(milliseconds: _windowMs),
      (_) => _forceFinalize(),
    );
  }

  /// Forced finalisation: flush accumulated audio, count, let Vosk reset,
  /// then replay any chunks that arrived while we were blocked.
  Future<void> _forceFinalize() async {
    if (!_running || _finalizing) return;
    _finalizing = true;
    try {
      final r = await _recognizer?.finalize();
      if (r != null && r.text.trim().isNotEmpty) {
        await _handleText(r.text);
      }
    } finally {
      _finalizing = false;
    }

    // Replay chunks buffered while finalization was in progress. This prevents
    // the start of the next chant from being silently dropped.
    if (!_running) {
      _bufferedChunks.clear();
      return;
    }
    final toReplay = List<Uint8List>.of(_bufferedChunks);
    _bufferedChunks.clear();
    for (final c in toReplay) {
      if (!_running || _finalizing) break;
      final r = await _recognizer?.acceptChunk(c);
      if (r == null) continue;
      if (r.isFinal && r.text.trim().isNotEmpty) {
        await _handleText(r.text);
        _restartWindowTimer();
        break;
      }
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

  /// Count how many times [mantra]'s full Devanagari phrase appears in [text].
  /// Only a complete phrase match counts — partial words (e.g. just "Shri"
  /// from "Sri Rama") are never accepted.
  int _countOccurrences(String text, Mantra mantra) {
    return VoicePhraseMatcher.countOccurrences(
      text,
      mantra.name.devanagari,
    );
  }

  /// Grammar phrases for the mantra: the full Devanagari phrase plus each of
  /// its words (≥2 chars). Lets Vosk recognise partial chants.
  List<String> _grammarPhrases(Mantra mantra) {
    final full = mantra.name.devanagari.trim();
    final words = full
        .split(RegExp(r'\s+'))
        .where((w) => w.runes.length >= 2)
        .toList();
    return {if (full.isNotEmpty) full, ...words}.toList();
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _bufferedChunks.clear();
    if (!_levels.isClosed) _levels.add(0); // waves settle when capture stops
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
    // Only dispose a recognizer we built ourselves — a shared/injected one
    // is owned by its provider and reused by later sessions.
    if (_ownsRecognizer) await _recognizer?.dispose();
    await _events.close();
    await _levels.close();
  }
}

/// Public static helper for counting mantra occurrences in ASR output.
/// Exposed separately so it can be unit-tested without a running audio session.
abstract final class VoicePhraseMatcher {
  /// Returns how many non-overlapping whole-token times [phrase] appears in
  /// [text]. Both are normalised before comparison so punctuation,
  /// capitalisation, and small Vosk Devanagari substitutions don't affect the
  /// count.
  ///
  /// A match is accepted only when the phrase is surrounded by word
  /// boundaries: start/end of string, whitespace, or common punctuation
  /// (comma, period, exclamation, question mark). This prevents "राम" from
  /// matching inside "सीताराम" even if the grammar constraint fails to
  /// exclude that token.
  static int countOccurrences(String text, String phrase) {
    final needle = phrase.trim().toLowerCase();
    final haystack = text.trim().toLowerCase();
    if (needle.isEmpty || haystack.isEmpty) return 0;

    final phraseTokens = _tokens(needle);
    final textTokens = _tokens(haystack);
    if (phraseTokens.isEmpty || textTokens.length < phraseTokens.length) {
      return 0;
    }

    var fuzzyCount = 0;
    for (var i = 0; i <= textTokens.length - phraseTokens.length;) {
      if (_tokenWindowMatches(textTokens, phraseTokens, i)) {
        fuzzyCount++;
        i += phraseTokens.length;
      } else {
        i++;
      }
    }
    return fuzzyCount;
  }

  /// Returns true for characters that constitute a word boundary:
  /// whitespace, punctuation, or Devanagari danda marks.
  static bool _isBoundary(int codeUnit) {
    const boundaries = {
      0x20,
      0x09,
      0x0A,
      0x0D,
      0x2C,
      0x2E,
      0x21,
      0x3F,
      0x3B,
      0x3A,
      0x0964,
      0x0965,
    };
    return boundaries.contains(codeUnit);
  }

  static List<String> _tokens(String value) {
    final tokens = <String>[];
    final current = StringBuffer();
    for (final rune in value.runes) {
      if (_isBoundary(rune)) {
        if (current.isNotEmpty) {
          tokens.add(current.toString());
          current.clear();
        }
      } else {
        current.writeCharCode(rune);
      }
    }
    if (current.isNotEmpty) tokens.add(current.toString());
    return tokens;
  }

  static bool _tokenWindowMatches(
    List<String> textTokens,
    List<String> phraseTokens,
    int offset,
  ) {
    var edits = 0;
    for (var j = 0; j < phraseTokens.length; j++) {
      final text = _normaliseToken(textTokens[offset + j]);
      final phrase = _normaliseToken(phraseTokens[j]);
      if (text == phrase) continue;

      final maxEdits = phrase.runes.length >= 4 ? 1 : 0;
      if (maxEdits == 0) return false;

      final distance = _boundedEditDistance(text, phrase, maxEdits);
      if (distance > maxEdits) return false;
      edits += distance;
      if (edits > 2) return false;
    }
    return true;
  }

  static String _normaliseToken(String token) => token
      .replaceAll('ॐ', 'ओम')
      .replaceAll('ँ', '')
      .replaceAll('ं', '')
      .replaceAll('ः', '')
      .replaceAll('़', '')
      .replaceAll('ण', 'न');

  static int _boundedEditDistance(String a, String b, int maxDistance) {
    final ar = a.runes.toList(growable: false);
    final br = b.runes.toList(growable: false);
    if ((ar.length - br.length).abs() > maxDistance) return maxDistance + 1;

    var prev = List<int>.generate(br.length + 1, (i) => i);
    for (var i = 1; i <= ar.length; i++) {
      final curr = List<int>.filled(br.length + 1, 0);
      curr[0] = i;
      var rowMin = curr[0];
      for (var j = 1; j <= br.length; j++) {
        final cost = ar[i - 1] == br[j - 1] ? 0 : 1;
        final insert = curr[j - 1] + 1;
        final delete = prev[j] + 1;
        final replace = prev[j - 1] + cost;
        curr[j] = insert < delete
            ? (insert < replace ? insert : replace)
            : (delete < replace ? delete : replace);
        if (curr[j] < rowMin) rowMin = curr[j];
      }
      if (rowMin > maxDistance) return maxDistance + 1;
      prev = curr;
    }
    return prev.last;
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
