import '../../../core/storage/repository.dart';
import 'reward_event.dart';

abstract class RewardRepository {
  Future<int> totalPoints(String profileId);
  Stream<int> watchTotalPoints(String profileId);

  Future<List<RewardEvent>> history(String profileId, {RewardKind? filter});
  Stream<List<RewardEvent>> watchHistory(String profileId, {RewardKind? filter});

  Future<void> earn({required String profileId, required int amount, required String source});
  Future<Result<void>> spend({required String profileId, required int amount, required String source});
}

class RewardFailure extends Failure {
  const RewardFailure(super.message, {super.code});
  factory RewardFailure.insufficient(int needed, int have) =>
      RewardFailure('Need $needed points (you have $have)', code: 'insufficient_points');
}
