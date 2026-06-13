import '../../../core/storage/repository.dart';
import 'reward_event.dart';

abstract class RewardRepository {
  Future<int> totalPoints(String memberId);
  Stream<int> watchTotalPoints(String memberId);

  /// Live balance = sum(programs.totalProgress) − sum(spend events).
  /// Updates immediately on every chant without waiting for a server sync.
  Stream<int> watchBalance(String memberId);

  Future<List<RewardEvent>> history(String memberId, {RewardKind? filter});
  Stream<List<RewardEvent>> watchHistory(String memberId, {RewardKind? filter});

  Future<void> earn({
    required String memberId,
    required int amount,
    required String source,
    String? storeItemId,
  });
  Future<Result<void>> spend({
    required String memberId,
    required int amount,
    required String source,
    String? storeItemId,
  });

  /// Sync the server-computed balance into local storage without enqueuing
  /// anything to the outbox. Called after each /api/v1/me pull.
  Future<void> reconcileFromServer(String memberId, int serverBalance);
}

class RewardFailure extends Failure {
  const RewardFailure(super.message, {super.code});
  factory RewardFailure.insufficient(int needed, int have) =>
      RewardFailure('Need $needed points (you have $have)', code: 'insufficient_points');
}
