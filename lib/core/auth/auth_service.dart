import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import 'auth_storage.dart';
import 'auth_tokens.dart';

/// All Account-level auth flows hit /api/v1/auth/*.
///
/// The returned tokens are persisted via [AuthStorage]; the bearer
/// interceptor on [ApiClient] reads them on every protected call and
/// refreshes when the access token expires.
class AuthService {
  AuthService({required ApiClient api, required AuthStorage storage})
      : _api = api,
        _storage = storage;

  final ApiClient _api;
  final AuthStorage _storage;

  final StreamController<AuthAccount?> _accountController = StreamController.broadcast();
  AuthAccount? _account;
  AuthTokens? _tokens;
  bool _bootstrapped = false;

  ApiClient get api => _api;

  Stream<AuthAccount?> get accountStream => _accountController.stream;
  AuthAccount? get currentAccount => _account;
  AuthTokens? get currentTokens => _tokens;
  bool get isAuthenticated => _account != null && _tokens != null;

  /// Load any persisted tokens. Call once at app launch — before any code
  /// reads `currentAccount`.
  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    _tokens = await _storage.readTokens();
    _account = await _storage.readAccount();
    _accountController.add(_account);
  }

  /// Returns true if an active account exists for [mobile] (10-digit, no prefix).
  Future<bool> checkMobileExists(String mobile) async {
    final res = await _api.dio.post<Map<String, Object?>>(
      '/api/v1/auth/check',
      data: {'mobile': mobile},
    );
    return (res.data?['exists'] as bool?) ?? false;
  }

  Future<void> startOtp(String mobile, {String countryCode = '+91'}) async {
    await _api.dio.post<Map<String, Object?>>(
      '/api/v1/auth/otp/start',
      data: {'mobile': mobile, 'country_code': countryCode},
    );
  }

  Future<AuthAccount> verifyOtp({
    required String mobile,
    required String code,
    String countryCode = '+91',
    String? username,
  }) async {
    final res = await _api.dio.post<Map<String, Object?>>(
      '/api/v1/auth/otp/verify',
      data: {
        'mobile': mobile,
        'code': code,
        'country_code': countryCode,
        if (username != null && username.trim().isNotEmpty)
          'username': username.trim(),
      },
    );
    return _persistFrom(res.data!);
  }

  /// Best-effort refresh. Returns the new tokens on success or null on
  /// failure (caller should treat the session as expired).
  Future<AuthTokens?> refresh() async {
    final tokens = _tokens;
    if (tokens == null) return null;
    try {
      final res = await _api.dio.post<Map<String, Object?>>(
        '/api/v1/auth/refresh',
        data: {'refresh_token': tokens.refreshToken},
      );
      final next = AuthTokens.fromJson(res.data!);
      _tokens = next;
      await _storage.writeTokens(next);
      return next;
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('[auth] refresh failed: ${e.message}');
      return null;
    }
  }

  Future<void> logout() async {
    _account = null;
    _tokens = null;
    await _storage.clear();
    _accountController.add(null);
  }

  Future<AuthAccount> _persistFrom(Map<String, Object?> body) async {
    final tokens = AuthTokens.fromJson(body);
    final account = AuthAccount.fromAuthResponse(body);
    _tokens = tokens;
    _account = account;
    await _storage.writeTokens(tokens);
    await _storage.writeAccount(account);
    _accountController.add(account);
    return account;
  }
}
