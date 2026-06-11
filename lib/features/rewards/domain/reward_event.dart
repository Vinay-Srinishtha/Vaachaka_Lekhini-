import 'package:equatable/equatable.dart';

enum RewardKind {
  earn,
  spend;

  static RewardKind fromName(String name) =>
      RewardKind.values.firstWhere((k) => k.name == name, orElse: () => RewardKind.earn);
}

/// One line in the reward ledger — mirrors Prisma `RewardEvent` table.
/// [memberId] was profileId in v2.
/// [occurredAt] was createdAt in v2 (Prisma field name).
/// [storeItemId] nullable — set when kind==spend for a store redemption.
class RewardEvent extends Equatable {
  const RewardEvent({
    required this.id,
    // CHANGED: profileId → memberId
    required this.memberId,
    required this.kind,
    required this.amount,
    required this.source,
    // CHANGED: createdAt → occurredAt
    required this.occurredAt,
    // ADDED: nullable store item link (Prisma field)
    this.storeItemId,
  });

  final String id;
  final String memberId;
  final RewardKind kind;
  final int amount;
  final String source;
  final DateTime occurredAt;
  final String? storeItemId;

  int get signedAmount => kind == RewardKind.earn ? amount : -amount;

  @override
  List<Object?> get props => [id];
}
