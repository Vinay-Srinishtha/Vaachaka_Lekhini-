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

  /// Drop the current session.
  Future<void> logout();
}

/// Failure subtypes specific to auth.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code, super.cause});

  factory AuthFailure.invalidOtp() =>
      const AuthFailure('Incorrect verification code', code: 'invalid_otp');

  factory AuthFailure.invalidMobile() =>
      const AuthFailure('Please enter a valid mobile number', code: 'invalid_mobile');

  factory AuthFailure.unknown(Object? cause) =>
      AuthFailure('Something went wrong', code: 'unknown', cause: cause);
}
