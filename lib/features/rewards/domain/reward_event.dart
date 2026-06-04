import 'package:equatable/equatable.dart';

enum RewardKind {
  earn,
  spend;

  static RewardKind fromName(String name) =>
      RewardKind.values.firstWhere((k) => k.name == name, orElse: () => RewardKind.earn);
}

/// One line in the user's reward ledger. Signed integers so totals are
/// `sum(amount * (kind==earn ? +1 : -1))` — convenience helpers below.
class RewardEvent extends Equatable {
  const RewardEvent({
    required this.id,
    required this.profileId,
    required this.kind,
    required this.amount,
    required this.source,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final RewardKind kind;
  final int amount;

  /// Human-readable source: "Daily Mantra Completion", "Milestone: 10 Lakh", "Store: E-book", "Friend Referral", "Donation to Charity".
  final String source;
  final DateTime createdAt;

  int get signedAmount => kind == RewardKind.earn ? amount : -amount;

  @override
  List<Object?> get props => [id];
}
