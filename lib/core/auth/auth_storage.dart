import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_tokens.dart';

/// Encrypted at-rest storage for the user's JWT pair + cached account stub.
/// Uses platform-native keychain (iOS) / EncryptedSharedPreferences (Android).
class AuthStorage {
  AuthStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kTokens = 'kvl.auth.tokens';
  static const _kAccount = 'kvl.auth.account';

  Future<AuthTokens?> readTokens() async {
    final raw = await _storage.read(key: _kTokens);
    if (raw == null) return null;
    try {
      return AuthTokens.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      await _storage.delete(key: _kTokens);
      return null;
    }
  }

  Future<void> writeTokens(AuthTokens tokens) async {
    await _storage.write(key: _kTokens, value: jsonEncode(tokens.toJson()));
  }

  Future<AuthAccount?> readAccount() async {
    final raw = await _storage.read(key: _kAccount);
    if (raw == null) return null;
    try {
      return AuthAccount.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      await _storage.delete(key: _kAccount);
      return null;
    }
  }

  Future<void> writeAccount(AuthAccount account) async {
    await _storage.write(key: _kAccount, value: jsonEncode(account.toJson()));
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _kTokens),
      _storage.delete(key: _kAccount),
    ]);
  }
}
