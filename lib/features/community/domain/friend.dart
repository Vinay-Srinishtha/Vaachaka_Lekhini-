import 'package:equatable/equatable.dart';

class Friend extends Equatable {
  const Friend({
    required this.id,
    required this.name,
    required this.streakDays,
    required this.totalChants,
    this.isSelf = false,
  });

  final String id;
  final String name;
  final int streakDays;
  final int totalChants;
  final bool isSelf;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
    }
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
  }

  @override
  List<Object?> get props => [id, name, streakDays, totalChants, isSelf];
}

enum LeaderboardSort { streak, totalChants }
