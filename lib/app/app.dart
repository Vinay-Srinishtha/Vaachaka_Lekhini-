import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import '../features/settings/domain/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

class KvlApp extends ConsumerStatefulWidget {
  const KvlApp({super.key});

  @override
  ConsumerState<KvlApp> createState() => _KvlAppState();
}

class _KvlAppState extends ConsumerState<KvlApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(mantraRepositoryProvider).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
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

    // CRITICAL: SyncEngine is a lazy provider — nothing else watches it, so
    // without this line the outbox never drains and nothing reaches Prisma.
    ref.watch(syncEngineProvider);

    // Reschedule on every cold start (clears the previously scheduled alarm
    // which Android drops on reboot) and whenever settings change.
    ref.listen(settingsProvider, (prev, next) {
      final s = next.value;
      if (s == null) return;
      final p = prev?.value;
      // Always reschedule on first emission (prev == null = cold start).
      // After that, only reschedule when time or sound actually changed.
      if (p != null &&
          p.reminderTime == s.reminderTime &&
          p.notificationSound == s.notificationSound) {
        return;
      }
      ref
          .read(notificationSchedulerProvider)
          .reschedule(s.reminderTime, sound: s.notificationSound);
    });

    return MaterialApp.router(
      title: 'Vaachaka Lekhini',
      debugShowCheckedModeBanner: false,
      theme: buildKvlLightTheme(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: Locale(settings.languageCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
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
