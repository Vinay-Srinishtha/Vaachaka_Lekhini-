import '../../../core/remote_config/remote_config.dart';

/// Reward economy rates and milestone thresholds.
/// Driven by FeatureFlags at /api/v1/config so the economy can be tuned
/// from the admin panel without a release. All business logic validation
/// runs server-side; this class is used only for client-side UI feedback
/// (haptic triggers, milestone labels).
class RewardRules {
  const RewardRules({
    this.dailyTarget = 50,
    this.milestoneCross = 500,
    this.friendReferral = 100,
    this.charityDonation = 50,
    this.milestoneThresholds = const [
      100000,
      500000,
      1000000,
      2500000,
      5000000,
      10000000,
    ],
  });

  final int dailyTarget;
  final int milestoneCross;
  final int friendReferral;
  final int charityDonation;
  final List<int> milestoneThresholds;

  factory RewardRules.fromConfig(RemoteConfig cfg) => RewardRules(
        dailyTarget: cfg.intFlag('reward_daily_points', fallback: 50),
        milestoneCross: cfg.intFlag('reward_milestone_points', fallback: 500),
        friendReferral: cfg.intFlag('reward_friend_referral', fallback: 100),
        charityDonation: cfg.intFlag('reward_charity_donation', fallback: 50),
        milestoneThresholds: cfg.listIntFlag(
          'reward_milestone_thresholds',
          fallback: const [100000, 500000, 1000000, 2500000, 5000000, 10000000],
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
