import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Extracts the bundled Hindi Vosk model on first launch and returns the
/// absolute path to its directory. Idempotent — re-uses the extracted copy.
class VoskModelLoader {
  static const _assetPath = 'assets/models/vosk-model-small-hi-0.22.zip';
  static const _dirName = 'vosk-model-small-hi-0.22';

  Future<String> ensureExtracted() async {
    final support = await getApplicationSupportDirectory();
    final modelDir = Directory('${support.path}/$_dirName');
    if (modelDir.existsSync() && modelDir.listSync().isNotEmpty) {
      return modelDir.path;
    }
    modelDir.createSync(recursive: true);
    final bytes = await rootBundle.load(_assetPath);
    final archive = ZipDecoder().decodeBytes(bytes.buffer.asUint8List());
    extractArchiveToDisk(archive, support.path);
    return modelDir.path;
  }
}
