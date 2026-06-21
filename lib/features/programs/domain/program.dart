import 'package:equatable/equatable.dart';

/// Mirrors Prisma `Program` table.
/// [memberId] = Prisma Member.id (was profileId).
/// [completedAt] replaces the old status enum — null means active/in-progress.
/// [currentStreak] / [longestStreak] are kept in sync with the backend;
/// the backend is authoritative on pull.
/// [dailyTarget] is a local convenience field (targetWritings / targetDays),
/// not stored in Prisma.
class Program extends Equatable {
  const Program({
    required this.id,
    // CHANGED: profileId → memberId
    required this.memberId,
    required this.mantraId,
    required this.targetWritings,
    required this.targetDays,
    required this.dailyTarget,
    required this.startedAt,
    required this.createdAt,
    required this.updatedAt,
    // CHANGED: status enum → completedAt nullable timestamp
    this.completedAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.totalChants = 0,
    this.totalWritings = 0,
  });

  final String id;
  final String memberId;
  final String mantraId;
  final int targetWritings;
  final int targetDays;
  final int dailyTarget;
  final DateTime startedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final int totalChants;
  final int totalWritings;

  // Derived helpers used by UI — same logic as before

  /// Server has confirmed completion (completedAt timestamp set).
  bool get isCompleted => completedAt != null;

  /// A goal-less "bonus" program: chants recorded without a set target.
  /// Created when the user chants first and chooses not to build a program.
  bool get hasGoal => targetWritings > 0;

  /// True for a goal-less program that already has chants recorded — i.e.
  /// a "Bonus Chants" bucket. An open program with no chants yet is neither
  /// a real program nor a bonus bucket (it's hidden until used).
  bool get isBonus => !hasGoal && totalProgress > 0;

  /// Goal reached locally — target met or server confirmed.
  /// Use this for all UI completion checks (milestones, ring, tabs) so
  /// the display stays consistent with the "✓ Goal Achieved" banner even
  /// before the next server sync stamps completedAt.
  /// Goal-less (bonus) programs are never "reached" — there is no goal.
  bool get isGoalReached =>
      hasGoal && (completedAt != null || totalProgress >= targetWritings);

  int get totalProgress => totalChants + totalWritings;

  double get progressFraction =>
      targetWritings <= 0 ? 0 : (totalProgress / targetWritings).clamp(0, 1).toDouble();

  int get daysElapsed {
    final today = DateTime.now();
    final start = DateTime(startedAt.year, startedAt.month, startedAt.day);
    return today.difference(start).inDays + 1;
  }

  int get daysRemaining =>
      targetDays <= 0 ? 0 : (targetDays - daysElapsed).clamp(0, targetDays);

  /// Dynamic daily target: remaining chants spread over remaining days.
  /// Recalculates as the user progresses so the goal stays achievable.
  /// Goal-less (bonus/open) programs have no daily target — return 0 instead
  /// of running `clamp(1, 0)`, which would throw (lower limit > upper limit).
  int get effectiveDailyTarget {
    if (targetDays <= 0 || targetWritings <= 0) return 0;
    final remaining = (targetWritings - totalProgress).clamp(0, targetWritings);
    final days = daysRemaining.clamp(1, targetDays);
    return (remaining / days).ceil();
  }

  Duration get estimatedDailyTime => Duration(seconds: dailyTarget);

  Program copyWith({
    DateTime? completedAt,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? totalChants,
    int? totalWritings,
    DateTime? updatedAt,
    int? targetWritings,
    int? targetDays,
  }) {
    final tw = targetWritings ?? this.targetWritings;
    final td = targetDays ?? this.targetDays;
    return Program(
      id: id,
      memberId: memberId,
      mantraId: mantraId,
      targetWritings: tw,
      targetDays: td,
      dailyTarget: td > 0 ? (tw / td).ceil() : 0,
      startedAt: startedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      totalChants: totalChants ?? this.totalChants,
      totalWritings: totalWritings ?? this.totalWritings,
    );
  }

  @override
  List<Object?> get props => [id];
}
