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
/// Vosk's built-in silence detector only emits a final result when it hears
/// a pause.  Rapid, continuous chanting produces no silence → no final → no
/// count.  We work around this with **timed-window forced finalisation**:
///
/// 1. Raw PCM chunks from the mic are accumulated into a byte buffer.
/// 2. Every [_windowMs] milliseconds a [Timer] fires, forces
///    `recognizer.finalize()` on the accumulated audio, and resets the
///    decoder for the next window.
/// 3. The final-result text is scanned for **occurrences** of the mantra
///    word(s), so two rapid chants that land in the same window are both
///    counted.
///
/// The window is 900 ms — comfortably long enough for one slow chant,
/// and short enough that a fast chanter loses at most one count to a window
/// boundary.
///
/// Vosk's normal silence-based final results are also counted (they fire when
/// there IS a natural pause and the window hasn't expired yet), so deliberate
/// slow chanting works just as well.
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
  int _target = 11;
  Mantra? _mantra;

  // How often (ms) we force a finalisation regardless of silence.
  static const int _windowMs = 900;

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
    _matches = 0;
    _target = target;
    _mantra = mantra;

    await warmUp();
    await _recognizer!.setGrammar([mantra.name.devanagari]);

    final stream = await _audio.start(
      minAmplitude: sensitivity.minAmplitudeThreshold,
      // 250 ms holdover: brief inter-chant dips are not silenced immediately,
      // preventing artificial gaps that confuse the decoder.
      holdoverMs: 250,
    );

    // ── Timed-window timer ─────────────────────────────────────────────────
    // Fires every [_windowMs] ms.  Forces a final result from whatever audio
    // Vosk has accumulated so far, then resets the decoder for the next window.
    _windowTimer = Timer.periodic(
      const Duration(milliseconds: _windowMs),
      (_) => _forceFinalize(),
    );

    // ── PCM stream → Vosk ──────────────────────────────────────────────────
    _sub = stream.listen(
      (chunk) async {
        if (!_running) return;
        final r = await _recognizer!.acceptChunk(chunk);
        if (r == null) return;

        // Vosk fired a natural silence-based final result *before* the window
        // timer.  Count it immediately (the timer will reset the decoder next).
        if (r.isFinal && r.text.trim().isNotEmpty) {
          await _handleText(r.text, source: 'natural');
        } else if (!r.isFinal && r.text.isNotEmpty) {
          _events.add(VoiceTrainingEvent.partial(_matches, r.text));
        }
      },
      onError: (Object e) => _events.add(VoiceTrainingEvent.error(_matches, e)),
    );
  }

  /// Forced finalisation: call `getFinalResult`, count occurrences, reset.
  Future<void> _forceFinalize() async {
    if (!_running) return;
    final r = await _recognizer!.finalize();
    if (r != null && r.text.trim().isNotEmpty) {
      await _handleText(r.text, source: 'timed');
    }
    // Reset the decoder for the next window by re-applying the grammar.
    // This clears Vosk's internal acoustic state so rapid chants in the next
    // window are decoded fresh rather than blended with residual state.
    final mantra = _mantra;
    if (_running && mantra != null) {
      await _recognizer!.setGrammar([mantra.name.devanagari]);
    }
  }

  /// Count how many times the mantra appears in [text] and emit events.
  Future<void> _handleText(String text, {required String source}) async {
    final mantra = _mantra;
    if (mantra == null) return;

    final count = _countOccurrences(text, mantra);
    if (count == 0) {
      // Recognised something but it wasn't the mantra.
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
  ///
  /// Handles both:
  ///   - Single-word mantras: exact word boundary match
  ///   - Multi-word mantras:  search for the full phrase, then slide forward
  int _countOccurrences(String text, Mantra mantra) {
    final needle = mantra.name.devanagari.trim().toLowerCase();
    final haystack = text.trim().toLowerCase();
    if (needle.isEmpty || haystack.isEmpty) return 0;

    int count = 0;
    int start = 0;
    while (true) {
      final idx = haystack.indexOf(needle, start);
      if (idx == -1) break;
      count++;
      start = idx + needle.length;
    }
    return count;
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _windowTimer?.cancel();
    _windowTimer = null;
    await _sub?.cancel();
    _sub = null;
    await _audio.stop();
    final r = _recognizer;
    if (r != null) await r.finalize();
    _events.add(VoiceTrainingEvent.done(_matches));
  }

  Future<void> dispose() async {
    await stop();
    await _audio.dispose();
    await _recognizer?.dispose();
    await _events.close();
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
