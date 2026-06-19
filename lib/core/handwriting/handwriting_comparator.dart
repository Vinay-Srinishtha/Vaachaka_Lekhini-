import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Compares two handwriting PNG images using a multi-signal approach
/// that tolerates natural variation in writing style, stroke thickness,
/// positional shifts (writing slightly left / right / up / down) — while
/// rejecting garbage inputs such as straight lines, scribbles, commas,
/// blackouts, and empty canvases.
///
/// ## Hard gates (checked in order — any failure returns 0.0)
///
/// 1. **Empty gate**: user drew nothing (< 1 % ink pixels) → reject.
/// 2. **Blackout gate**: user filled > 70 % of the canvas → reject.
/// 3. **Straight-line gate**: user ink spans < 5 rows OR < 5 columns in the
///    48-pixel grid → reject.  Catches horizontal/vertical strokes, dashes,
///    and single commas.
/// 4. **Ink-volume gate**: user ink < 40 % of reference ink → reject.
///    Ensures a partial letter/stroke can't pass as the full word.
/// 5. **Spatial-coverage gate**: user ink occupies < 50 % of the zones the
///    reference uses → reject.  Catches ink bunched in one corner.
///
/// ## Similarity signals (only reached when all gates pass)
///
/// 1. **Dilated Jaccard** (weight 0.45) — both grids dilated with a 5×5
///    structuring element (radius 2) before IoU.  Tolerates ±2 px positional
///    shift so writing a character slightly down/left/right still scores well.
///
/// 2. **Zone density cosine** (weight 0.35) — 36-element zone-density vectors
///    compared with cosine similarity.  Captures spatial distribution without
///    requiring pixel alignment.
///
/// 3. **Coarse Jaccard** (weight 0.20) — 8×8 silhouette match for overall
///    shape agreement.
///
/// Final score = 0.45 × dilatedJaccard + 0.35 × zoneCosine + 0.20 × coarseJaccard
///
/// Range: 0.0 (gate failed / no match) → 1.0 (perfect match).
/// A score ≥ 0.35 (configurable via RemoteConfig) is considered accepted.
class HandwritingComparator {
  HandwritingComparator._();

  static const int _gridSize   = 48;
  static const int _coarseSize = 8;
  static const int _zoneCount  = 6;
  static const int _zoneSize   = _gridSize ~/ _zoneCount;

  // ── Gate thresholds ───────────────────────────────────────────────────────

  /// Reject if user ink is below this fraction of total pixels (empty canvas).
  static const double _minAbsoluteInkFraction = 0.01;

  /// Reject if user ink exceeds this fraction of total pixels (blackout).
  static const double _maxInkFraction = 0.70;

  /// Dense input is only treated as blackout when it greatly exceeds the
  /// reference ink. This keeps valid dense reference shapes comparable.
  static const double _maxInkRatio = 2.50;

  /// Minimum number of distinct rows with ink in the 48-px grid.
  /// A horizontal line or dash typically spans ≤ 3 rows.
  static const int _minRowSpread = 5;

  /// Minimum number of distinct columns with ink in the 48-px grid.
  /// A vertical line typically spans ≤ 3 columns.
  static const int _minColSpread = 5;

  /// User ink must be ≥ 40 % of reference ink.
  static const double _minInkRatio = 0.40;

  /// User ink must occupy ≥ 50 % of the zones the reference uses.
  static const double _minZoneCoverage = 0.50;

  /// A zone is "occupied" when its ink fraction exceeds this.
  static const double _zoneOccupiedThreshold = 0.04;

  // ── Blend weights (must sum to 1.0) ──────────────────────────────────────
  static const double _wDilated = 0.45;
  static const double _wZone    = 0.35;
  static const double _wCoarse  = 0.20;

  /// Dilation radius in pixels.  Radius 2 → 5×5 neighbourhood → tolerates
  /// writing shifted up to ~2 px in any direction.
  static const int _dilateRadius = 2;

  // ─────────────────────────────────────────────────────────────────────────

