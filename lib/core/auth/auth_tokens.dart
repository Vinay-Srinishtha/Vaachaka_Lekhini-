import 'package:equatable/equatable.dart';

/// Pair of access + refresh tokens issued by the server.
class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;

  bool get isAccessExpired => DateTime.now().isAfter(accessExpiresAt.subtract(const Duration(seconds: 30)));

  factory AuthTokens.fromJson(Map<String, Object?> json) => AuthTokens(
        accessToken: json['access_token'] as String? ?? '',
        refreshToken: json['refresh_token'] as String? ?? '',
        accessExpiresAt: DateTime.tryParse(json['access_token_expires_at'] as String? ?? '') ?? DateTime.now().add(const Duration(hours: 1)),
        refreshExpiresAt: DateTime.tryParse(json['refresh_token_expires_at'] as String? ?? '') ?? DateTime.now().add(const Duration(days: 30)),
      );

  Map<String, Object?> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'access_token_expires_at': accessExpiresAt.toIso8601String(),
        'refresh_token_expires_at': refreshExpiresAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [accessToken, refreshToken];
}

/// Lightweight view of the signed-in account, kept alongside the tokens
/// so the splash screen can render before /api/v1/me lands.
class AuthAccount extends Equatable {
  const AuthAccount({
    required this.id,
    required this.mobile,
    required this.countryCode,
    this.primaryMemberId,
  });

  final String id;
  final String mobile;
  final String countryCode;
  final String? primaryMemberId;

  factory AuthAccount.fromAuthResponse(Map<String, Object?> json) {
    final acc = (json['account'] as Map?)?.cast<String, Object?>() ?? {};
    final primary = (json['primary_member'] as Map?)?.cast<String, Object?>();
    return AuthAccount(
      id: acc['id'] as String? ?? '',
      mobile: acc['mobile'] as String? ?? '',
      countryCode: (acc['country_code'] as String?) ?? '+91',
      primaryMemberId: primary?['id'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'mobile': mobile,
        'country_code': countryCode,
        'primary_member_id': primaryMemberId,
      };

  factory AuthAccount.fromJson(Map<String, Object?> json) => AuthAccount(
        id: json['id'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
        countryCode: (json['country_code'] as String?) ?? '+91',
        primaryMemberId: json['primary_member_id'] as String?,
      );

  @override
  List<Object?> get props => [id];
}
