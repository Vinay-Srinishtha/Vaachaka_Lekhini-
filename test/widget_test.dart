import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:vachika_lekhini/app/app.dart';
import 'package:vachika_lekhini/core/storage/storage_keys.dart';

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
    ]);
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  testWidgets('KvlApp boots and redirects unauthenticated user to Welcome', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: KvlApp()));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Vaachaka Lekhini'), findsOneWidget);
  });
}
