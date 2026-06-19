import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'app/app.dart';
import 'app/providers.dart';
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
  // Load the bundled sqlite3 .so before Drift opens the database.
  // Required on Android — the native assets resolver can't find the symbol
  // via process lookup on recent Android versions.
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }
  await initHive();
  // Clear the active profile on every cold start so the "Who is Practicing?"
  // screen is always shown. The user explicitly picks who is chanting each
  // session — the last-used profile is never auto-resumed.
  Hive.box<dynamic>(KvlBoxes.session).delete(KvlKeys.activeProfileId);

  // Pre-warm key providers before the first frame so auth state, Drift DB
  // connection, and remote config are already initialising before the widget
  // tree builds. This eliminates the visible "loading → content" flash.
  final container = ProviderContainer();
  container.read(appDatabaseProvider);          // opens Drift/SQLite connection early
  container.read(sessionProvider);              // starts the auth stream
  container.read(remoteConfigProvider);         // kicks off remote-config fetch
  container.read(appSettingsProvider);          // kicks off app-settings fetch
  container.read(mantraCatalogProvider);        // seeds mantra list from cache
  container.read(activeGlobalSadhanaProvider);  // seeds global sadhana from cache
  container.read(quotesProvider);               // seeds quote cards from cache
  container.read(storeItemsProvider);           // seeds store catalogue from cache
  container.read(activeProfileProvider);        // starts profile stream
  container.read(programsForActiveProfileProvider); // starts programs stream
  container.read(rewardTotalProvider);          // starts balance stream
  // Let the sync microtasks settle (session + profile emit their first value).
  await Future.microtask(() {});
  await Future.microtask(() {});
  await Future.microtask(() {});
  await Future.microtask(() {});

  runApp(UncontrolledProviderScope(container: container, child: const KvlApp()));
}

