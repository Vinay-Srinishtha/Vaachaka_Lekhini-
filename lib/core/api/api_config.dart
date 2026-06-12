import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Resolves the base URL of the KVL admin API at runtime.
///
/// Precedence:
///   1. `--dart-define=KVL_API_BASE=<url>` build flag
///   2. Production Vercel API for release builds
///   3. Platform-aware local development mapping
///
/// All paths under `/api/v1/*` are appended to this base.
abstract final class ApiConfig {
  static const String _override = String.fromEnvironment('KVL_API_BASE');
  static const String _productionBaseUrl =
      'https://vaachaka-lekhini.vercel.app';

  /// Dev fallback. The SvelteKit dev server defaults to port 5173.
  static const int _devPort = 5173;

  /// Base URL — never has a trailing slash.
  static final String baseUrl = _resolveBaseUrl();

  /// Your Mac's WiFi IP — phone must be on the same network.
  /// Update this if your router assigns a different IP.
  static const String _devHost = '192.168.29.35';

  static String _resolveBaseUrl() {
    if (_override.isNotEmpty) return _stripTrailingSlash(_override);
    if (kReleaseMode) return _productionBaseUrl;
    if (kIsWeb) return 'http://localhost:$_devPort';
    // Both emulator (10.0.2.2) and real device need the Mac's LAN IP.
    // Real device on WiFi can't use localhost or 10.0.2.2.
    if (Platform.isAndroid) return 'http://$_devHost:$_devPort';
    return 'http://localhost:$_devPort';
  }

  static String _stripTrailingSlash(String s) =>
      s.endsWith('/') ? s.substring(0, s.length - 1) : s;
}
