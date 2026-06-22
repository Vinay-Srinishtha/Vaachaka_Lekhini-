import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
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
  final String recognized; // best-matching OCR output (debug/feedback)
  final String expected; // the target it was closest to
}

/// Fully offline handwriting verification using bundled Tesseract traineddata.
///
/// Renders the user's strokes to a clean black-on-white image, OCRs it in the
/// relevant script(s), then fuzzy-matches the text against the expected mantra
/// spelling. A wrong word (e.g. "Ravi" vs "Sri Rama") is recognised as itself
/// and falls far below the similarity threshold, so it is rejected — unlike the
/// old shape-only matcher that accepted any consistent scribble.
class HandwritingRecognizer {
  HandwritingRecognizer._();
  static final HandwritingRecognizer instance = HandwritingRecognizer._();

  /// Minimum normalised similarity (0..1) to accept. Tuned to tolerate minor
  /// recognition slips / spelling variation while still rejecting other words.
  /// (e.g. "श्री राम" misread as "श्री शम" ≈ 0.71 → accept; "Ravi" ≈ 0.15 → reject.)
  static const double _minSimilarity = 0.50;

  /// Recognise [pngBytes] (transparent background, dark ink) and decide whether
  /// it matches any of [candidates].
  Future<HandwritingResult> check({
    required Uint8List pngBytes,
    required List<ExpectedWriting> candidates,
  }) async {
    final imagePath = await _renderForOcr(pngBytes);

    // OCR once per distinct script, then match each candidate to its script.
    final langs = {for (final c in candidates) c.tessLang};
    final recognisedByLang = <String, String>{};
    for (final lang in langs) {
      recognisedByLang[lang] = await _ocr(imagePath, lang);
    }

    var bestSim = 0.0;
    var bestRecognised = '';
    var bestExpected = '';
    for (final c in candidates) {
      final got = _normalize(recognisedByLang[c.tessLang] ?? '');
      final want = _normalize(c.text);
      if (want.isEmpty) continue;
      final sim = _similarity(got, want);
      if (sim > bestSim) {
        bestSim = sim;
        bestRecognised = recognisedByLang[c.tessLang] ?? '';
        bestExpected = c.text;
      }
    }

    // Clean up the temp image; ignore failures.
    try {
      await File(imagePath).delete();
    } catch (_) {}

    return HandwritingResult(
      accepted: bestSim >= _minSimilarity,
      similarity: bestSim,
      recognized: bestRecognised,
      expected: bestExpected,
    );
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

  /// Lowercase, strip everything that isn't a letter mark (keeps Indic glyphs
  /// and Latin letters), drop spaces — so "Sri Rama" == "srirama".
  String _normalize(String s) {
    final buf = StringBuffer();
    for (final r in s.toLowerCase().runes) {
      final c = String.fromCharCode(r);
      // Keep Latin letters and any non-ASCII letter/mark (Devanagari, Telugu,
      // Kannada). Drop digits, punctuation, whitespace, control chars.
      final isLatin = RegExp(r'[a-z]').hasMatch(c);
      final isIndic = r >= 0x0900 && r <= 0x0CFF; // Devanagari..Kannada blocks
      if (isLatin || isIndic) buf.write(c);
    }
    return buf.toString();
  }

  /// Similarity of OCR output [got] to the expected word [want], in 0..1.
  /// Uses an *infix* match: the expected word only has to align well with the
  /// best-fitting region of the OCR text, so stray marks / noise around the
  /// word don't drag the score down. Normalised by the expected length.
  double _similarity(String got, String want) {
    if (want.isEmpty) return got.isEmpty ? 1 : 0;
    if (got.isEmpty) return 0;
    final dist = _infixDistance(want, got);
    return (1 - dist / want.length).clamp(0.0, 1.0);
  }

  /// Minimum edit distance to match [pat] against the best contiguous region
  /// of [text]. Leading/trailing characters of [text] are free (cost 0), so
  /// OCR noise surrounding the word is not penalised.
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
