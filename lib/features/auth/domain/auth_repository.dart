import '../../../core/storage/repository.dart';
import 'session.dart';

/// Contract for authentication. The local implementation in Phase 1 fakes
/// OTP entirely; the remote implementation in Phase 9 will hit a backend.
/// UI code must only depend on this abstract type.
abstract class AuthRepository {
  /// Currently persisted session, or null if not signed in.
  Future<Session?> currentSession();

  /// Watch the session over time (emits whenever it changes).
  Stream<Session?> sessionChanges();

  /// Returns true if an account already exists for [mobile].
  Future<Result<bool>> checkMobileRegistered(String mobile);

  /// Trigger an OTP send for [mobile]. In Phase 1 this is a no-op that
  /// returns immediately; in Phase 9 it calls the backend SMS service.
  Future<Result<void>> sendOtp(String mobile);

  /// Verify [otp] for [mobile] and create (or restore) a session.
  /// [username] / [referralCode] / [language] are written when creating
  /// a new account; ignored when restoring an existing session.
  Future<Result<Session>> verifyOtp({
    required String mobile,
    required String otp,
    String? username,
    String? referralCode,
    String? language,
  });

  /// Update the display name on the current session (and "me" profile).
  Future<Result<Session>> updateName(String name);

  /// Update the mobile number on the current session after OTP verification.
  /// The [otp] must have been sent to [newMobile] via [sendOtp] first.
  Future<Result<Session>> updateMobile({
    required String newMobile,
    required String otp,
  });

  /// Delete the account from the backend, then drop the local session.
  Future<void> deleteAccount();

  /// Drop the current session.
  Future<void> logout();
}

/// Failure subtypes specific to auth.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.cause});

  factory AuthFailure.invalidOtp() =>
      const AuthFailure('Wrong verification code. Please try again.', code: 'invalid_otp');

  factory AuthFailure.invalidMobile() =>
      const AuthFailure('Please enter a valid 10-digit mobile number.', code: 'invalid_mobile');

  factory AuthFailure.accountNotFound() => const AuthFailure(
        'No account found for this number. Please create an account first.',
        code: 'account_not_found',
      );

  factory AuthFailure.accountAlreadyExists() => const AuthFailure(
        'An account already exists for this number. Please log in instead.',
        code: 'account_exists',
      );

  factory AuthFailure.serverUnavailable() => const AuthFailure(
        'Server is unreachable. Please check your connection and try again.',
        code: 'server_unavailable',
      );

  factory AuthFailure.noInternet() => const AuthFailure(
        'No internet connection. Please check your network and try again.',
        code: 'no_internet',
      );

  factory AuthFailure.otpExpired() => const AuthFailure(
        'Verification code has expired. Please request a new one.',
        code: 'otp_expired',
      );

  factory AuthFailure.serverError() => const AuthFailure(
        'Server error. Please try again in a moment.',
        code: 'server_error',
      );

  factory AuthFailure.tooManyAttempts() => const AuthFailure(
        'Too many attempts. Please wait a moment before trying again.',
        code: 'too_many_attempts',
      );

  factory AuthFailure.accountBanned() => const AuthFailure(
        'Your account has been suspended. Please contact support.',
        code: 'account_banned',
      );

  factory AuthFailure.accountSuspended() => const AuthFailure(
        'Your account has been deactivated by an administrator. Please contact support.',
        code: 'account_suspended',
      );

  factory AuthFailure.otpMaxAttempts() => const AuthFailure(
        'Too many wrong codes. This code is now locked — please request a new one.',
        code: 'otp_max_attempts',
      );

  factory AuthFailure.otpAlreadyUsed() => const AuthFailure(
        'This code has already been used. Please request a new verification code.',
        code: 'otp_already_used',
      );

  factory AuthFailure.cooldownActive() => const AuthFailure(
        'Please wait before requesting another code.',
        code: 'cooldown_active',
      );

  factory AuthFailure.dailyLimitReached() => const AuthFailure(
        'Daily OTP limit reached. Please try again tomorrow.',
        code: 'daily_limit_reached',
      );

  factory AuthFailure.deliveryFailure() => const AuthFailure(
        'We could not deliver the SMS to this number. Please try again.',
        code: 'delivery_failure',
      );

  factory AuthFailure.unknown(Object? cause) =>
      AuthFailure('Something went wrong. Please try again.', code: 'unknown', cause: cause);
}
