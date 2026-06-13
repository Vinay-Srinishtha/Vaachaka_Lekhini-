import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hive_ce/hive.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/storage/repository.dart';
import '../../../core/storage/storage_keys.dart';
import '../domain/auth_repository.dart';
import '../domain/session.dart';

/// Real auth backed by the KVL backend (/api/v1/auth/*).
///
/// Flow:
///   sendOtp   → POST /api/v1/auth/otp/start  (backend sends real SMS)
///   verifyOtp → POST /api/v1/auth/otp/verify → JWT pair + Account stub
///             → persists Session to Hive so the rest of the app stays the same
///   logout    → clears JWT + Hive session
///
/// The [AuthService] owns the JWT lifecycle (storage + auto-refresh via Dio
/// interceptor). This class is a thin adapter that maps AuthService → the
/// AuthRepository interface the UI depends on.
class AuthRepositoryRemote implements AuthRepository {
  AuthRepositoryRemote({
    required AuthService authService,
    required Box<dynamic> sessionBox,
  })  : _auth = authService,
        _sessionBox = sessionBox {
    // Seed the broadcast stream from whatever is already in secure storage.
    _controller.add(_readSession());

    // Forward sign-in / sign-out events from AuthService → our session stream.
    _auth.accountStream.listen((account) {
      if (account == null) {
        _sessionBox.delete(KvlKeys.currentSession);
        _controller.add(null);
      }
      // sign-in is handled inside verifyOtp after we have the full session shape
    });
  }

  final AuthService _auth;
  final Box<dynamic> _sessionBox;
  final _controller = StreamController<Session?>.broadcast();

  // ---------------------------------------------------------------------------
  // Hive helpers — same storage shape as AuthRepositoryLocal so existing
  // persisted sessions are still readable after the swap.
  // ---------------------------------------------------------------------------

  Session? _readSession() {
    final raw = _sessionBox.get(KvlKeys.currentSession);
    if (raw == null) return null;
    try {
      return Session.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSession(Session? s) async {
    if (s == null) {
      await _sessionBox.delete(KvlKeys.currentSession);
    } else {
      await _sessionBox.put(KvlKeys.currentSession, s.toJson());
    }
    _controller.add(s);
  }

  // ---------------------------------------------------------------------------
  // AuthRepository interface
  // ---------------------------------------------------------------------------

  @override
  Future<Session?> currentSession() async => _readSession();

  @override
  Stream<Session?> sessionChanges() => _controller.stream;

  @override
  Future<Result<bool>> checkMobileRegistered(String mobile) async {
    if (!_isValidMobile(mobile)) return Err(AuthFailure.invalidMobile());
    try {
      final digits = mobile.replaceAll(RegExp(r'^\+91'), '');
      final exists = await _auth.checkMobileExists(digits);
      return Ok(exists);
    } on DioException catch (e) {
      return Err(_mapDioException(e));
    } catch (e) {
      return Err(AuthFailure.unknown(e));
    }
  }

  /// Calls POST /api/v1/auth/otp/start — the backend sends a real SMS.
  @override
  Future<Result<void>> sendOtp(String mobile) async {
    if (!_isValidMobile(mobile)) return Err(AuthFailure.invalidMobile());
    try {
      // Strip +91 prefix — backend schema expects 10 raw digits.
      final digits = mobile.replaceAll(RegExp(r'^\+91'), '');
      await _auth.startOtp(digits);
      return const Ok(null);
    } on DioException catch (e) {
      return Err(_mapDioException(e, isOtpStart: true));
    } catch (e) {
      return Err(AuthFailure.unknown(e));
    }
  }

  /// Calls POST /api/v1/auth/otp/verify.
  /// On success: persists JWT (via AuthService) + Session (in Hive).
  /// The returned [Session.userId] is the Prisma Account.id — used as the
  /// FK for all Member (Profile) rows created for this account.
  @override
  Future<Result<Session>> verifyOtp({
    required String mobile,
    required String otp,
    String? username,
    String? referralCode,
    String? language,
  }) async {
    if (!_isValidMobile(mobile)) return Err(AuthFailure.invalidMobile());
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) return Err(AuthFailure.invalidOtp());
    try {
      // Strip +91 prefix — backend schema expects 10 raw digits.
      final digits = mobile.replaceAll(RegExp(r'^\+91'), '');
      final account = await _auth.verifyOtp(
        mobile: digits,
        code: otp,
        username: username,
      );

      // Build a Session using what we know. Username may come from the
      // registration form (new user) or from a later /api/v1/me pull
      // (returning user). We store whatever we have now — the sync engine
      // will enrich it after the first pull.
      final existing = _readSession();
      final session = Session(
        userId: account.id,          // Prisma Account.id
        username: (username?.trim().isNotEmpty == true)
            ? username!.trim()
            : (existing?.username ?? 'Friend'),
        mobile: mobile,
        language: language ?? existing?.language ?? 'en',
        referralCode: referralCode?.trim().isEmpty == true
            ? null
            : referralCode?.trim(),
        createdAt: existing?.createdAt ?? DateTime.now(),
      );
      await _writeSession(session);
      return Ok(session);
    } on DioException catch (e) {
      return Err(_mapDioException(e, isRegistration: username != null));
    } catch (e) {
      return Err(AuthFailure.unknown(e));
    }
  }

  // ---------------------------------------------------------------------------
  // DioException → AuthFailure mapping
  // ---------------------------------------------------------------------------

  AuthFailure _mapDioException(
    DioException e, {
    bool isOtpStart = false,
    bool isRegistration = false,
  }) {
    // Network-level errors — no response available.
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AuthFailure.serverUnavailable();
      case DioExceptionType.connectionError:
        return AuthFailure.noInternet();
      default:
        break;
    }

    final data = e.response?.data;
    final body = data is Map ? data : <String, dynamic>{};
    final serverCode = (body['code'] as String? ?? '').toLowerCase();
    final serverMsg = (body['message'] as String? ?? '').toLowerCase();
    final status = e.response?.statusCode ?? 0;

    // --- sendOtp-specific codes ---
    if (isOtpStart) {
      if (serverCode == 'invalid_mobile' || serverMsg.contains('invalid')) {
        return AuthFailure.invalidMobile();
      }
      if (status == 429 || serverCode.contains('rate') || serverMsg.contains('too many')) {
        return AuthFailure.tooManyAttempts();
      }
    }

    // --- verifyOtp-specific codes ---
    if (status == 401 || status == 400) {
      if (serverCode == 'otp_expired' || serverMsg.contains('expired')) {
        return AuthFailure.otpExpired();
      }
      if (serverCode.contains('no_account') ||
          serverMsg.contains('no account') ||
          serverMsg.contains('not found') ||
          serverMsg.contains('register')) {
        return AuthFailure.accountNotFound();
      }
      if (serverCode.contains('exists') || serverMsg.contains('already exists')) {
        return AuthFailure.accountAlreadyExists();
      }
      if (serverCode == 'invalid_otp' ||
          serverCode == 'invalid_code' ||
          serverMsg.contains('invalid') ||
          serverMsg.contains('incorrect') ||
          serverMsg.contains('wrong')) {
        return AuthFailure.invalidOtp();
      }
      if (status == 401) return AuthFailure.invalidOtp();
    }

    if (status == 404) return AuthFailure.accountNotFound();
    if (status == 409) return AuthFailure.accountAlreadyExists();
    if (status == 429) return AuthFailure.tooManyAttempts();
    if (status >= 500) return AuthFailure.serverError();

    return AuthFailure.unknown(e);
  }

