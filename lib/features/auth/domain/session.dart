import 'package:equatable/equatable.dart';

/// Represents an authenticated user session. In Phase 1 this is created
/// locally by the dummy [AuthRepository]; in Phase 9 it will be created
/// by the remote auth backend. Same shape, same UI consumption.
class Session extends Equatable {
  const Session({
    required this.userId,
    required this.username,
    required this.mobile,
    required this.language,
    required this.createdAt,
    this.referralCode,
    this.primaryMemberId,
  });

  /// Stable user id (uuid).
  final String userId;
  final String username;

  /// Full E.164 mobile, e.g. "+919876543210".
  final String mobile;

  /// BCP-47 language code: en | hi | te | kn.
  final String language;

  final String? referralCode;
  final DateTime createdAt;

  /// Server-assigned primary Member id. Set on registration/login so the
  /// client can pin the correct server UUID as the active profile instead of
  /// generating a new local one.
  final String? primaryMemberId;

  Session copyWith({
    String? userId,
    String? username,
    String? mobile,
    String? language,
    String? referralCode,
    DateTime? createdAt,
    String? primaryMemberId,
  }) =>
      Session(
        userId: userId ?? this.userId,
        username: username ?? this.username,
        mobile: mobile ?? this.mobile,
        language: language ?? this.language,
        referralCode: referralCode ?? this.referralCode,
        createdAt: createdAt ?? this.createdAt,
        primaryMemberId: primaryMemberId ?? this.primaryMemberId,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'mobile': mobile,
        'language': language,
        'referralCode': referralCode,
        'createdAt': createdAt.toIso8601String(),
        'primaryMemberId': primaryMemberId,
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        userId: j['userId'] as String,
        username: j['username'] as String,
        mobile: j['mobile'] as String,
        language: j['language'] as String? ?? 'en',
        referralCode: j['referralCode'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        primaryMemberId: j['primaryMemberId'] as String?,
      );

  @override
  List<Object?> get props => [userId, username, mobile, language, referralCode, createdAt, primaryMemberId];
}
