import 'package:flutter/material.dart';

import '../../../core/storage/repository.dart';

/// Discrete option set for "Microphone Sensitivity".
enum MicSensitivity {
  low,
  medium,
  high;

  String get label => switch (this) {
        MicSensitivity.low => 'Low',
        MicSensitivity.medium => 'Medium',
        MicSensitivity.high => 'High',
      };

  /// Minimum PCM amplitude (0–32767) a chunk must exceed to be passed to
  /// the ASR engine.  Low = lenient (picks up quiet voices / distant mic),
  /// High = strict (ignores background noise, requires a loud clear chant).
  double get minAmplitudeThreshold => switch (this) {
        MicSensitivity.low => 300.0,    // ~−38 dBFS — very quiet voices
        MicSensitivity.medium => 800.0, // ~−32 dBFS — normal speaking
        MicSensitivity.high => 2000.0,  // ~−24 dBFS — loud/clear chant
      };

  static MicSensitivity fromName(String? name) =>
      MicSensitivity.values.firstWhere((m) => m.name == name, orElse: () => MicSensitivity.medium);
}

/// Whole-app settings state. Used both by SettingsRepository.snapshot
/// and by the watch* stream so the UI gets a single immutable view.
class KvlSettings {
  const KvlSettings({
    required this.languageCode,
    required this.themeMode,
    required this.fontScale,
    required this.reminderTime,
    required this.notificationSound,
    required this.micSensitivity,
    required this.linkFacebook,
    required this.linkWhatsApp,
    required this.linkInstagram,
  });

  final String languageCode;
  final ThemeMode themeMode;
  final double fontScale;
  final TimeOfDay reminderTime;
  final String notificationSound;
  final MicSensitivity micSensitivity;
  final bool linkFacebook;
  final bool linkWhatsApp;
  final bool linkInstagram;

  static const fallback = KvlSettings(
    languageCode: 'en',
    themeMode: ThemeMode.system,
    fontScale: 1.0,
    reminderTime: TimeOfDay(hour: 6, minute: 0),
    notificationSound: 'Bell',
    micSensitivity: MicSensitivity.medium,
    linkFacebook: false,
    linkWhatsApp: false,
    linkInstagram: false,
  );

  KvlSettings copyWith({
    String? languageCode,
    ThemeMode? themeMode,
    double? fontScale,
    TimeOfDay? reminderTime,
    String? notificationSound,
    MicSensitivity? micSensitivity,
    bool? linkFacebook,
    bool? linkWhatsApp,
    bool? linkInstagram,
  }) =>
      KvlSettings(
        languageCode: languageCode ?? this.languageCode,
        themeMode: themeMode ?? this.themeMode,
        fontScale: fontScale ?? this.fontScale,
        reminderTime: reminderTime ?? this.reminderTime,
        notificationSound: notificationSound ?? this.notificationSound,
        micSensitivity: micSensitivity ?? this.micSensitivity,
        linkFacebook: linkFacebook ?? this.linkFacebook,
        linkWhatsApp: linkWhatsApp ?? this.linkWhatsApp,
        linkInstagram: linkInstagram ?? this.linkInstagram,
      );
}

abstract class SettingsRepository {
  Future<KvlSettings> snapshot();
  Stream<KvlSettings> watch();

  Future<void> setLanguage(String code);
  Future<void> setThemeMode(ThemeMode mode);
  Future<void> setFontScale(double scale);
  Future<void> setReminderTime(TimeOfDay t);
  Future<void> setNotificationSound(String sound);
  Future<void> setMicSensitivity(MicSensitivity s);
  Future<void> setLinkFacebook(bool v);
  Future<void> setLinkWhatsApp(bool v);
  Future<void> setLinkInstagram(bool v);

  /// Used by `Download Your Data`. Returns a JSON-ready map.
  Future<Map<String, dynamic>> exportJson();
}

class SettingsFailure extends Failure {
  const SettingsFailure(super.message, {super.code});
}
