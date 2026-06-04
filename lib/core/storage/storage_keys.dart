/// Central registry of Hive box and key names — avoids stringly-typed access.
abstract final class KvlBoxes {
  static const session = 'kvl_session';
  static const profiles = 'kvl_profiles';
  static const settings = 'kvl_settings';
  static const cache = 'kvl_cache';
  static const outbox = 'kvl_outbox';
}

abstract final class KvlKeys {
  // session box
  static const currentSession = 'current';
  static const activeProfileId = 'activeProfileId';

  // settings box
  static const languageCode = 'languageCode';
  static const themeMode = 'themeMode';
  static const fontScale = 'fontScale';
  static const reminderTime = 'reminderTime';
  static const notificationSound = 'notificationSound';
  static const micSensitivity = 'micSensitivity';
}
