import '../domain/friend.dart';
import '../domain/leaderboard_repository.dart';

class LeaderboardRepositoryLocal implements LeaderboardRepository {
  /// Hand-tuned mock friends matching the Figma leaderboard. The numbers
  /// are deliberately ahead/behind the user to make ranking visible.
  static const _seeded = <Friend>[
    Friend(id: 'rohan', name: 'Rohan Mehta', streakDays: 138, totalChants: 1850000),
    Friend(id: 'anjali', name: 'Anjali Sharma', streakDays: 152, totalChants: 2900000),
    Friend(id: 'priya', name: 'Priya Desai', streakDays: 119, totalChants: 1400000),
    Friend(id: 'vikram', name: 'Vikram Singh', streakDays: 73, totalChants: 720000),
    Friend(id: 'meera', name: 'Meera Iyer', streakDays: 56, totalChants: 510000),
  ];

  @override
  Future<List<Friend>> leaderboard({required LeaderboardSort sort, required Friend self}) async {
    final list = [..._seeded, self];
    switch (sort) {
      case LeaderboardSort.streak:
        list.sort((a, b) => b.streakDays.compareTo(a.streakDays));
      case LeaderboardSort.totalChants:
        list.sort((a, b) => b.totalChants.compareTo(a.totalChants));
    }
    return list;
  }
}
