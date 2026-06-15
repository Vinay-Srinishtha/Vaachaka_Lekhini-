import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:vachika_lekhini/core/handwriting/handwriting_comparator.dart';

/// Generates a PNG by drawing on a Canvas.
///
/// The [draw] callback receives a 100×100 canvas. Use it to paint shapes that
/// represent ink vs. blank areas.  The resulting PNG is what the comparator
/// actually receives at runtime (exported from SignatureController or a file).
Future<Uint8List> _makePng(void Function(ui.Canvas canvas) draw) async {
  const size = 100.0;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(
    recorder,
    ui.Rect.fromLTWH(0, 0, size, size),
  );
  // Transparent background (no background fill — ink pixels only)
  draw(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return byteData!.buffer.asUint8List();
}

// ── Shared helpers ────────────────────────────────────────────────────────────

final _blackPaint = ui.Paint()
  ..color = const ui.Color(0xFF000000)
  ..style = ui.PaintingStyle.fill;

/// A filled black square covering the entire 100×100 canvas.
Future<Uint8List> _fullSquare() => _makePng(
      (c) => c.drawRect(const ui.Rect.fromLTWH(0, 0, 100, 100), _blackPaint),
    );

/// A filled black square in the left half only (0–50 × 0–100).
Future<Uint8List> _leftHalf() => _makePng(
      (c) => c.drawRect(const ui.Rect.fromLTWH(0, 0, 50, 100), _blackPaint),
    );

/// A filled black square in the top-left quadrant only (0–50 × 0–50).
Future<Uint8List> _topLeftQuadrant() => _makePng(
      (c) => c.drawRect(const ui.Rect.fromLTWH(0, 0, 50, 50), _blackPaint),
    );

/// Completely transparent / empty canvas.
Future<Uint8List> _empty() => _makePng((_) {});

/// A thin diagonal line (simulates a minimal scribble).
Future<Uint8List> _thinLine() => _makePng((c) {
      c.drawLine(
        const ui.Offset(0, 0),
        const ui.Offset(100, 100),
        ui.Paint()
          ..color = const ui.Color(0xFF000000)
          ..strokeWidth = 2,
      );
    });

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HandwritingComparator — completeness gates', () {
    test('empty user vs non-empty reference → 0.0 (ink gate)', () async {
      final ref = await _fullSquare();
      final user = await _empty();
      final score = await HandwritingComparator.compare(user, ref);
      expect(score, 0.0,
          reason: 'Empty user canvas has no ink — ink-volume gate must fail');
    });

    test('thin-line user vs full-square reference → 0.0 (ink gate)', () async {
      final ref = await _fullSquare();
      final user = await _thinLine();
      final score = await HandwritingComparator.compare(user, ref);
      expect(score, 0.0,
          reason: 'A single thin line has far less ink than a full square');
    });

    test('top-left-only user vs full-square reference → 0.0 (zone gate)', () async {
      // The user's ink is concentrated in one quadrant — fails spatial-coverage gate
      // even though the ink volume (25 % of reference) fails the ink gate too.
      final ref = await _fullSquare();
      final user = await _topLeftQuadrant();
      final score = await HandwritingComparator.compare(user, ref);
      expect(score, 0.0,
          reason:
              'Top-left quadrant covers < 50 % of spatial zones — zone gate must fail');
    });

    test('both images empty → 0.0 (no ink in reference)', () async {
      final img = await _empty();
      final score = await HandwritingComparator.compare(img, img);
      // refInk == 0 so gate never fires, but signals produce 0.0 too
      expect(score, lessThanOrEqualTo(0.01));
    });
  });

  group('HandwritingComparator — similarity signals', () {
    test('identical non-trivial images → score near 1.0', () async {
      final img = await _fullSquare();
      final score = await HandwritingComparator.compare(img, img);
      expect(score, greaterThan(0.90),
          reason: 'Identical images should produce a near-perfect score');
    });

    test('left half vs full square — passes gates, score > 0', () async {
      final ref = await _fullSquare();
      final user = await _leftHalf();
      final score = await HandwritingComparator.compare(user, ref);
      // Left half has 50 % ink (≥ _minInkRatio=40 %) and covers all rows so
      // spatial zones span ≥ 50 % — both gates should pass.
      expect(score, greaterThan(0.0),
          reason: 'Left half passes both gates; should produce a positive score');
      // But it won't be high — user is missing the right half
      expect(score, lessThan(0.75),
          reason: 'Missing right half should lower the score significantly');
    });

    test('score is symmetric: compare(a,b) ≈ compare(b,a)', () async {
      final a = await _leftHalf();
      final b = await _fullSquare();
      final ab = await HandwritingComparator.compare(a, b);
      final ba = await HandwritingComparator.compare(b, a);
      // Not required to be exactly equal (gates are asymmetric) but within ~0.10
      expect((ab - ba).abs(), lessThan(0.20),
          reason: 'Scores should be roughly symmetric when both pass gates');
    });
  });

  group('HandwritingComparator — parameter regression', () {
    // These tests document the expected score ranges for known inputs.
    // Re-run them after any parameter change — if scores drift significantly
    // outside these bands, review the change carefully.

    test('identical image scores ≥ 0.90', () async {
      final img = await _leftHalf();
      final score = await HandwritingComparator.compare(img, img);
      expect(score, greaterThanOrEqualTo(0.90));
    });

    test('left-half vs full-square score in [0.20, 0.65]', () async {
      final ref = await _fullSquare();
      final user = await _leftHalf();
      final score = await HandwritingComparator.compare(user, ref);
      expect(score, greaterThanOrEqualTo(0.20));
      expect(score, lessThanOrEqualTo(0.65));
    });
  });
}
