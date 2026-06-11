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
    if (chunk.isEmpty) return 0;
    final samples = chunk.buffer.asInt16List(chunk.offsetInBytes);
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
  Future<Stream<Uint8List>> start({double minAmplitude = 0}) async {
    if (!await ensurePermission()) {
      throw StateError('Microphone permission denied');
    }
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
      noiseSuppress: true,
      echoCancel: false,
    ));
    _out = StreamController<Uint8List>.broadcast();
    _sub = stream.listen(
      (chunk) {
        // Amplitude gate: if the chunk is too quiet, send silence instead.
        // This stops ASR from mis-firing on background noise.
        final gated = minAmplitude > 0 && peakAmplitude(chunk) < minAmplitude
            ? Uint8List(chunk.length) // all-zero = silence
            : chunk;
        _out!.add(gated);
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
