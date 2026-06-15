import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import 'app/app.dart';
import 'core/storage/hive_setup.dart';
import 'core/storage/storage_keys.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // edgeToEdge: app fills the full screen with transparent bars while keeping
  // the system gesture zone (bottom swipe, side swipes) always active.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  // Portrait-only — the spiritual practice surfaces are designed around
  // a single-column reading experience.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await initHive();
  // Clear the active profile on every cold start so the "Who is Practicing?"
  // screen is always shown. The user explicitly picks who is chanting each
  // session — the last-used profile is never auto-resumed.
  Hive.box<dynamic>(KvlBoxes.session).delete(KvlKeys.activeProfileId);
  runApp(const ProviderScope(child: KvlApp()));
}

