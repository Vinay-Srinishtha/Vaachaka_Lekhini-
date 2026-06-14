import '../../../core/remote_config/remote_config.dart';
import '../../../core/remote_config/remote_config_keys.dart';

/// Reward economy rates and milestone thresholds.
/// All values come from FeatureFlags at /api/v1/config — tunable from the
/// admin panel without a release. Business-logic validation runs server-side;
/// this class is used only for client-side UI feedback (haptic triggers,
/// milestone labels). Use [RewardRules.fromConfig] — never construct directly.
class RewardRules {
  const RewardRules._({
    required this.dailyTarget,
    required this.milestoneCross,
    required this.friendReferral,
    required this.charityDonation,
    required this.milestoneThresholds,
  });

  final int dailyTarget;
  final int milestoneCross;
  final int friendReferral;
  final int charityDonation;
  final List<int> milestoneThresholds;

  static const _defaultThresholds = [
    100000, 500000, 1000000, 2500000, 5000000, 10000000,
  ];

  factory RewardRules.fromConfig(RemoteConfig cfg) => RewardRules._(
        dailyTarget: cfg.intFlag(RemoteConfigKeys.rewardDailyPoints, fallback: 50),
        milestoneCross: cfg.intFlag(RemoteConfigKeys.rewardMilestonePoints, fallback: 500),
        friendReferral: cfg.intFlag(RemoteConfigKeys.rewardFriendReferral, fallback: 100),
        charityDonation: cfg.intFlag(RemoteConfigKeys.rewardCharityDonation, fallback: 50),
        milestoneThresholds: cfg.listIntFlag(
          RemoteConfigKeys.rewardMilestoneThresholds,
          fallback: _defaultThresholds,
        ),
      );

  String? milestoneCrossedLabel(int before, int after) {
    for (final t in milestoneThresholds) {
      if (before < t && after >= t) return _label(t);
    }
    return null;
  }

  static String _label(int n) {
    if (n >= 10000000) return '${n ~/ 10000000} Cr Chants';
    if (n >= 100000) return '${n ~/ 100000} Lakh Chants';
    return '$n Chants';
  }
}
