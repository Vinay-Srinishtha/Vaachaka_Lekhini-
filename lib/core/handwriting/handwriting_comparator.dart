import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Compares two handwriting PNG images using a multi-signal approach
/// that tolerates natural variation in writing style, stroke thickness,
/// minor positional shifts and proportion differences.
///
/// Three signals are blended:
///
/// 1. **Dilated Jaccard** (weight 0.45)
///    Both grids are morphologically dilated (each ink pixel expands to its
///    8-neighbours) before computing IoU.  This makes the comparator blind to
///    ±1 px positional jitter and stroke-width variation.
///
/// 2. **Zone density cosine** (weight 0.35)
///    The 32×32 grid is divided into a 4×4 array of 8×8-pixel zones.  For
///    each zone the ink fraction (0–1) is computed, producing a 16-element
///    density vector.  Cosine similarity between the two vectors captures
///    "ink in roughly the same regions" without demanding pixel alignment.
///    This tolerates different letter forms that share the same overall
///    stroke distribution.
///
/// 3. **Coarse Jaccard** (weight 0.20)
///    Images are additionally decoded at 8×8 resolution.  Jaccard at this
///    scale represents the overall shape silhouette and catches cases where
///    the fine-grained signals might agree by coincidence.
///
/// Final score = 0.45 × dilatedJaccard + 0.35 × zoneCosine + 0.20 × coarseJaccard
///
/// Range: 0.0 (nothing matches) → 1.0 (perfect match).
/// A score ≥ 0.20 (configurable via RemoteConfig) is considered accepted.
class HandwritingComparator {
  HandwritingComparator._();

  static const int _gridSize = 32;   // main grid resolution
  static const int _coarseSize = 8;  // coarse grid resolution
  static const int _zoneCount = 4;   // 4×4 zones in the main grid
  static const int _zoneSize = _gridSize ~/ _zoneCount; // 8 px per zone edge

  // Blend weights (must sum to 1.0)
  static const double _wDilated = 0.45;
  static const double _wZone    = 0.35;
  static const double _wCoarse  = 0.20;

  /// Compares [userPng] against [referencePng].
  /// Returns a similarity score from 0.0 to 1.0.
  static Future<double> compare(
    Uint8List userPng,
    Uint8List referencePng,
  ) async {
    // Decode both images at two resolutions in parallel.
    final results = await Future.wait([
      _toGrid(userPng,  _gridSize),
      _toGrid(referencePng, _gridSize),
      _toGrid(userPng,  _coarseSize),
      _toGrid(referencePng, _coarseSize),
    ]);

    final userFine   = results[0];
    final refFine    = results[1];
    final userCoarse = results[2];
    final refCoarse  = results[3];

    // 1. Dilated Jaccard — tolerates positional/thickness variation
    final dilatedUser = _dilate(userFine,  _gridSize);
    final dilatedRef  = _dilate(refFine,   _gridSize);
    final dilatedScore = _jaccard(dilatedUser, dilatedRef);

    // 2. Zone density cosine — tolerates style & proportion differences
    final userDensity = _zoneDensity(userFine);
    final refDensity  = _zoneDensity(refFine);
    final cosineScore = _cosine(userDensity, refDensity);

    // 3. Coarse Jaccard — overall shape silhouette match
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
