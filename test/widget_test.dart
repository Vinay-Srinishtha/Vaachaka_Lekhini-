import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:vachika_lekhini/app/app.dart';
import 'package:vachika_lekhini/app/providers.dart';
import 'package:vachika_lekhini/core/notifications/notification_scheduler.dart';
import 'package:vachika_lekhini/core/permissions/startup_permissions.dart';
import 'package:vachika_lekhini/core/remote_config/remote_config.dart';
import 'package:vachika_lekhini/core/remote_config/remote_config_repository.dart';
import 'package:vachika_lekhini/core/storage/repository.dart';
import 'package:vachika_lekhini/core/storage/storage_keys.dart';
import 'package:vachika_lekhini/features/auth/domain/auth_repository.dart';
import 'package:vachika_lekhini/features/auth/domain/session.dart';
import 'package:vachika_lekhini/features/mantras/domain/mantra.dart';
import 'package:vachika_lekhini/features/mantras/domain/mantra_repository.dart';
import 'package:vachika_lekhini/features/settings/domain/settings_repository.dart';

/// No-op scheduler so FlutterLocalNotifications doesn't touch the platform
/// channel in tests (it requires a real iOS/Android environment to init).
class _NoOpScheduler extends NotificationScheduler {
  @override
  Future<void> reschedule(TimeOfDay time, {String sound = 'bell'}) async {}
  @override
  Future<void> cancel() async {}
}

class _EmptyMantraRepository implements MantraRepository {
  @override
  List<Mantra> all() => const [];

  @override
  Mantra? byId(String id) => null;

  @override
  Future<void> refresh() async {}

  @override
  List<Mantra> recommendForNeed(MantraNeed need) => const [];

  @override
  Stream<List<Mantra>> get stream => const Stream.empty();
}

class _EmptyRemoteConfigRepository implements RemoteConfigRepository {
  @override
  RemoteConfig current() => RemoteConfig.empty;

  @override
  Future<void> refresh() async {}

  @override
  Stream<RemoteConfig> watch() => const Stream.empty();
}

class _LoggedOutAuthRepository implements AuthRepository {
  @override
  Session? cachedSession() => null;

  @override
  Future<Session?> currentSession() async => null;

  @override
  Stream<Session?> sessionChanges() => const Stream.empty();

  @override
  Future<Result<bool>> checkMobileRegistered(String mobile) async =>
      const Ok(false);

  @override
  Future<Result<void>> sendOtp(String mobile) async => const Ok(null);

  @override
  Future<Result<Session>> verifyOtp({
    required String mobile,
    required String otp,
    String? username,
    String? referralCode,
    String? language,
  }) async =>
      Err(AuthFailure.accountNotFound());

  @override
  Future<Result<Session>> updateName(String name) async =>
      Err(AuthFailure.accountNotFound());

  @override
  Future<Result<Session>> updateMobile({
    required String newMobile,
    required String otp,
  }) async =>
      Err(AuthFailure.accountNotFound());

  @override
  Future<Result<Session>> register({
    required String mobile,
    required String username,
    required String password,
    String? referralCode,
    String? language,
  }) async =>
      Err(AuthFailure.accountNotFound());

  @override
  Future<Result<Session>> loginWithPassword({
    required String mobile,
    required String password,
  }) async =>
      Err(AuthFailure.accountNotFound());

  @override
  Future<Result<void>> requestPasswordReset(String mobile) async =>
      const Ok(null);

  @override
  Future<Result<Session>> resetPassword({
    required String mobile,
    required String otp,
    required String newPassword,
  }) async =>
      Err(AuthFailure.accountNotFound());

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> logout() async {}
}

class _StaticSettingsRepository implements SettingsRepository {
  @override
  Future<KvlSettings> snapshot() async => KvlSettings.fallback;

  @override
  Stream<KvlSettings> watch() => Stream.value(KvlSettings.fallback);

  @override
  Future<void> setLanguage(String code) async {}

  @override
  Future<void> setMantraLanguage(String code) async {}

  @override
  Future<void> setReminderTime(TimeOfDay t) async {}

  @override
  Future<void> setNotificationSound(String sound) async {}

  @override
  Future<void> setMicSensitivity(MicSensitivity s) async {}

  @override
  Future<void> setLinkFacebook(bool v) async {}

  @override
  Future<void> setLinkWhatsApp(bool v) async {}

  @override
  Future<void> setLinkInstagram(bool v) async {}

  @override
  Future<Map<String, dynamic>> exportJson() async => const {};
}

void main() {
  late Directory tmp;

  setUp(() async {
    StartupPermissions.enabled = false; // no startup permission timer in tests
    tmp = await Directory.systemTemp.createTemp('kvl_test_');
    Hive.init(p.join(tmp.path, 'hive'));
    await Future.wait([
      Hive.openBox<dynamic>(KvlBoxes.session),
      Hive.openBox<dynamic>(KvlBoxes.profiles),
      Hive.openBox<dynamic>(KvlBoxes.settings),
      Hive.openBox<dynamic>(KvlBoxes.cache),
      Hive.openBox<dynamic>(KvlBoxes.outbox),
    ]);
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  testWidgets('KvlApp boots and redirects unauthenticated user to Welcome', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_LoggedOutAuthRepository()),
          settingsRepositoryProvider.overrideWithValue(
            _StaticSettingsRepository(),
          ),
          notificationSchedulerProvider.overrideWithValue(_NoOpScheduler()),
          mantraRepositoryProvider.overrideWithValue(_EmptyMantraRepository()),
          remoteConfigRepositoryProvider.overrideWithValue(
            _EmptyRemoteConfigRepository(),
          ),
        ],
        child: const KvlApp(startBackgroundServices: false),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Vaachaka Lekhini'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