  /// Compares [userPng] against [referencePng].
  /// Returns a similarity score 0.0–1.0.  Returns 0.0 when any hard gate
  /// fails (empty, blackout, straight line, too little ink, wrong coverage).
  static Future<double> compare(
    Uint8List userPng,
    Uint8List referencePng,
  ) async {
    final results = await Future.wait([
      _toGrid(userPng,      _gridSize),
      _toGrid(referencePng, _gridSize),
      _toGrid(userPng,      _coarseSize),
      _toGrid(referencePng, _coarseSize),
    ]);

    final userFine   = results[0];
    final refFine    = results[1];
    final userCoarse = results[2];
    final refCoarse  = results[3];

    final totalPixels = _gridSize * _gridSize;
    final userInk = userFine.where((p) => p).length;
    final refInk  = refFine.where((p) => p).length;

    // ── Gate 1: empty canvas ──────────────────────────────────────────────
    if (userInk < totalPixels * _minAbsoluteInkFraction) return 0.0;

    // ── Gate 2: blackout ──────────────────────────────────────────────────
    final userInkFraction = userInk / totalPixels;
    if (userInkFraction > _maxInkFraction &&
        (refInk == 0 || userInk > refInk * _maxInkRatio)) {
      return 0.0;
    }

    // ── Gate 3: straight line / comma / dot ───────────────────────────────
    final spread = _inkSpread(userFine, _gridSize);
    if (spread.rows < _minRowSpread || spread.cols < _minColSpread) return 0.0;

    // ── Gate 4: ink volume vs reference ───────────────────────────────────
    if (refInk > 0 && userInk < refInk * _minInkRatio) return 0.0;

    // ── Gate 5: spatial coverage ──────────────────────────────────────────
    final userDensity = _zoneDensity(userFine);
    final refDensity  = _zoneDensity(refFine);
    final userZones = userDensity.where((d) => d > _zoneOccupiedThreshold).length;
    final refZones  = refDensity.where((d) => d > _zoneOccupiedThreshold).length;
    if (refZones > 0 && userZones < refZones * _minZoneCoverage) return 0.0;

    // ── Signal 1: Dilated Jaccard (radius 2 → ±2 px shift tolerance) ─────
    final dilatedUser  = _dilate(userFine, _gridSize);
    final dilatedRef   = _dilate(refFine,  _gridSize);
    final dilatedScore = _jaccard(dilatedUser, dilatedRef);

    // ── Signal 2: Zone density cosine ─────────────────────────────────────
    final cosineScore = _cosine(userDensity, refDensity);

    // ── Signal 3: Coarse Jaccard ──────────────────────────────────────────
    final coarseScore = _jaccard(userCoarse, refCoarse);

    return (_wDilated * dilatedScore
          + _wZone    * cosineScore
          + _wCoarse  * coarseScore)
        .clamp(0.0, 1.0);
  }

  // ─── Ink spread: count distinct rows and columns that have any ink ─────────
  static ({int rows, int cols}) _inkSpread(List<bool> grid, int size) {
    final rows = <int>{};
    final cols = <int>{};
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (grid[y * size + x]) {
          rows.add(y);
          cols.add(x);
        }
      }
    }
    return (rows: rows.length, cols: cols.length);
  }

  // ─── Morphological dilation: (2r+1)×(2r+1) structuring element ────────────
  /// Expands each ink pixel to all neighbours within [_dilateRadius].
  /// Radius 2 tolerates up to ±2 px positional shift in any direction.
  static List<bool> _dilate(List<bool> grid, int size) {
    final out = List<bool>.filled(size * size, false);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (!grid[y * size + x]) continue;
        for (int dy = -_dilateRadius; dy <= _dilateRadius; dy++) {
          for (int dx = -_dilateRadius; dx <= _dilateRadius; dx++) {
            final ny = y + dy;
            final nx = x + dx;
            if (ny >= 0 && ny < size && nx >= 0 && nx < size) {
              out[ny * size + nx] = true;
            }
          }
        }
      }
    }
    return out;
  }

  // ─── Jaccard / IoU on boolean grids ────────────────────────────────────────
  static double _jaccard(List<bool> a, List<bool> b) {
    int aInk = 0, bInk = 0, inter = 0;
    for (int i = 0; i < a.length; i++) {
      if (a[i]) aInk++;
      if (b[i]) bInk++;
      if (a[i] && b[i]) inter++;
    }
    final union = aInk + bInk - inter;
    if (union == 0) return 0.0;
    return inter / union;
  }

  // ─── Zone ink density: _zoneCount × _zoneCount zones ──────────────────────
  static List<double> _zoneDensity(List<bool> grid) {
    final zones = List<double>.filled(_zoneCount * _zoneCount, 0.0);
    const area = _zoneSize * _zoneSize;
    for (int zy = 0; zy < _zoneCount; zy++) {
      for (int zx = 0; zx < _zoneCount; zx++) {
        int ink = 0;
        for (int py = 0; py < _zoneSize; py++) {
          for (int px = 0; px < _zoneSize; px++) {
            final y = zy * _zoneSize + py;
            final x = zx * _zoneSize + px;
            if (grid[y * _gridSize + x]) ink++;
          }
        }
        zones[zy * _zoneCount + zx] = ink / area;
      }
    }
    return zones;
  }

  // ─── Cosine similarity for zone-density vectors ────────────────────────────
  static double _cosine(List<double> a, List<double> b) {
    double dot = 0.0, magA = 0.0, magB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot  += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    final denom = math.sqrt(magA) * math.sqrt(magB);
    if (denom < 1e-9) return 0.0;
    return (dot / denom).clamp(0.0, 1.0);
  }

  // ─── PNG decode → boolean ink grid ────────────────────────────────────────
  /// Decodes [png] and downsamples to [size]×[size] boolean grid.
  /// true = ink (alpha > 50), false = transparent/background.
  static Future<List<bool>> _toGrid(Uint8List png, int size) async {
    final codec = await ui.instantiateImageCodec(
      png,
      targetWidth: size,
      targetHeight: size,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData == null) return List.filled(size * size, false);

    final grid = <bool>[];
    for (int i = 0; i < byteData.lengthInBytes; i += 4) {
      grid.add(byteData.getUint8(i + 3) > 50);
    }
    return grid;
  }
}
