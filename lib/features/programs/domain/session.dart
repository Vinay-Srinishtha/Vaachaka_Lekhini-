import 'package:equatable/equatable.dart';

enum SessionModality {
  voice,
  manual,
  handwriting;

  static SessionModality fromName(String name) =>
      SessionModality.values.firstWhere((m) => m.name == name, orElse: () => SessionModality.manual);
}

class PracticeSession extends Equatable {
  const PracticeSession({
    required this.id,
    required this.programId,
    required this.startedAt,
    required this.count,
    required this.modality,
    required this.usedHandwriting,
    required this.updatedAt,
    this.endedAt,
  });

  final String id;
  final String programId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int count;
  final SessionModality modality;
  final bool usedHandwriting;
  final DateTime updatedAt;

  bool get isOpen => endedAt == null;
  Duration get duration => (endedAt ?? DateTime.now()).difference(startedAt);

  @override
  List<Object?> get props => [id];
}

/// What the Daily Progress detail card shows for a selected day.
class DailySummary extends Equatable {
  const DailySummary({
    required this.day,
    required this.dailyTarget,
    required this.actualAchieved,
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
