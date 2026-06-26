import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads an image URL to a content-addressed temp file.
/// If the file already exists (from a prior call) it returns the path
/// instantly without re-downloading. Returns null if the URL is empty or
/// the download fails.
Future<String?> cachedShareImagePath(String url) async {
  if (url.isEmpty) return null;
  try {
    final tmpDir = await getTemporaryDirectory();
    final ext = url.contains('.png') ? 'png' : 'jpg';
    final hash = url.hashCode.toRadixString(36);
    final file = File('${tmpDir.path}/share_img_$hash.$ext');
    if (!file.existsSync()) {
      await Dio().download(url, file.path);
    }
    return file.path;
  } catch (_) {
    return null;
  }
}
