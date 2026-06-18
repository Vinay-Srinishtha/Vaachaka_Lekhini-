import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/permissions/startup_permissions.dart';
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
    // Prompt for Mic + Notifications permissions once, after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(StartupPermissions.requestAll());
    });
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
      // Drain outbox and pull /api/v1/me so rewards, programs and streak
      // counts reflect server state immediately when the user returns to the app.
      unawaited(ref.read(syncEngineProvider).syncNow());
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    // Kick off the Vosk warm-up in the background once auth completes:
    // unzip the model AND build the shared recognizer (the expensive native
    // model load) so tapping "Start" begins counting instantly — no cold load.
    ref.watch(voskModelWarmupProvider);
    ref.watch(voskRecognizerProvider);

    // Touch the remote-backed providers so they hydrate from cache + start
    // their background refresh against /api/v1/* at app launch. The mantra
    // catalog is already watched by screens, but feature flags have no
    // existing consumer yet — keep this read so the first fetch fires.
    ref.watch(mantraRepositoryProvider);
    ref.watch(remoteConfigProvider);
    // Pre-warm programs so the Drift stream is already running by the time
    // the home screen builds — eliminates the shimmer flash for returning users.
    ref.watch(programsForActiveProfileProvider);

    // CRITICAL: SyncEngine is a lazy provider — nothing else watches it, so
    // without this line the outbox never drains and nothing reaches Prisma.
    ref.watch(syncEngineProvider);

    // Restore server profiles/programs after login and on every /api/v1/me pull.
    ref.watch(accountHydrationProvider);

    // Keep the active profile's language in sync with app-level settings.
    ref.watch(profileLanguageSyncProvider);

    // Switch UI language when the user switches to a different family member.
    // Guard against cold start: on first emission prev is null/AsyncLoading, so
    // the stored Hive setting (the real source of truth) must not be overwritten
    // by the server-returned profile.language which may default to 'en'.
    ref.listen(activeProfileProvider, (prev, next) {
      final profile = next.value;
      if (profile == null) return;
      // Only act when transitioning from one loaded member to another.
      final prevProfile = prev?.value;
      if (prevProfile == null) return;          // cold start — trust stored settings
      if (prevProfile.id == profile.id) return; // same member — no switch
      final current = ref.read(settingsProvider).value;
      final repo = ref.read(settingsRepositoryProvider);
      if (current != null && current.languageCode != profile.language) {
        unawaited(repo.setLanguage(profile.language));
      }
      if (current != null &&
          current.mantraLanguageCode != profile.mantraLanguage) {
        unawaited(repo.setMantraLanguage(profile.mantraLanguage));
      }
    });

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
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
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
    );
  }
}
