import 'dart:typed_data';
import 'dart:ui' as ui;

/// Compares two handwriting PNG images using a downsampled pixel grid.
///
/// Both images are scaled down to [_gridSize]×[_gridSize] pixels.
/// A pixel is considered "ink" if its alpha channel > 50 (transparent
/// background exports from the signature canvas have alpha=0 for empty
/// pixels and alpha=255 for drawn strokes).
///
/// Score formula:
///   score = (ink pixels present in BOTH user & reference) / (ink pixels in reference)
///
/// Range: 0.0 (nothing matches) → 1.0 (perfect match).
/// A score ≥ 0.40 (configurable via RemoteConfig) is considered accepted.
class HandwritingComparator {
  HandwritingComparator._();

  static const int _gridSize = 32;

  /// Compares [userPng] against [referencePng].
  /// Returns a similarity score from 0.0 to 1.0.
  static Future<double> compare(
    Uint8List userPng,
    Uint8List referencePng,
  ) async {
    final userGrid = await _toGrid(userPng);
    final refGrid = await _toGrid(referencePng);

    int refInk = 0;
    int intersection = 0;

    for (int i = 0; i < _gridSize * _gridSize; i++) {
      if (refGrid[i]) {
        refInk++;
        if (userGrid[i]) intersection++;
      }
    }

    if (refInk == 0) return 0.0;
    return intersection / refInk;
  }

  /// Decodes [png] and downsamples to a [_gridSize]×[_gridSize] boolean grid.
  /// true = ink, false = background / transparent.
  static Future<List<bool>> _toGrid(Uint8List png) async {
    final codec = await ui.instantiateImageCodec(
      png,
      targetWidth: _gridSize,
      targetHeight: _gridSize,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData == null) return List.filled(_gridSize * _gridSize, false);

    final grid = <bool>[];
    for (int i = 0; i < byteData.lengthInBytes; i += 4) {
      // RGBA — pixel is ink if alpha > 50 (ignores transparent background)
      final alpha = byteData.getUint8(i + 3);
      grid.add(alpha > 50);
    }
    return grid;
  }
}
