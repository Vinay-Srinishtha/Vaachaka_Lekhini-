import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Compares two handwriting PNG images using a multi-signal approach
/// that tolerates natural variation in writing style, stroke thickness,
/// minor positional shifts and proportion differences — while enforcing
/// that the user wrote the *complete* word/phrase, not just a fragment.
///
/// ## Completeness gates (checked first — return 0.0 on failure)
///
/// Before any similarity signal is computed two hard gates are applied:
///
/// * **Ink-volume gate**: the user's total ink pixel count must be at least
///   [_minInkRatio] × the reference's count (default 40 %).  Writing just
///   one letter of a multi-letter word fails this gate immediately.
///
/// * **Spatial-coverage gate**: the number of zones where the user has
///   meaningful ink must cover at least [_minZoneCoverage] × the zones the
///   reference occupies (default 50 %).  This rejects ink concentrated in
///   one corner even if the total volume happens to pass.
///
/// ## Similarity signals (only reached when both gates pass)
///
/// 1. **Dilated Jaccard** (weight 0.40)
///    Both grids are morphologically dilated (each ink pixel expands to its
///    8-neighbours) before computing IoU.  Tolerates ±1 px positional jitter
///    and stroke-width variation.
///
/// 2. **Zone density cosine** (weight 0.40)
///    36-element zone-density vectors compared with cosine similarity.
///    Captures "ink in roughly the same regions" without pixel alignment.
///    Tolerates different letter forms with similar overall distribution.
///    Weight increased vs dilated Jaccard because Devanagari script has
///    complex spatial structure that cosine captures more robustly.
///
/// 3. **Coarse Jaccard** (weight 0.20)
///    8×8 resolution Jaccard for overall shape silhouette match.
///
/// Final score = 0.40 × dilatedJaccard + 0.40 × zoneCosine + 0.20 × coarseJaccard
///
/// Range: 0.0 (nothing matches / gates failed) → 1.0 (perfect match).
/// A score ≥ 0.25 (configurable via RemoteConfig) is considered accepted.
class HandwritingComparator {
  HandwritingComparator._();

  static const int _gridSize = 48;   // main grid resolution (was 32 — higher res for Devanagari)
  static const int _coarseSize = 8;  // coarse grid resolution
  static const int _zoneCount = 6;   // 6×6 zones (was 4×4 — finer spatial encoding)
  static const int _zoneSize = _gridSize ~/ _zoneCount; // 8 px per zone edge

  // ── Completeness gates ────────────────────────────────────────────────────
  /// User ink must be ≥ 40 % of reference ink (raised from 35 %).
  /// Ensures a partial letter/stroke can't pass as the full word.
  static const double _minInkRatio = 0.40;

  /// User ink must occupy ≥ 50 % of the zones the reference uses (raised from 45 %).
  /// Ensures the writing spans the full spatial extent of the reference.
  static const double _minZoneCoverage = 0.50;

  /// A zone is considered "occupied" when its ink fraction exceeds this.
  static const double _zoneOccupiedThreshold = 0.04;

  // ── Blend weights (must sum to 1.0) ──────────────────────────────────────
  static const double _wDilated = 0.40;
  static const double _wZone    = 0.40;
  static const double _wCoarse  = 0.20;

  /// Compares [userPng] against [referencePng].
  /// Returns a similarity score from 0.0 to 1.0.
  /// Returns 0.0 immediately if the completeness gates are not met.
  static Future<double> compare(
    Uint8List userPng,
    Uint8List referencePng,
  ) async {
    // Decode both images at two resolutions in parallel.
    final results = await Future.wait([
      _toGrid(userPng,       _gridSize),
      _toGrid(referencePng,  _gridSize),
      _toGrid(userPng,       _coarseSize),
      _toGrid(referencePng,  _coarseSize),
    ]);

    final userFine   = results[0];
    final refFine    = results[1];
    final userCoarse = results[2];
    final refCoarse  = results[3];

    // ── Zone density (needed by both gates and signal 2) ──────────────────
    final userDensity = _zoneDensity(userFine);
    final refDensity  = _zoneDensity(refFine);

    // ── Gate 1: ink volume ────────────────────────────────────────────────
    final userInk = userFine.where((p) => p).length;
    final refInk  = refFine.where((p) => p).length;
    if (refInk > 0 && userInk < refInk * _minInkRatio) return 0.0;

    // ── Gate 2: spatial coverage ──────────────────────────────────────────
    final userZones = userDensity.where((d) => d > _zoneOccupiedThreshold).length;
    final refZones  = refDensity.where((d) => d > _zoneOccupiedThreshold).length;
    if (refZones > 0 && userZones < refZones * _minZoneCoverage) return 0.0;

    // ── Signal 1: Dilated Jaccard ─────────────────────────────────────────
    final dilatedUser  = _dilate(userFine, _gridSize);
    final dilatedRef   = _dilate(refFine,  _gridSize);
    final dilatedScore = _jaccard(dilatedUser, dilatedRef);

    // ── Signal 2: Zone density cosine ─────────────────────────────────────
    final cosineScore = _cosine(userDensity, refDensity);

    // ── Signal 3: Coarse Jaccard ──────────────────────────────────────────
    final coarseScore = _jaccard(userCoarse, refCoarse);

    return _wDilated * dilatedScore
         + _wZone    * cosineScore
         + _wCoarse  * coarseScore;
  }

  // ─── Morphological dilation: 3×3 structuring element ──────────────────────
  /// Expands each ink pixel to all 8 immediate neighbours.
  /// Smooths over ±1 pixel misalignment and stroke-width variation.
  static List<bool> _dilate(List<bool> grid, int size) {
    final out = List<bool>.filled(size * size, false);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (!grid[y * size + x]) continue;
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
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
  /// Returns a vector of ink fractions, one per zone, in row-major order.
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
  /// true = ink (alpha > 50), false = transparent background.
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
      // RGBA — pixel is ink if alpha > 50
      grid.add(byteData.getUint8(i + 3) > 50);
    }
    return grid;
  }
}
