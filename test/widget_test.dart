import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:vachika_lekhini/app/app.dart';
import 'package:vachika_lekhini/app/providers.dart';
import 'package:vachika_lekhini/core/notifications/notification_scheduler.dart';
import 'package:vachika_lekhini/core/storage/storage_keys.dart';

/// No-op scheduler so FlutterLocalNotifications doesn't touch the platform
/// channel in tests (it requires a real iOS/Android environment to init).
class _NoOpScheduler extends NotificationScheduler {
  @override
  Future<void> reschedule(TimeOfDay time, {String sound = 'bell'}) async {}
  @override
  Future<void> cancel() async {}
}

void main() {
  late Directory tmp;

  setUp(() async {
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
          notificationSchedulerProvider.overrideWithValue(_NoOpScheduler()),
        ],
        child: const KvlApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Vaachaka Lekhini'), findsOneWidget);
  });
}
