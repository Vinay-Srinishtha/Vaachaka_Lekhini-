import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import '../features/settings/domain/settings_repository.dart';
import 'providers.dart';
import 'router.dart';

class KvlApp extends ConsumerWidget {
  const KvlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    // Kick off the Vosk model warm-up in the background once auth completes.
    // We discard the value — its only job is to side-effect the unzip.
    ref.watch(voskModelWarmupProvider);

    // Touch the remote-backed providers so they hydrate from cache + start
    // their background refresh against /api/v1/* at app launch. The mantra
    // catalog is already watched by screens, but feature flags have no
    // existing consumer yet — keep this read so the first fetch fires.
    ref.watch(mantraRepositoryProvider);
    ref.watch(remoteConfigProvider);

    return MaterialApp.router(
      title: 'Vaachaka Lekhini',
      debugShowCheckedModeBanner: false,
      theme: buildKvlLightTheme(),
      themeMode: settings.themeMode,
      routerConfig: router,
      locale: Locale(settings.languageCode),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('te'),
        Locale('kn'),
      ],
      builder: (context, child) {
        // Honour the user-selected font scale (Profile → Display → Font Size).
        // Clamped to a sensible range so layouts never break.
        final scale = settings.fontScale.clamp(0.85, 1.5);
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
