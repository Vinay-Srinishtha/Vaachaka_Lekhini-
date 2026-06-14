/// Central registry of remote-config keys served by `/api/v1/config`.
/// Mirrors the keys seeded by the admin app's `prisma/seed.ts`. Keep in
/// sync: a typo here silently falls back to the in-code default.
abstract final class RemoteConfigKeys {
  // Feature toggles
  static const handwritingCamera = 'feature.handwriting_camera';
  static const handwritingGallery = 'feature.handwriting_gallery';
  static const communityTab = 'feature.community_tab';
  static const storeTab = 'feature.store_tab';

  // Tunables
  static const dailyQuoteTelugu = 'config.daily_quote_telugu';
  static const dailyQuoteAttribution = 'config.daily_quote_attribution';
  static const maxProfilesPerUser = 'config.max_profiles_per_user';

  /// Minimum handwriting accuracy (0–100 integer) required to accept a
  /// written Japa count. Compared against HandwritingComparator score × 100.
  /// Default: 20 (20%). Adjustable from admin without an app update.
  static const minHandwritingAccuracy = 'config.min_handwriting_accuracy';

  // Reward economy — must stay in sync with admin reward-config.ts seedDefaultFlags()
  static const rewardDailyPoints = 'reward_daily_points';
  static const rewardMilestonePoints = 'reward_milestone_points';
  static const rewardFriendReferral = 'reward_friend_referral';
  static const rewardCharityDonation = 'reward_charity_donation';
  static const rewardMilestoneThresholds = 'reward_milestone_thresholds';
}
