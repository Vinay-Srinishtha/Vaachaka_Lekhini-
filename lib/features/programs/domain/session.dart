import 'package:equatable/equatable.dart';

enum SessionModality {
  voice,
  manual,
  handwriting;

  static SessionModality fromName(String name) =>
      SessionModality.values.firstWhere((m) => m.name == name, orElse: () => SessionModality.manual);
}

/// Mirrors Prisma `Session` table.
/// [countAdded] was `count` in v2 (Prisma field name).
/// [memberId] added — Prisma stores it directly on Session.
/// [durationSec] added — Prisma tracks session length.
/// [usedHandwriting] removed — modality == handwriting covers it.
class PracticeSession extends Equatable {
  const PracticeSession({
    required this.id,
    required this.programId,
    // ADDED: Prisma Session.memberId
    required this.memberId,
    required this.startedAt,
    required this.createdAt,
    // CHANGED: count → countAdded
    required this.countAdded,
    required this.modality,
    required this.updatedAt,
    this.endedAt,
    // ADDED: session length in seconds
    this.durationSec = 0,
  });

  final String id;
  final String programId;
  final String memberId;
  final DateTime startedAt;
  final DateTime createdAt;
  final DateTime? endedAt;
  final int countAdded;
  final int durationSec;
  final SessionModality modality;
  final DateTime updatedAt;

  bool get isOpen => endedAt == null;
  Duration get duration => (endedAt ?? DateTime.now()).difference(startedAt);

  @override
  List<Object?> get props => [id];
}

/// What the Daily Progress detail card shows for a selected day.
/// [usedHandwriting] derived from whether any session had modality==handwriting.
class DailySummary extends Equatable {
  const DailySummary({
    required this.day,
    required this.dailyTarget,
    required this.actualAchieved,
    // CHANGED: still exposed to UI — now derived from modality, not a stored bool
    required this.usedHandwriting,
  });

  final DateTime day;
  final int dailyTarget;
  final int actualAchieved;
  final bool usedHandwriting;

  bool get metTarget => actualAchieved >= dailyTarget;

  @override
  List<Object?> get props => [day, dailyTarget, actualAchieved, usedHandwriting];
}
