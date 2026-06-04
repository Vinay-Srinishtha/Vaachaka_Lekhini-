import 'package:equatable/equatable.dart';

enum ProgramStatus {
  active,
  completed,
  paused;

  static ProgramStatus fromName(String name) =>
      ProgramStatus.values.firstWhere((s) => s.name == name, orElse: () => ProgramStatus.active);
}

/// A user's commitment to chant/write a mantra a target number of times
/// over a target number of days, with one row per profile · per mantra.
class Program extends Equatable {
  const Program({
    required this.id,
    required this.profileId,
    required this.mantraId,
    required this.targetWritings,
    required this.targetDays,
    required this.dailyTarget,
    required this.startedAt,
    required this.status,
    required this.totalChants,
    required this.totalWritings,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final String mantraId;
  final int targetWritings;
  final int targetDays;
  final int dailyTarget;
  final DateTime startedAt;
  final ProgramStatus status;
  final int totalChants;
  final int totalWritings;
  final DateTime updatedAt;

  int get totalProgress => totalChants + totalWritings;

  /// 0.0 — 1.0
  double get progressFraction =>
      targetWritings <= 0 ? 0 : (totalProgress / targetWritings).clamp(0, 1).toDouble();

  int get daysElapsed {
    final today = DateTime.now();
    final start = DateTime(startedAt.year, startedAt.month, startedAt.day);
    return today.difference(start).inDays + 1;
  }

  int get daysRemaining => (targetDays - daysElapsed).clamp(0, targetDays);

  /// "1.5 hours/day" pacing estimate at 1 second per chant.
  Duration get estimatedDailyTime => Duration(seconds: dailyTarget);

  @override
  List<Object?> get props => [id];
}
