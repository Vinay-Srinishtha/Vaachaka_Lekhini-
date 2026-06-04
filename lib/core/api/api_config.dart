import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Resolves the base URL of the KVL admin API at runtime.
///
/// Precedence:
///   1. `--dart-define=KVL_API_BASE=<url>` build flag
///   2. Platform-aware localhost mapping (Android emulator vs everything else)
///
/// All paths under `/api/v1/*` are appended to this base.
abstract final class ApiConfig {
  static const String _override = String.fromEnvironment('KVL_API_BASE');

  /// Dev fallback. The SvelteKit dev server defaults to port 5173.
  static const int _devPort = 5173;

  /// Base URL — never has a trailing slash.
  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    if (_override.isNotEmpty) return _stripTrailingSlash(_override);
    if (kIsWeb) return 'http://localhost:$_devPort';
    if (Platform.isAndroid) return 'http://10.0.2.2:$_devPort';
    // iOS sim, macOS, Linux, Windows can hit localhost directly.
    return 'http://localhost:$_devPort';
  }

  static String _stripTrailingSlash(String s) =>
      s.endsWith('/') ? s.substring(0, s.length - 1) : s;
}
