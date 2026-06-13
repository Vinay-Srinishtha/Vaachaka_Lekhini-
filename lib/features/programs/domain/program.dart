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
    // ADDED: streak fields (Prisma tracks these)
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

  /// true when admin or user has marked this program done.
  bool get isCompleted => completedAt != null;

  int get totalProgress => totalChants + totalWritings;

  double get progressFraction =>
      targetWritings <= 0 ? 0 : (totalProgress / targetWritings).clamp(0, 1).toDouble();

  int get daysElapsed {
    final today = DateTime.now();
    final start = DateTime(startedAt.year, startedAt.month, startedAt.day);
    return today.difference(start).inDays + 1;
  }

  int get daysRemaining => (targetDays - daysElapsed).clamp(0, targetDays);

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
