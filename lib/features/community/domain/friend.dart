import 'package:equatable/equatable.dart';

class Friend extends Equatable {
  const Friend({
    required this.id,
    required this.name,
    required this.longestStreak,
    required this.currentStreak,
    required this.totalChants,
    this.isSelf = false,
    this.streakActive = false,
  });

  final String id;
  final String name;

  /// Best-ever consecutive-day run — used for ranking and podium display.
  final int longestStreak;

  /// Currently active consecutive-day run (0 if broken).
  final int currentStreak;

  final int totalChants;
  final bool isSelf;

  /// true when [currentStreak] > 0 and last practice was today or yesterday.
  final bool streakActive;

  /// Backward-compat alias used by the sort/display logic.
  int get streakDays => longestStreak;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
          .toUpperCase();
    }
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
  }

  @override
  List<Object?> get props =>
      [id, name, longestStreak, currentStreak, totalChants, isSelf, streakActive];
}

enum LeaderboardSort { streak, totalChants }

class LeaderboardFilter extends Equatable {
  const LeaderboardFilter({required this.sort, this.mantraId});
  final LeaderboardSort sort;
  final String? mantraId;

  @override
  List<Object?> get props => [sort, mantraId];
}
