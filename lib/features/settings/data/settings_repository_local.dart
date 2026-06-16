import 'dart:async';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:hive_ce/hive.dart';

import '../../../core/storage/storage_keys.dart';
import '../domain/settings_repository.dart';

class SettingsRepositoryLocal implements SettingsRepository {
  SettingsRepositoryLocal(this._box) {
    _migrateMantraLanguageIfNeeded();
    _emit();
    _box.watch().listen((_) => _emit());
  }

  /// One-time backfill of the mantra-language key, run before onboarding can
  /// change the app language:
  /// • Existing installs (an app language was already chosen) keep mantras
  ///   looking exactly as before by following that language.
  /// • Fresh installs (no language yet) default to Devanagari ('hi'), the
  ///   canonical chant script.
  /// After this runs the two settings are fully independent.
  void _migrateMantraLanguageIfNeeded() {
    if (_box.containsKey(KvlKeys.mantraLanguageCode)) return;
    final existingLang = _box.get(KvlKeys.languageCode) as String?;
    _box.put(
      KvlKeys.mantraLanguageCode,
      existingLang ?? KvlSettings.fallback.mantraLanguageCode,
    );
  }

  final Box<dynamic> _box;
  final _controller = StreamController<KvlSettings>.broadcast();

  void _emit() => _controller.add(_read());

  KvlSettings _read() {
    String? str(String k) => _box.get(k) as String?;
    bool b(String k, {bool fb = false}) => (_box.get(k) as bool?) ?? fb;

    final reminderRaw = str(KvlKeys.reminderTime) ?? '06:00';
    final parts = reminderRaw.split(':');
    final t = parts.length == 2
        ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 6, minute: int.tryParse(parts[1]) ?? 0)
        : KvlSettings.fallback.reminderTime;

    final hasLangKey = _box.containsKey(KvlKeys.languageCode);
    final languageCode =
        str(KvlKeys.languageCode) ?? KvlSettings.fallback.languageCode;

    return KvlSettings(
      languageCode: languageCode,
      // Mirror the migration in [_migrateMantraLanguageIfNeeded] for the brief
      // window before its async write lands: explicit choice → existing app
      // language (upgrade) → Devanagari fallback (fresh install).
      mantraLanguageCode: str(KvlKeys.mantraLanguageCode) ??
          (hasLangKey ? languageCode : KvlSettings.fallback.mantraLanguageCode),
      reminderTime: t,
      notificationSound: str(KvlKeys.notificationSound) ?? KvlSettings.fallback.notificationSound,
      micSensitivity: MicSensitivity.fromName(str(KvlKeys.micSensitivity)),
      linkFacebook: b('linkFacebook'),
      linkWhatsApp: b('linkWhatsApp'),
      linkInstagram: b('linkInstagram'),
    );
  }

  @override
  Future<KvlSettings> snapshot() async => _read();

  @override
  Stream<KvlSettings> watch() async* {
    yield _read();
    yield* _controller.stream;
  }

  @override
  Future<void> setLanguage(String code) => _box.put(KvlKeys.languageCode, code);

  @override
  Future<void> setMantraLanguage(String code) =>
      _box.put(KvlKeys.mantraLanguageCode, code);

  @override
  Future<void> setReminderTime(TimeOfDay t) =>
      _box.put(KvlKeys.reminderTime, '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');

  @override
  Future<void> setNotificationSound(String sound) => _box.put(KvlKeys.notificationSound, sound);

  @override
  Future<void> setMicSensitivity(MicSensitivity s) => _box.put(KvlKeys.micSensitivity, s.name);

  @override
  Future<void> setLinkFacebook(bool v) => _box.put('linkFacebook', v);

  @override
  Future<void> setLinkWhatsApp(bool v) => _box.put('linkWhatsApp', v);

  @override
  Future<void> setLinkInstagram(bool v) => _box.put('linkInstagram', v);

  @override
  Future<Map<String, dynamic>> exportJson() async {
    final s = _read();
    return {
      'languageCode': s.languageCode,
      'mantraLanguageCode': s.mantraLanguageCode,
      'reminderTime': '${s.reminderTime.hour}:${s.reminderTime.minute}',
      'notificationSound': s.notificationSound,
      'micSensitivity': s.micSensitivity.name,
      'linkFacebook': s.linkFacebook,
      'linkWhatsApp': s.linkWhatsApp,
      'linkInstagram': s.linkInstagram,
    };
  }
}
