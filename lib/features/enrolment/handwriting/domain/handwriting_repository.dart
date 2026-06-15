import 'dart:typed_data';

import 'handwriting_asset.dart';

abstract class HandwritingRepository {
  Future<List<HandwritingAsset>> listForProfile(String profileId);
  Future<HandwritingAsset> savePng({
    required String profileId,
    required HandwritingMode mode,
    required Uint8List bytes,
    String? mantraId,
  });
  Future<HandwritingAsset> registerExisting({
    required String profileId,
    required HandwritingMode mode,
    required String filePath,
    String? mantraId,
  });
  Future<HandwritingAsset> recordDefaultFontChoice({required String profileId, String? mantraId});
  Future<void> delete(String id);

  /// Saves [bytes] and ensures at most [maxSamples] practice PNGs are kept
  /// for this (profileId, mantraId) pair. When over the cap, one existing
  /// sample is evicted at random so the pool stays fresh rather than always
  /// dropping the oldest.
  Future<HandwritingAsset> savePngCapped({
    required String profileId,
    required String mantraId,
    required Uint8List bytes,
    int maxSamples = 10,
  });
}
