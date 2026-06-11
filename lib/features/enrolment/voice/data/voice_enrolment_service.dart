import 'dart:async';
import 'dart:typed_data';

import '../../../../core/asr/vosk_model_loader.dart';
import '../../../../core/asr/vosk_recognizer.dart';
import '../../../../core/audio/audio_capture.dart';
import '../../../mantras/domain/mantra.dart';
import '../../../settings/domain/settings_repository.dart';

/// Drives a voice-enrolment session: hooks the mic stream to Vosk,
/// counts confirmed matches of a chosen mantra, and emits progress.
///
/// Phase-2 scope: matching only. Phase-8 polish adds the TFLite ECAPA-TDNN
/// speaker embedding capture using the same audio buffers we already see here.
class VoiceEnrolmentService {
  VoiceEnrolmentService({VoskModelLoader? modelLoader, VoskRecognizer? recognizer, AudioCapture? audio})
      : _modelLoader = modelLoader ?? VoskModelLoader(),
        _recognizer = recognizer,
        _audio = audio ?? AudioCapture();

  final VoskModelLoader _modelLoader;
  VoskRecognizer? _recognizer;
  final AudioCapture _audio;

  StreamSubscription<Uint8List>? _sub;
  final _events = StreamController<VoiceTrainingEvent>.broadcast();
  int _matches = 0;
  bool _running = false;

  Stream<VoiceTrainingEvent> get events => _events.stream;

  /// Ensure model is loaded (idempotent). Call once before [start].
  Future<void> warmUp() async {
    if (_recognizer != null) return;
    final path = await _modelLoader.ensureExtracted();
    _recognizer = await VoskRecognizer.create(modelPath: path);
  }

  /// Begin a training session. Emits [VoiceTrainingEvent]s on [events].
  /// Automatically stops itself once [target] matches are observed.
  ///
  /// [sensitivity] controls the amplitude gate — quiet chunks below the
  /// threshold are silenced before being sent to the ASR engine, preventing
  /// background noise from triggering false matches.
  Future<void> start(
    Mantra mantra, {
    int target = 11,
    MicSensitivity sensitivity = MicSensitivity.medium,
  }) async {
    if (_running) return;
    _running = true;
    _matches = 0;
    await warmUp();
    await _recognizer!.setGrammar([mantra.name.devanagari]);

    final stream = await _audio.start(
      minAmplitude: sensitivity.minAmplitudeThreshold,
    );
    _sub = stream.listen((chunk) async {
      if (!_running) return;
      final r = await _recognizer!.acceptChunk(chunk);
      if (r == null) return;

      if (r.isFinal) {
        if (_isMatch(r.text, mantra)) {
          _matches++;
          _events.add(VoiceTrainingEvent.matched(_matches));
          if (_matches >= target) await stop();
        } else if (r.text.trim().isNotEmpty) {
          _events.add(VoiceTrainingEvent.miss(_matches, r.text));
        }
      } else if (r.text.isNotEmpty) {
        _events.add(VoiceTrainingEvent.partial(_matches, r.text));
      }
    }, onError: (Object e) => _events.add(VoiceTrainingEvent.error(_matches, e)));
  }

  bool _isMatch(String heard, Mantra mantra) {
    final clean = heard.trim();
    if (clean.isEmpty) return false;
    // For Phase 2 we accept exact match against the canonical Devanagari
    // form (per the binary-match grammar design). Future work: tolerate
    // half-matches via word-level confidence.
    return clean == mantra.name.devanagari;
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
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