  @override
  Future<Result<Session>> updateName(String name) async {
    final existing = _readSession();
    if (existing == null) return Err(const AuthFailure('Not logged in.', code: 'not_authenticated'));
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Err(const AuthFailure('Name cannot be empty.', code: 'invalid_name'));
    final updated = existing.copyWith(username: trimmed);
    await _writeSession(updated);
    return Ok(updated);
  }

  @override
  Future<Result<Session>> updateMobile({
    required String newMobile,
    required String otp,
  }) async {
    final existing = _readSession();
    if (existing == null) return Err(const AuthFailure('Not logged in.', code: 'not_authenticated'));
    if (!_isValidMobile(newMobile)) return Err(AuthFailure.invalidMobile());
    if (newMobile == existing.mobile) {
      return Err(const AuthFailure(
        'New number is the same as the current number.',
        code: 'same_mobile',
      ));
    }
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) return Err(AuthFailure.invalidOtp());
    try {
      final digits = newMobile.replaceAll(RegExp(r'^\+91'), '');
      await _auth.verifyOtp(mobile: digits, code: otp);
      final updated = existing.copyWith(mobile: newMobile);
      await _writeSession(updated);
      return Ok(updated);
    } on DioException catch (e) {
      return Err(_mapDioException(e));
    } catch (e) {
      return Err(AuthFailure.unknown(e));
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _auth.api.dio.delete<void>('/api/v1/me');
    } catch (_) {
      // Best-effort — proceed with local wipe even if request fails.
    }
    await logout();
  }

  @override
  Future<void> logout() async {
    await _auth.logout();         // clears JWT from secure storage
    await _writeSession(null);    // clears Hive session
    await _sessionBox.delete(KvlKeys.activeProfileId);
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  bool _isValidMobile(String m) {
    final stripped = m.replaceAll(RegExp(r'\s+'), '');
    return RegExp(r'^(\+91)?[6-9]\d{9}$').hasMatch(stripped);
  }
}
