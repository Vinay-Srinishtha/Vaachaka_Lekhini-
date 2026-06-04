import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'storage_keys.dart';

/// Initialises Hive CE and opens the boxes used across the app.
/// Call once during app bootstrap, before `runApp`.
Future<void> initHive() async {
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  await Future.wait([
    Hive.openBox<dynamic>(KvlBoxes.session),
    Hive.openBox<dynamic>(KvlBoxes.profiles),
    Hive.openBox<dynamic>(KvlBoxes.settings),
    Hive.openBox<dynamic>(KvlBoxes.cache),
    Hive.openBox<dynamic>(KvlBoxes.outbox),
  ]);

  if (kDebugMode) {
    debugPrint('Hive initialised at ${dir.path}');
  }
}

/// Convenience accessors. These assume `initHive` ran successfully.
Box<dynamic> sessionBox() => Hive.box<dynamic>(KvlBoxes.session);
Box<dynamic> profilesBox() => Hive.box<dynamic>(KvlBoxes.profiles);
Box<dynamic> settingsBox() => Hive.box<dynamic>(KvlBoxes.settings);
Box<dynamic> cacheBox() => Hive.box<dynamic>(KvlBoxes.cache);
Box<dynamic> outboxBox() => Hive.box<dynamic>(KvlBoxes.outbox);
