import '../../../core/storage/repository.dart';
import 'reward_event.dart';

abstract class RewardRepository {
  Future<int> totalPoints(String memberId);
  Stream<int> watchTotalPoints(String memberId);

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
}

class RewardFailure extends Failure {
  const RewardFailure(super.message, {super.code});
  factory RewardFailure.insufficient(int needed, int have) =>
      RewardFailure('Need $needed points (you have $have)', code: 'insufficient_points');
}
