import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// One expected target: the script-specific Tesseract language and the text
/// the user is supposed to have written in that script.
class ExpectedWriting {
  const ExpectedWriting({required this.tessLang, required this.text});

  /// Tesseract language code: 'eng' | 'hin' | 'tel' | 'kan'.
  final String tessLang;

  /// The expected mantra spelling in that script (e.g. Devanagari or roman).
  final String text;
}

/// Result of checking a handwriting sample against the expected mantra.
class HandwritingResult {
  const HandwritingResult({
    required this.accepted,
    required this.similarity,
    required this.recognized,
    required this.expected,
  });

  final bool accepted;
  final double similarity; // best 0..1 over all candidates
  final String recognized; // best-matching output (debug/feedback)
  final String expected; // the target it was closest to
}

/// Tesseract lang code → ML Kit BCP-47 digital ink model tag.
/// Languages absent from this map fall through to Tesseract OCR (e.g. 'eng').
const _mlKitLangMap = {
  'eng': 'en-US', // English cursive/print handwriting via ML Kit stroke model
  'hin': 'hi',
  'tel': 'te',
  'kan': 'kn',
};

/// Fully offline handwriting verification.
///
/// English → Tesseract OCR (unchanged, bundled traineddata).
/// Hindi / Telugu / Kannada → Google ML Kit Digital Ink Recognition
///   (stroke-gesture model; downloaded from Google on first use, then cached).
///
/// Both paths use the same _normalize + _similarity scoring pipeline with the
/// same _minSimilarity = 0.50 acceptance threshold.
class HandwritingRecognizer {
  HandwritingRecognizer._();
  static final HandwritingRecognizer instance = HandwritingRecognizer._();

  static const double _minSimilarity = 0.50;

  // ML Kit recognizer instances, cached by BCP-47 language code.
  final _recognizers = <String, DigitalInkRecognizer>{};
  final _modelManager = DigitalInkRecognizerModelManager();

  /// Recognise [pngBytes] and decide whether it matches any of [candidates].
  ///
  /// [strokes] — raw stroke data from the drawing canvas:
  ///   `controller.pointsToStrokes(3).map((s) => s.map((p) => p.offset).toList()).toList()`
  /// When provided, Indic-script candidates use ML Kit Digital Ink instead of
  /// Tesseract OCR. English candidates always use Tesseract regardless.
  Future<HandwritingResult> check({
    required Uint8List pngBytes,
    required List<ExpectedWriting> candidates,
    List<List<Offset>>? strokes,
  }) async {
    var bestSim = 0.0;
    var bestRecognised = '';
    var bestExpected = '';

    // Defer Tesseract image rendering until actually needed.
    String? imagePath;
    final recognisedByTessLang = <String, String>{};

    for (final c in candidates) {
      final mlLang = _mlKitLangMap[c.tessLang];
      String got;

      if (mlLang != null && strokes != null && strokes.isNotEmpty) {
        // ── ML Kit Digital Ink path (Hindi / Telugu / Kannada) ────────────
        got = await _mlKitRecognize(strokes, mlLang);
      } else {
        // ── Tesseract OCR path (English + fallback) ───────────────────────
        if (!recognisedByTessLang.containsKey(c.tessLang)) {
          imagePath ??= await _renderForOcr(pngBytes);
          recognisedByTessLang[c.tessLang] = await _ocr(imagePath, c.tessLang);
        }
        got = recognisedByTessLang[c.tessLang]!;
      }

      final normGot = _normalize(got);
      final normWant = _normalize(c.text);
      if (normWant.isEmpty) continue;
      // Syllable gate: exact syllable count match required.
      // Prevents partial words ("श्री" for "श्रीराम") from passing via infix score.
      if (_syllableCount(normGot) != _syllableCount(normWant)) continue;
      final sim = _similarity(normGot, normWant);
      if (sim > bestSim) {
        bestSim = sim;
        bestRecognised = got;
        bestExpected = c.text;
      }
    }

    if (imagePath != null) {
      try { await File(imagePath).delete(); } catch (_) {}
    }

    return HandwritingResult(
      accepted: bestSim >= _minSimilarity,
      similarity: bestSim,
      recognized: bestRecognised,
      expected: bestExpected,
    );
  }

  /// ML Kit Digital Ink recognition. Returns the top candidate text, or ''
  /// on any failure (graceful degradation → low similarity → rejection).
  Future<String> _mlKitRecognize(
    List<List<Offset>> strokes,
    String mlLang,
  ) async {
    try {
      // Download model on first use; subsequent calls are instant (cached).
      final available = await _modelManager.isModelDownloaded(mlLang);
      if (!available) {
        await _modelManager.downloadModel(mlLang);
      }

      // Build Ink with synthetic timestamps — ML Kit only uses these to
      // identify stroke boundaries, not for timing accuracy.
      var t = 0;
      final inkStrokes = <Stroke>[];
      for (final stroke in strokes) {
        if (stroke.isEmpty) continue;
        final pts = <StrokePoint>[];
        for (var i = 0; i < stroke.length; i++) {
          pts.add(StrokePoint(x: stroke[i].dx, y: stroke[i].dy, t: t));
          t += 10;
        }
        inkStrokes.add(Stroke()..points = pts);
        t += 500; // inter-stroke gap
      }
      if (inkStrokes.isEmpty) return '';

      final ink = Ink()..strokes = inkStrokes;
      _recognizers[mlLang] ??= DigitalInkRecognizer(languageCode: mlLang);
      final results = await _recognizers[mlLang]!.recognize(ink);

      // ML Kit returns candidates sorted by score (lower = more confident).
      return results.isNotEmpty ? results.first.text : '';
    } catch (_) {
      return '';
    }
  }

