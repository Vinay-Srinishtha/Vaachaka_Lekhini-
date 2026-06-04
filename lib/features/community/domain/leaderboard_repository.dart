import 'friend.dart';

abstract class LeaderboardRepository {
  /// All friends including the user themselves, ordered by [sort].
  /// In Phase 5 this returns 5 seeded friends + the user; Phase 9 will
  /// replace this with a real backend leaderboard.
  Future<List<Friend>> leaderboard({required LeaderboardSort sort, required Friend self});

  /// Max friends a user can invite to their circle (per Figma).
  static const int maxCircle = 5;
}
