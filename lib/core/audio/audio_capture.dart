import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// 16 kHz mono PCM mic stream. Single source of truth for mic capture —
/// shared by enrolment and counting features.
class AudioCapture {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;
  StreamController<Uint8List>? _out;

  static const int sampleRate = 16000;

  /// Peak absolute amplitude of a 16-bit PCM [chunk] (0–32767).
  static double peakAmplitude(Uint8List chunk) {
    if (chunk.length < 2) return 0;
    // The Android `record` plugin delivers Uint8List sub-views whose
    // offsetInBytes may be odd (e.g. 5), which breaks asInt16List() because
    // Int16List requires 2-byte alignment.  Copying to a fresh list always
    // gives offsetInBytes == 0, fixing the RangeError crash.
    final bytes = Uint8List.fromList(chunk);
    final samples = bytes.buffer.asInt16List();
    double peak = 0;
    for (final s in samples) {
      final abs = s.abs().toDouble();
      if (abs > peak) peak = abs;
    }
    return peak;
  }

  Future<bool> ensurePermission() async {
    if (await Permission.microphone.isGranted) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Lightweight check used before kicking off voice mode — lets the UI
  /// decide between "permanently denied → open settings" vs. "ask politely".
  Future<PermissionStatus> permissionStatus() => Permission.microphone.status;

  /// Start the mic stream.
  ///
  /// [minAmplitude] — chunks whose peak 16-bit amplitude is below this value
  /// are replaced with silence (all-zero bytes) before being forwarded.
  /// Use [MicSensitivity.minAmplitudeThreshold] to convert the setting.
  /// Defaults to 0 (no gate — every chunk passes through).
  /// Start the mic stream.
  ///
  /// [minAmplitude] — amplitude gate threshold (0 = disabled).
  /// [holdoverMs] — how many consecutive milliseconds of sub-threshold audio
  /// must be seen before a chunk is replaced with silence.  Defaults to 250 ms,
  /// which prevents the brief amplitude dip *between* rapid chants from being
  /// treated as silence by the ASR decoder.
  /// [calibrateMs] — if > 0, the first [calibrateMs] of audio are used to
  /// measure the room's ambient noise floor. The gate threshold is then raised
  /// to `noiseFloor * noiseMultiplier` (never below [minAmplitude], capped at
  /// 3× [minAmplitude]) so background noise is filtered while real chants —
  /// which are louder than ambient — still pass. In a quiet room the floor is
  /// low, so the threshold stays at [minAmplitude] (unchanged behaviour).
  /// Audio during calibration is passed through so the first chant isn't lost.
  Future<Stream<Uint8List>> start({
    double minAmplitude = 0,
    int holdoverMs = 250,
    int calibrateMs = 0,
    double noiseMultiplier = 1.5,
  }) async {
    if (!await ensurePermission()) {
      throw StateError('Microphone permission denied');
    }
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
      noiseSuppress: false,
      echoCancel: false,
    ));
    _out = StreamController<Uint8List>.broadcast();

    // Holdover gate state: track how long the signal has been quiet.
    int quietMs = 0;
    // Adaptive-gate state.
    double effectiveMin = minAmplitude;
    double noiseFloor = 0;
    int calibAccrued = 0;
    bool calibrating = calibrateMs > 0;

    _sub = stream.listen(
      (chunk) {
        // Estimate chunk duration in ms (16-bit = 2 bytes/sample, mono).
        final chunkDurationMs =
            ((chunk.lengthInBytes / 2) / sampleRate * 1000).round();
        final peak = peakAmplitude(chunk);

        // ── Calibration: learn the ambient noise floor, pass audio through ──
        if (calibrating) {
          if (peak > noiseFloor) noiseFloor = peak;
          calibAccrued += chunkDurationMs;
          if (calibAccrued >= calibrateMs) {
            calibrating = false;
            final adaptive = noiseFloor * noiseMultiplier;
            // Raise the gate to clear the noise floor, but never below the
            // configured minimum and never more than 3× it (so a stray loud
            // sound during calibration can't deafen the gate).
            final ceiling = minAmplitude > 0 ? minAmplitude * 3 : adaptive;
            effectiveMin = adaptive.clamp(minAmplitude, ceiling).toDouble();
          }
          _out!.add(chunk);
          return;
        }

        if (effectiveMin <= 0) {
          _out!.add(chunk);
          return;
        }

        if (peak >= effectiveMin) {
          quietMs = 0; // signal is loud enough — reset holdover
          _out!.add(chunk);
        } else {
          quietMs += chunkDurationMs;
          // Only silence the chunk once the signal has been quiet long enough.
          // Within the holdover window we still pass real audio so the ASR
          // engine does not see artificial silence between rapid chants.
          if (quietMs >= holdoverMs) {
            _out!.add(Uint8List(chunk.length)); // all-zero = silence
          } else {
            _out!.add(chunk);
          }
        }
      },
      onError: _out!.addError,
      onDone: _out!.close,
    );
    return _out!.stream;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    await _out?.close();
    _out = null;
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }
}
