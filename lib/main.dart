import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/storage/hive_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait-only — the spiritual practice surfaces are designed around
  // a single-column reading experience.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await initHive();
  runApp(const ProviderScope(child: KvlApp()));
}
