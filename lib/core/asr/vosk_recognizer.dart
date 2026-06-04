import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:vosk_flutter_2/vosk_flutter_2.dart';

class WordResult {
  final String word;
  final double confidence;
  final double start;
  final double end;
  WordResult(this.word, this.confidence, this.start, this.end);

  factory WordResult.fromJson(Map<String, dynamic> j) =>
      WordResult(j['word'] as String, (j['conf'] as num).toDouble(),
          (j['start'] as num).toDouble(), (j['end'] as num).toDouble());
}

class RecognitionResult {
  final String text;
  final List<WordResult> words;
  final bool isFinal;
  RecognitionResult({required this.text, required this.words, required this.isFinal});

  double get minWordConfidence =>
      words.isEmpty ? 0 : words.map((w) => w.confidence).reduce((a, b) => a < b ? a : b);
}

/// DRY wrapper around vosk_flutter_2. The same instance is reused for
/// enrolment and counting — only [grammar] changes between sessions.
class VoskRecognizer {
  final VoskFlutterPlugin _plugin;
  final Model _model;
  final int sampleRate;

  Recognizer? _recognizer;

  VoskRecognizer._(this._plugin, this._model, this.sampleRate);

  static Future<VoskRecognizer> create({
    required String modelPath,
    int sampleRate = 16000,
  }) async {
    final plugin = VoskFlutterPlugin.instance();
    final model = await plugin.createModel(modelPath);
    return VoskRecognizer._(plugin, model, sampleRate);
  }

  /// Restrict recognition to [phrases] (plus implicit `[unk]` to absorb
  /// non-matches). Pass the *only* expected mantra here — single-mantra
  /// grammar gives binary match/no-match accuracy.
  Future<void> setGrammar(List<String> phrases) async {
    await _recognizer?.dispose();
    final grammar = [...phrases, '[unk]'];
    _recognizer = await _plugin.createRecognizer(
      model: _model,
      sampleRate: sampleRate,
      grammar: grammar,
    );
  }

  Future<RecognitionResult?> acceptChunk(Uint8List pcm16) async {
    final r = _recognizer;
    if (r == null) return null;
    final isFinal = await r.acceptWaveformBytes(pcm16);
    final raw = isFinal ? await r.getFinalResult() : await r.getPartialResult();
    return _parse(raw, isFinal);
  }

  Future<RecognitionResult?> finalize() async {
    final r = _recognizer;
    if (r == null) return null;
    final raw = await r.getFinalResult();
    return _parse(raw, true);
  }

  RecognitionResult _parse(String raw, bool isFinal) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final text = (j['text'] ?? j['partial'] ?? '') as String;
    final words = (j['result'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(WordResult.fromJson)
            .toList() ??
        const <WordResult>[];
    return RecognitionResult(text: text, words: words, isFinal: isFinal);
  }

  Future<void> dispose() async {
    await _recognizer?.dispose();
    _model.dispose();
  }
}