  Future<String> _ocr(String imagePath, String lang) async {
    try {
      final text = await FlutterTesseractOcr.extractText(
        imagePath,
        language: lang,
        args: {
          'psm': '7', // treat the image as a single text line
          'preserve_interword_spaces': '1',
        },
      );
      return text;
    } catch (_) {
      return '';
    }
  }

  /// Composite the transparent-ink PNG onto a white background and upscale a
  /// little so thin strokes survive OCR. Returns the temp file path.
  Future<String> _renderForOcr(Uint8List pngBytes) async {
    final src = img.decodePng(pngBytes) ?? img.decodeImage(pngBytes);
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/hw_ocr_${DateTime.now().microsecondsSinceEpoch}.png';

    if (src == null) {
      await File(path).writeAsBytes(pngBytes);
      return path;
    }

    final canvas = img.Image(width: src.width, height: src.height)
      ..clear(img.ColorRgb8(255, 255, 255));
    img.compositeImage(canvas, src); // draw ink (with alpha) over white
    var out = img.grayscale(canvas);
    // Upscale 2× — Tesseract reads ~300 DPI best; on-screen strokes are coarse.
    out = img.copyResize(
      out,
      width: out.width * 2,
      height: out.height * 2,
      interpolation: img.Interpolation.cubic,
    );
    await File(path).writeAsBytes(img.encodePng(out));
    return path;
  }

  /// Lowercase, strip everything that isn't a Latin letter or Indic glyph,
  /// drop spaces — so "Sri Rama" == "srirama".
  String _normalize(String s) {
    final buf = StringBuffer();
    for (final r in s.toLowerCase().runes) {
      final c = String.fromCharCode(r);
      final isLatin = RegExp(r'[a-z]').hasMatch(c);
      final isIndic = r >= 0x0900 && r <= 0x0CFF; // Devanagari..Kannada blocks
      if (isLatin || isIndic) buf.write(c);
    }
    return buf.toString();
  }

  /// Counts phonemic syllable nuclei in a normalised string.
  ///
  /// Latin (romanized): count vowel letters — a e i o u.
  /// Devanagari/Telugu/Kannada: count vowel matras + independent vowels +
  ///   consonants that carry the inherent 'a' (not followed by virama or matra).
  ///
  /// Examples:
  ///   "sri"       → 1    "srirama"     → 3    "sriramaya"   → 4
  ///   "श्री"      → 1    "श्रीराम"    → 3    "श्रीरामाय"  → 4
  int _syllableCount(String normalized) {
    if (normalized.isEmpty) return 0;
    final runes = normalized.runes.toList();
    final first = runes.first;

    // ── Latin path ─────────────────────────────────────────────────────────
    if (first < 0x0900) {
      return runes.where((r) =>
          r == 0x61 || r == 0x65 || r == 0x69 || r == 0x6F || r == 0x75).length;
    }

    // ── Indic path: select script constants ────────────────────────────────
    final int virama;
    final int matraStart, matraEnd;
    final int ivStart, ivEnd; // independent vowels
    final int csStart, csEnd; // consonants

    if (first <= 0x097F) {
      // Devanagari
      virama = 0x094D;
      matraStart = 0x093E; matraEnd = 0x094C;
      ivStart = 0x0905;    ivEnd = 0x0914;
      csStart = 0x0915;    csEnd = 0x0939;
    } else if (first <= 0x0C7F) {
      // Telugu
      virama = 0x0C4D;
      matraStart = 0x0C3E; matraEnd = 0x0C4C;
      ivStart = 0x0C05;    ivEnd = 0x0C14;
      csStart = 0x0C15;    csEnd = 0x0C39;
    } else {
      // Kannada
      virama = 0x0CCD;
      matraStart = 0x0CBE; matraEnd = 0x0CCC;
      ivStart = 0x0C85;    ivEnd = 0x0C94;
      csStart = 0x0C95;    csEnd = 0x0CB9;
    }

    bool isMatra(int r) => r >= matraStart && r <= matraEnd;

    var count = 0;
    for (var i = 0; i < runes.length; i++) {
      final r = runes[i];
      if (isMatra(r) || (r >= ivStart && r <= ivEnd)) {
        count++;
      } else if (r >= csStart && r <= csEnd) {
        // Consonant contributes a syllable only when not followed by virama or matra
        final next = i + 1 < runes.length ? runes[i + 1] : -1;
        if (next != virama && !isMatra(next)) count++;
      }
    }
    return count;
  }

  double _similarity(String got, String want) {
    if (want.isEmpty) return got.isEmpty ? 1 : 0;
    if (got.isEmpty) return 0;
    final dist = _infixDistance(want, got);
    return (1 - dist / want.length).clamp(0.0, 1.0);
  }

  int _infixDistance(String pat, String text) {
    final m = pat.length, n = text.length;
    var prev = List<int>.filled(n + 1, 0); // row 0 = start anywhere in text
    var curr = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      curr[0] = i; // must consume all of pat
      for (var j = 1; j <= n; j++) {
        final cost = pat.codeUnitAt(i - 1) == text.codeUnitAt(j - 1) ? 0 : 1;
        final del = prev[j] + 1;
        final ins = curr[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        curr[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    var best = prev[0]; // end anywhere in text
    for (var j = 1; j <= n; j++) {
      if (prev[j] < best) best = prev[j];
    }
    return best;
  }
}
