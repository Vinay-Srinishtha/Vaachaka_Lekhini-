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

  Future<bool> ensurePermission() async {
    if (await Permission.microphone.isGranted) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Lightweight check used before kicking off voice mode — lets the UI
  /// decide between "permanently denied → open settings" vs. "ask politely".
  Future<PermissionStatus> permissionStatus() => Permission.microphone.status;

  Future<Stream<Uint8List>> start() async {
    if (!await ensurePermission()) {
      throw StateError('Microphone permission denied');
    }
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
      // Cleaner audio for Vosk in noisy environments (kitchens, traffic).
      // Echo cancellation is irrelevant — no playback while chanting.
      noiseSuppress: true,
      echoCancel: false,
    ));
    _out = StreamController<Uint8List>.broadcast();
    _sub = stream.listen(_out!.add, onError: _out!.addError, onDone: _out!.close);
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
