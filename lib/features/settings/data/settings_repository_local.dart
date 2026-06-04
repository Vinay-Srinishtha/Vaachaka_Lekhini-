import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../core/storage/storage_keys.dart';
import '../domain/settings_repository.dart';

class SettingsRepositoryLocal implements SettingsRepository {
  SettingsRepositoryLocal(this._box) {
    _emit();
    _box.watch().listen((_) => _emit());
  }

  final Box<dynamic> _box;
  final _controller = StreamController<KvlSettings>.broadcast();

  void _emit() => _controller.add(_read());

  KvlSettings _read() {
    String? str(String k) => _box.get(k) as String?;
    bool b(String k, {bool fb = false}) => (_box.get(k) as bool?) ?? fb;
    double d(String k, {double fb = 1.0}) => (_box.get(k) as num?)?.toDouble() ?? fb;

    final reminderRaw = str(KvlKeys.reminderTime) ?? '06:00';
    final parts = reminderRaw.split(':');
    final t = parts.length == 2
        ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 6, minute: int.tryParse(parts[1]) ?? 0)
        : KvlSettings.fallback.reminderTime;

    final themeName = str(KvlKeys.themeMode) ?? 'system';
    final theme = switch (themeName) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return KvlSettings(
      languageCode: str(KvlKeys.languageCode) ?? KvlSettings.fallback.languageCode,
      themeMode: theme,
      fontScale: d(KvlKeys.fontScale),
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
  Future<void> setThemeMode(ThemeMode mode) =>
      _box.put(KvlKeys.themeMode, switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      });

  @override
  Future<void> setFontScale(double scale) => _box.put(KvlKeys.fontScale, scale);

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
      'themeMode': s.themeMode.name,
      'fontScale': s.fontScale,
      'reminderTime': '${s.reminderTime.hour}:${s.reminderTime.minute}',
      'notificationSound': s.notificationSound,
      'micSensitivity': s.micSensitivity.name,
      'linkFacebook': s.linkFacebook,
      'linkWhatsApp': s.linkWhatsApp,
      'linkInstagram': s.linkInstagram,
    };
  }
}
