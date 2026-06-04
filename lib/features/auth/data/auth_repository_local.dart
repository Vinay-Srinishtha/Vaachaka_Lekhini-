import 'dart:async';

import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/repository.dart';
import '../../../core/storage/storage_keys.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';

/// Phase-1 dummy auth backed by Hive.
/// - `sendOtp` is a no-op (the dummy code is "123456" or any 6 digits).
/// - `verifyOtp` accepts any 6-digit otp and persists a session.
///
/// When the real backend is wired in Phase 9, replace this with
/// `AuthRepositoryRemoteImpl` — UI/controllers won't change.
class AuthRepositoryLocal implements AuthRepository {
  AuthRepositoryLocal(this._sessionBox, {Uuid? uuid}) : _uuid = uuid ?? const Uuid() {
    // Seed the broadcast stream with the current persisted value.
    _controller.add(_readSession());
    // Forward any external box changes (e.g. logout from another notifier).
    _sessionBox.watch(key: KvlKeys.currentSession).listen((_) {
      _controller.add(_readSession());
    });
  }

  final Box<dynamic> _sessionBox;
  final Uuid _uuid;
  final _controller = StreamController<Session?>.broadcast();

  static const _otpDummyAcceptAnySixDigits = true;

  Session? _readSession() {
    final raw = _sessionBox.get(KvlKeys.currentSession);
    if (raw == null) return null;
    return Session.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> _writeSession(Session? s) async {
    if (s == null) {
      await _sessionBox.delete(KvlKeys.currentSession);
    } else {
      await _sessionBox.put(KvlKeys.currentSession, s.toJson());
    }
  }

  @override
  Future<Session?> currentSession() async => _readSession();

  @override
  Stream<Session?> sessionChanges() => _controller.stream;

  @override
  Future<Result<void>> sendOtp(String mobile) async {
    if (!_isValidMobile(mobile)) {
      return Err(AuthFailure.invalidMobile());
    }
    // No-op: in Phase 9 this calls the backend SMS service.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return const Ok(null);
  }

  @override
  Future<Result<Session>> verifyOtp({
    required String mobile,
    required String otp,
    String? username,
    String? referralCode,
    String? language,
  }) async {
    if (!_isValidMobile(mobile)) return Err(AuthFailure.invalidMobile());
    if (!_isValidOtp(otp)) return Err(AuthFailure.invalidOtp());

    await Future<void>.delayed(const Duration(milliseconds: 300));

    final existing = _readSession();
    final session = existing?.mobile == mobile
        ? existing!
        : Session(
            userId: _uuid.v4(),
            username: (username == null || username.trim().isEmpty) ? 'Friend' : username.trim(),
            mobile: mobile,
            language: language ?? 'en',
            referralCode: referralCode?.trim().isEmpty == true ? null : referralCode?.trim(),
            createdAt: DateTime.now(),
          );

    await _writeSession(session);
    return Ok(session);
  }

  @override
  Future<void> logout() async {
    await _writeSession(null);
    await _sessionBox.delete(KvlKeys.activeProfileId);
  }

  // --- validation helpers ---

  bool _isValidMobile(String m) {
    final stripped = m.replaceAll(RegExp(r'\s+'), '');
    // Expect +91 followed by 10 digits, or just 10 digits.
    final re = RegExp(r'^(\+91)?[6-9]\d{9}$');
    return re.hasMatch(stripped);
  }

  bool _isValidOtp(String o) {
    if (_otpDummyAcceptAnySixDigits) {
      return RegExp(r'^\d{6}$').hasMatch(o);
    }
    return o == '123456';
  }
}
