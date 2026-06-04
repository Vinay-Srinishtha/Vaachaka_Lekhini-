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
}
