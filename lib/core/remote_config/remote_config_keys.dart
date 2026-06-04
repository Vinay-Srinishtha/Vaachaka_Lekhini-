/// Central registry of remote-config keys served by `/api/v1/config`.
/// Mirrors the keys seeded by the admin app's `prisma/seed.ts`. Keep in
/// sync: a typo here silently falls back to the in-code default.
abstract final class RemoteConfigKeys {
  // Feature toggles
  static const voiceCounting = 'feature.voice_counting';
  static const handwritingCamera = 'feature.handwriting_camera';
  static const handwritingGallery = 'feature.handwriting_gallery';
  static const communityTab = 'feature.community_tab';
  static const storeTab = 'feature.store_tab';

  // Tunables
  static const dailyQuoteTelugu = 'config.daily_quote_telugu';
  static const maxProfilesPerUser = 'config.max_profiles_per_user';
  static const minAppVersion = 'config.min_app_version';
}
