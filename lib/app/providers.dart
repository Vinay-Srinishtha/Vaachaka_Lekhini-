import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/asr/vosk_model_loader.dart';
import '../core/asr/vosk_recognizer.dart';
import '../core/notifications/notification_scheduler.dart';
import '../core/auth/auth_service.dart';
import '../core/auth/auth_storage.dart';
import '../core/remote_config/remote_config.dart';
import '../core/remote_config/remote_config_keys.dart';
import '../core/remote_config/remote_config_repository.dart';
import '../core/remote_config/remote_config_repository_remote.dart';
import '../core/storage/app_database.dart';
import '../core/storage/hive_setup.dart';
import '../core/sync/sync_engine.dart';
import '../core/sync/sync_outbox.dart';
import '../features/auth/data/auth_repository_remote.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/domain/session.dart';
import '../features/enrolment/handwriting/data/handwriting_repository_local.dart';
import '../features/enrolment/handwriting/domain/handwriting_repository.dart';
import '../features/community/data/invite_service.dart';
import '../features/community/domain/friend.dart';
import '../features/enrolment/voice/data/voice_enrolment_repository_local.dart';
import '../features/enrolment/voice/domain/voice_enrolment_repository.dart';
import '../features/mantras/data/mantra_repository_remote.dart';
import '../features/mantras/domain/mantra.dart';
import '../features/mantras/domain/mantra_repository.dart';
import '../features/global_sadhana/data/global_sadhana_repository.dart';
import '../features/global_sadhana/domain/global_sadhana.dart';
import '../features/home/data/quote_repository.dart';
import '../features/home/domain/quote.dart';
import '../features/programs/data/program_repository_drift.dart';
import '../features/programs/domain/program.dart';
import '../features/programs/domain/program_repository.dart';
import '../features/rewards/data/reward_repository_drift.dart';
import '../features/rewards/domain/reward_repository.dart';
import '../features/rewards/domain/reward_rules.dart';
import '../features/rewards/domain/store_item.dart';
import '../features/settings/data/settings_repository_local.dart';
import '../features/settings/domain/settings_repository.dart';
import '../features/profiles/data/profile_repository_local.dart';
import '../features/profiles/domain/profile.dart';
import '../features/profiles/domain/profile_repository.dart';

/// App-wide Riverpod composition root.
///
/// Repository providers are the only thing that changes when we swap
/// local → remote in Phase 9; the rest of the tree consumes the abstract
/// interface and doesn't care.

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryRemote(
    authService: ref.watch(authServiceProvider),
    sessionBox: sessionBox(),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryLocal(
    profilesBox: profilesBox(),
    sessionBox: sessionBox(),
    outbox: ref.watch(syncOutboxProvider),
  );
});

/// Secure-storage-backed JWT vault. Single instance shared by AuthService
/// and the Dio Bearer interceptor.
final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

/// Shared Dio-backed client for the public `/api/v1/*` endpoints.
/// The bearer interceptor reads tokens from [authStorageProvider] on every
/// request, so writes to the storage take effect on the next call.
final apiClientProvider = Provider<ApiClient>((ref) {
  ApiClient.useAuthStorage(ref.read(authStorageProvider));
  return ApiClient();
});

/// User-side auth (OTP + password). Hold a single instance for the
/// lifetime of the app so `accountStream` listeners persist across navigations.
final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService(
    api: ref.watch(apiClientProvider),
    storage: ref.watch(authStorageProvider),
  );
  // Best-effort bootstrap from secure storage. UI watches authAccountProvider.
  unawaited(service.bootstrap());
  return service;
});

/// Outbox for pending mutations awaiting upload. Backed by Hive.
final syncOutboxProvider = Provider<SyncOutbox>(
  (ref) => SyncOutbox(outboxBox()),
);

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    api: ref.watch(apiClientProvider),
    auth: ref.watch(authServiceProvider),
    outbox: ref.watch(syncOutboxProvider),
  );
  ref.onDispose(() => unawaited(engine.dispose()));
  return engine;
});

/// Mantra catalog — backed by the admin API with Hive cache fallback.
/// Reads from `MantraRepositoryRemote.readCache(cacheBox())` at bootstrap
/// in `main.dart`; shows empty list until the API responds.
final mantraRepositoryProvider = Provider<MantraRepository>((ref) {
  final bootstrap = MantraRepositoryRemote.readCache(cacheBox());
  return MantraRepositoryRemote(
    api: ref.watch(apiClientProvider),
    cache: cacheBox(),
    bootstrap: bootstrap,
  );
});

/// Live mantra catalog — seeds from cache immediately, then updates whenever
/// the API refresh lands (without any loading gap on subsequent opens).
final mantraCatalogProvider = StreamProvider<List<Mantra>>((ref) async* {
  final repo = ref.watch(mantraRepositoryProvider);
  yield repo.all(); // instant: cached or bootstrap value
  yield* repo.stream; // live: emits on every API refresh
});

final mantraByIdProvider = Provider.family<Mantra?, String>((ref, id) {
  final catalog = ref.watch(mantraCatalogProvider).value;
  if (catalog == null) return null;
  try {
    return catalog.firstWhere((m) => m.id == id);
  } catch (_) {
    return null;
  }
});

/// Remote feature-flag store. Reads `/api/v1/config`, caches in Hive.
final remoteConfigRepositoryProvider = Provider<RemoteConfigRepository>((ref) {
  final bootstrap = RemoteConfigRepositoryRemote.readCache(cacheBox());
  return RemoteConfigRepositoryRemote(
    api: ref.watch(apiClientProvider),
    cache: cacheBox(),
    bootstrap: bootstrap,
  );
});

/// Live snapshot of the feature flags. Re-emits whenever a refresh lands.
final remoteConfigProvider = StreamProvider<RemoteConfig>((ref) async* {
  final repo = ref.watch(remoteConfigRepositoryProvider);
  yield repo.current();
  yield* repo.watch();
});

/// Effective family-profile cap. Remote config can lower the limit but
/// never raise it past the local hard ceiling — the grid only renders
/// [ProfileRepository.maxPerUser] tiles, and the repository's runtime
/// guard rejects more anyway.
final profileCapProvider = Provider<int>((ref) {
  final cfg = ref.watch(remoteConfigProvider).value ?? RemoteConfig.empty;
  final remote = cfg.intFlag(
    RemoteConfigKeys.maxProfilesPerUser,
    fallback: ProfileRepository.maxPerUser,
  );
  return remote.clamp(1, ProfileRepository.maxPerUser);
});

final voiceEnrolmentRepositoryProvider = Provider<VoiceEnrolmentRepository>((
  ref,
) {
  return VoiceEnrolmentRepositoryLocal(cacheBox());
});

final handwritingRepositoryProvider = Provider<HandwritingRepository>((ref) {
  return HandwritingRepositoryLocal(cacheBox());
});

final inviteServiceProvider = Provider<InviteService>((ref) {
  final host = ref.watch(appSettingsProvider).value?.inviteHost ?? 'vaachakalekhini.com';
  return InviteService(host: host);
});

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return RewardRepositoryDrift(
    ref.watch(appDatabaseProvider),
    ref.watch(syncOutboxProvider),
  );
});

/// Exposes the /api/v1/me snapshot stream so other providers can react to pulls.
final meSnapshotProvider = StreamProvider<Map<String, Object?>>((ref) {
  return ref.watch(syncEngineProvider).snapshots;
});

/// Hydrates server-owned account data into local repositories after login,
/// foreground sync, and connectivity recovery. This makes a fresh device
/// usable without first creating duplicate local profiles/programs.
final accountHydrationProvider = Provider<void>((ref) {
  // Trigger an immediate pull whenever the user logs in so the restore
  // fires on a fresh device (startup pull happens before auth token exists).
  ref.listen(sessionProvider, (prev, next) {
    final wasLoggedOut = prev?.value == null;
    final isNowLoggedIn = next.value != null;
    if (wasLoggedOut && isNowLoggedIn) {
      unawaited(ref.read(syncEngineProvider).syncNow());
    }
  });

  ref.listen(meSnapshotProvider, (_, next) {
    final snapshot = next.value;
    if (snapshot == null) return;
    // Every sync pull happens AFTER the outbox drains, by which point the
    // server has credited any new practice sessions toward the global
    // sadhanas. Refresh the global providers so the count/percentage and the
    // user's contribution update live across home + detail screens.
    ref.invalidate(activeGlobalSadhanaProvider);
    ref.invalidate(globalSadhanaEnrollmentProvider);
    Future(() async {
      final account = snapshot['account'];
      if (account is! Map) return;

      final accountMap = Map<String, dynamic>.from(account);
      final accountId = accountMap['id'] as String?;
      if (accountId == null) return;
      final members = accountMap['members'] as List<dynamic>? ?? const [];

      for (final rawMember in members) {
        final member = Map<String, dynamic>.from(rawMember as Map);
        final memberId = member['id'] as String?;
        if (memberId == null) continue;
        final isPrimary = member['is_primary'] == true;
        final genderRaw = member['gender'] as String?;
        final profile = Profile(
          id: memberId,
          userId: accountId,
          name: (member['display_name'] as String?) ?? '',
          relation: isPrimary
              ? FamilyRelation.me
              : _familyRelationFromServer(
                  member['relation'] as String?,
                  genderRaw,
                ),
          gender: Gender.fromServer(genderRaw),
          birthYear: (member['birth_year'] as num?)?.toInt(),
          motherTongue: member['mother_tongue'] as String?,
          avatarSeed: member['avatar_key'] as String?,
          language: member['language'] as String? ?? 'en',
          mantraLanguage: member['mantra_language'] as String? ?? 'hi',
          createdAt:
              DateTime.tryParse(member['created_at'] as String? ?? '') ??
              DateTime.now(),
        );
        await ref.read(profileRepositoryProvider).upsertRemote(profile);

        final programs = member['programs'] as List<dynamic>? ?? const [];
        final serverProgramIds = <String>{};
        for (final rawProgram in programs) {
          final program = Map<String, dynamic>.from(rawProgram as Map);
          final id = program['id'] as String?;
          final mantra = program['mantra'];
          final mantraSlug = mantra is Map
              ? Map<String, dynamic>.from(mantra)['slug'] as String?
              : null;
          final targetWritings =
              (program['target_writings'] as num?)?.toInt() ?? 1;
          final targetDays = (program['target_days'] as num?)?.toInt() ?? 1;
          if (id == null || mantraSlug == null) continue;
          serverProgramIds.add(id);
          final startedAt =
              DateTime.tryParse(program['started_at'] as String? ?? '') ??
              DateTime.now();
          final updatedAt =
              DateTime.tryParse(program['updated_at'] as String? ?? '') ??
              startedAt;
          await ref
              .read(programRepositoryProvider)
              .upsertRemote(
                Program(
                  id: id,
                  memberId: memberId,
                  mantraId: mantraSlug,
                  targetWritings: targetWritings,
                  targetDays: targetDays,
                  dailyTarget: ProgramRepository.computeDailyTarget(
                    targetWritings,
                    targetDays,
                  ),
                  startedAt: startedAt,
                  createdAt: startedAt,
                  updatedAt: updatedAt,
                  completedAt: DateTime.tryParse(
                    program['completed_at'] as String? ?? '',
                  ),
                  currentStreak:
                      (program['current_streak'] as num?)?.toInt() ?? 0,
                  longestStreak:
                      (program['longest_streak'] as num?)?.toInt() ?? 0,
                  lastActiveDate: DateTime.tryParse(
                    program['last_active_date'] as String? ?? '',
                  ),
                  totalChants: (program['total_chants'] as num?)?.toInt() ?? 0,
                  totalWritings:
                      (program['total_writings'] as num?)?.toInt() ?? 0,
                ),
              );
        }

        // Delete any local programs that no longer exist on the server — but
        // NOT ones still queued in the outbox. The 60s poll calls pull()
        // without draining first, so a freshly-created local program may be
        // absent from this snapshot purely because it hasn't uploaded yet;
        // deleting it here would lose the user's new program.
        final pending = await ref.read(syncOutboxProvider).peekAll();
        final pendingProgramIds = pending
            .where((i) => i.kind.startsWith('programs.'))
            .map((i) => i.payload['id'])
            .whereType<String>()
            .toSet();
        final localPrograms = await ref
            .read(programRepositoryProvider)
            .listForProfile(memberId);
        for (final local in localPrograms) {
          if (!serverProgramIds.contains(local.id) &&
              !pendingProgramIds.contains(local.id)) {
            await ref.read(programRepositoryProvider).delete(local.id);
          }
        }

        final redemptions =
            member['reward_events'] as List<dynamic>? ?? const [];
        for (final rawRedemption in redemptions) {
          final r = Map<String, dynamic>.from(rawRedemption as Map);
          final eventId = r['id'] as String?;
          final storeItemId = r['store_item_id'] as String?;
          if (eventId == null || storeItemId == null) continue;
          await ref.read(rewardRepositoryProvider).seedRedemption(
                id: eventId,
                memberId: memberId,
                storeItemId: storeItemId,
                amount: (r['amount'] as num?)?.toInt() ?? 0,
                source: (r['source'] as String?) ?? 'store',
                occurredAt:
                    DateTime.tryParse(r['occurred_at'] as String? ?? '') ??
                    DateTime.now(),
              );
        }
      }
    }).catchError((Object e) { debugPrint('[accountHydration] error: $e'); });
  });
});

FamilyRelation _familyRelationFromServer(String? value, String? gender) {
  final isFemale = gender == 'female' || gender == 'f';
  return switch (value) {
    'self' => FamilyRelation.me,
    'spouse' => FamilyRelation.spouse,
    'parent' => isFemale ? FamilyRelation.mother : FamilyRelation.father,
    'child' => isFemale ? FamilyRelation.daughter : FamilyRelation.son,
    'sibling' => FamilyRelation.sibling,
    _ => FamilyRelation.other,
  };
}

final rewardTotalProvider = StreamProvider<int>((ref) async* {
  final profile = ref.watch(activeProfileProvider).value;
  if (profile == null) {
    yield 0;
    return;
  }

  // Reconcile server-computed balance + program totals into local Drift after each pull.
  ref.listen(meSnapshotProvider, (_, next) {
    final snapshot = next.value;
    if (snapshot == null) return;
    final members =
        ((snapshot['account'] as Map?)?['members'] as List<dynamic>?) ?? [];
    for (final m in members) {
      final map = Map<String, dynamic>.from(m as Map);
      if (map['id'] == profile.id) {
        // Reward balance reconciliation
        final serverBal = (map['reward_points_balance'] as num?)?.toInt() ?? 0;
        Future(
          () => ref
              .read(rewardRepositoryProvider)
              .reconcileFromServer(profile.id, serverBal),
        ).catchError((Object e) { debugPrint('[rewardTotal] reconcile error: $e'); });

        // Program totals reconciliation — server is canonical for totalChants/totalWritings
        final programs = (map['programs'] as List<dynamic>?) ?? [];
        for (final p in programs) {
          final pm = Map<String, dynamic>.from(p as Map);
          final programId = pm['id'] as String?;
          if (programId == null) continue;
          // Server sends snake_case after snakeJson transformation
          final serverChants =
              (pm['total_chants'] as num?)?.toInt() ?? 0;
          final serverWritings =
              (pm['total_writings'] as num?)?.toInt() ?? 0;
          Future(
            () => ref
                .read(programRepositoryProvider)
                .reconcileFromServer(programId, serverChants, serverWritings),
          ).catchError((Object e) { debugPrint('[rewardTotal] program reconcile error: $e'); });
        }
        break;
      }
    }
  });

  // Balance = sum(programs.totalProgress) − sum(spend events).
  // Updates live on every chant without waiting for a server sync.
  yield* ref.watch(rewardRepositoryProvider).watchBalance(profile.id);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryLocal(settingsBox());
});

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler();
});

final settingsProvider = StreamProvider<KvlSettings>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

/// Keep the selected UI language attached to the active server-backed member.
/// Local settings remain the immediate source of truth; the profile update is
/// queued so the same language is restored after login on another device.
final profileLanguageSyncProvider = Provider<void>((ref) {
  ref.listen(settingsProvider, (_, next) {
    final settings = next.value;
    final profile = ref.read(activeProfileProvider).value;
    if (settings == null || profile == null) return;

    final languageChanged = profile.language != settings.languageCode;
    final mantraChanged =
        profile.mantraLanguage != settings.mantraLanguageCode;
    if (!languageChanged && !mantraChanged) return;

    Future(
      () => ref.read(profileRepositoryProvider).update(
            profile.copyWith(
              language: settings.languageCode,
              mantraLanguage: settings.mantraLanguageCode,
            ),
          ),
    ).catchError((Object e) { debugPrint('[profileLanguageSync] error: $e'); });
  });
});

/// Fire-and-forget warm-up: once a session exists, extract the bundled
/// Hindi Vosk model on a background isolate-ish path so the first voice
/// session doesn't stall on unzip. Idempotent — `ensureExtracted` short-
/// circuits if the directory is already populated.
///
/// Watched from `KvlApp.build` purely to start the work — the future's
/// resolved path isn't consumed anywhere because [VoiceEnrolmentService]
/// calls `ensureExtracted` itself and finds the work already done.
final voskModelWarmupProvider = FutureProvider<String?>((ref) async {
  final session = ref.watch(sessionProvider).value;
  if (session == null) return null;
  try {
    final path = await VoskModelLoader().ensureExtracted();
    if (kDebugMode) debugPrint('Vosk model warmed at: $path');
    return path;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Vosk warm-up failed (will retry on first use): $e');
    }
    return null;
  }
});

/// Shared, long-lived [VoskRecognizer] built ONCE (the expensive native
/// `createModel` load) and reused across every voice session. Warmed at
/// launch from `KvlApp.build` so that tapping "Start" never pays the cold
/// model-load cost — counting begins the instant the mic opens.
///
/// Kept alive for the app's lifetime; disposed only on app shutdown.
final voskRecognizerProvider = FutureProvider<VoskRecognizer?>((ref) async {
  final session = ref.watch(sessionProvider).value;
  if (session == null) return null;
  ref.keepAlive();
  try {
    final path = await VoskModelLoader().ensureExtracted();
    final recognizer = await VoskRecognizer.create(modelPath: path);
    ref.onDispose(recognizer.dispose);
    if (kDebugMode) debugPrint('Vosk recognizer ready (model loaded).');
    return recognizer;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Vosk recognizer warm-up failed (will build on use): $e');
    }
    return null;
  }
});

/// Single shared Drift connection for the app's lifetime.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  return ProgramRepositoryDrift(
    ref.watch(appDatabaseProvider),
    ref.watch(syncOutboxProvider),
  );
});

/// Programs belonging to the active member. Empty when no profile is selected.
final programsForActiveProfileProvider = StreamProvider<List<Program>>((
  ref,
) async* {
  final profile = ref.watch(activeProfileProvider).value;
  if (profile == null) {
    yield const [];
    return;
  }
  // profile.id IS the memberId (Prisma Member.id)
  yield* ref.watch(programRepositoryProvider).watchForProfile(profile.id);
});

/// Most-recently-active program for the current member (or null).
final mostRecentProgramProvider = FutureProvider<Program?>((ref) async {
  ref.watch(programsForActiveProfileProvider);
  final profile = ref.watch(activeProfileProvider).value;
  if (profile == null) return null;
  return ref.watch(programRepositoryProvider).mostRecentlyActive(profile.id);
});

/// Reactive session state. `null` ⇒ logged out.
/// Emits the Hive-cached session synchronously on the first frame so the
/// profile and program providers never wait behind an async I/O boundary.
final sessionProvider = StreamProvider<Session?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  yield repo.cachedSession(); // synchronous Hive read — zero delay
  yield* repo.sessionChanges();
});

/// Reactive list of profiles belonging to the current user.
/// Empty when logged out.
final profilesProvider = StreamProvider<List<Profile>>((ref) async* {
  final session = ref.watch(sessionProvider).value;
  if (session == null) {
    yield const [];
    return;
  }
  yield* ref.watch(profileRepositoryProvider).watchForUser(session.userId);
});

/// Currently selected profile, or null.
final activeProfileProvider = StreamProvider<Profile?>((ref) async* {
  // Re-emit when session changes (logout clears active).
  ref.watch(sessionProvider);
  yield* ref.watch(profileRepositoryProvider).watchActive();
});

// Hive cache keys for the cache-first remote providers below. Stored in the
// shared cacheBox() as decoded JSON (same approach as the mantra catalogue).
const _kStoreCache = 'remote.store.payload';
const _kLeaderboardCachePrefix = 'remote.leaderboard.v2.';
const _kStatsCachePrefix = 'remote.stats.';

/// Live store catalogue from /api/v1/store — cache-first.
///
/// Emits the last cached catalogue instantly (no spinner on return visits or
/// when offline), then refreshes from the network. On a network error with a
/// cache present, the cached list is kept; only a cold first load with no
/// cache surfaces an error (so the Store screen can show Retry).
final storeItemsProvider = StreamProvider<List<StoreItem>>((ref) async* {
  final box = cacheBox();

  List<StoreItem> parse(dynamic raw) =>
      ((raw is Map ? raw['items'] : raw) as List<dynamic>? ?? const [])
          .map((e) => StoreItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

  final cached = box.get(_kStoreCache);
  if (cached != null) yield parse(cached);

  try {
    final api = ref.watch(apiClientProvider);
    final res = await api.dio.get<dynamic>('/api/v1/store');
    final data = res.data;
    await box.put(_kStoreCache, data);
    yield parse(data);
  } catch (_) {
    if (cached == null) rethrow; // cold + offline → Store screen shows Retry
  }
});

/// Global community statistics from /api/v1/stats?mantra_id= (public, no auth).
/// Refreshes every 30 seconds so the global count stays reasonably live without
/// hammering the API (the old 2-second loop caused a request storm when the
/// backend was unreachable). Call ref.invalidate(globalStatsProvider(id)) to
/// force an immediate refresh (e.g. after a practice session finishes).
final globalStatsProvider = FutureProvider.autoDispose
    .family<({int globalChantCount, int memberCount}), String>((ref, mantraId) async {
  // Keep the provider alive across re-builds while its widget is on screen,
  // but still allow disposal when the screen is gone.
  final link = ref.keepAlive();

  // Schedule a periodic re-fetch while the screen is mounted.
  final timer = Timer(const Duration(seconds: 30), () {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    timer.cancel();
    link.close();
  });

  final box = cacheBox();
  final cacheKey = '$_kStatsCachePrefix$mantraId';

  ({int globalChantCount, int memberCount}) cachedOrZero() {
    final raw = box.get(cacheKey);
    if (raw is Map) {
      return (
        globalChantCount: (raw['c'] as num?)?.toInt() ?? 0,
        memberCount: (raw['m'] as num?)?.toInt() ?? 0,
      );
    }
    return (globalChantCount: 0, memberCount: 0);
  }

  try {
    final api = ref.watch(apiClientProvider);
    final res = await api.dio.get<Map<String, dynamic>>(
      '/api/v1/stats?mantra_id=${Uri.encodeComponent(mantraId)}',
    );
    final data = res.data ?? {};
    final result = (
      globalChantCount: (data['global_chant_count'] as num?)?.toInt() ?? 0,
      memberCount: (data['member_count'] as num?)?.toInt() ?? 0,
    );
    await box.put(cacheKey, {'c': result.globalChantCount, 'm': result.memberCount});
    return result;
  } catch (_) {
    // Offline / server down: keep the last known totals instead of dropping
    // the global count to zero (which made the on-screen number flicker).
    return cachedOrZero();
  }
});

/// Reward economy rates sourced from FeatureFlags at /api/v1/config.
/// Flutter uses this only for UI feedback (haptics, milestone labels).
/// All actual earn/spend validation runs server-side.
final rewardRulesProvider = Provider<RewardRules>((ref) {
  final cfg = ref.watch(remoteConfigProvider).value ?? RemoteConfig.empty;
  return RewardRules.fromConfig(cfg);
});

/// Active FAQs from /api/v1/faqs. Cached 5 min via HTTP headers.
final faqsProvider = FutureProvider<List<({String question, String answer})>>((ref) async {
  try {
    final api = ref.watch(apiClientProvider);
    final res = await api.dio.get<Map<String, dynamic>>('/api/v1/faqs');
    final list = (res.data?['faqs'] as List<dynamic>?) ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return (question: m['question'] as String, answer: m['answer'] as String);
    }).toList();
  } catch (_) {
    return const [];
  }
});

/// App-wide settings from /api/v1/app-settings.
final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  try {
    final api = ref.watch(apiClientProvider);
    final res = await api.dio.get<Map<String, dynamic>>('/api/v1/app-settings');
    final d = res.data ?? <String, dynamic>{};
    return AppSettings(
      privacyPolicy: d['privacy_policy'] as String? ?? '',
      aboutApp: (d['about_app'] as String?)?.isNotEmpty == true ? d['about_app'] as String : null,
      logoUrl: d['app_logo_url'] as String?,
      inviteHost: (d['invite_host'] as String?)?.isNotEmpty == true
          ? d['invite_host'] as String
          : 'vaachakalekhini.com',
      appDownloadLink: (d['app_download_link'] as String?)?.isNotEmpty == true
          ? d['app_download_link'] as String
          : null,
      shareQuoteImageUrl: (d['share_quote_image_url'] as String?)?.isNotEmpty == true
          ? d['share_quote_image_url'] as String
          : null,
      shareQuoteText: (d['share_quote_text'] as String?)?.isNotEmpty == true
          ? d['share_quote_text'] as String
          : null,
    );
  } catch (_) {
    return const AppSettings(
      privacyPolicy: '',
      aboutApp: null,
      logoUrl: null,
      inviteHost: 'vaachakalekhini.com',
      appDownloadLink: null,
      shareQuoteImageUrl: null,
      shareQuoteText: null,
    );
  }
});

class AppSettings {
  const AppSettings({
    required this.privacyPolicy,
    required this.aboutApp,
    required this.logoUrl,
    required this.inviteHost,
    required this.appDownloadLink,
    required this.shareQuoteImageUrl,
    required this.shareQuoteText,
  });
  final String privacyPolicy;
  final String? aboutApp;
  final String? logoUrl;
  final String inviteHost;
  final String? appDownloadLink;
  final String? shareQuoteImageUrl;
  final String? shareQuoteText;
}

/// Real leaderboard from /api/v1/leaderboard (Bearer required) — cache-first.
/// Emits the last cached board for this sort instantly (no spinner on return
/// visits or when offline), then refreshes. Never throws: an error with no
/// cache yields an empty list so the Community screen shows its empty state.
final leaderboardProvider =
    StreamProvider.family<List<Friend>, LeaderboardFilter>((ref, filter) async* {
      final box = cacheBox();
      final sortParam =
          filter.sort == LeaderboardSort.streak ? 'streak' : 'total_chants';
      final cacheKey = '$_kLeaderboardCachePrefix${sortParam}_${filter.mantraId ?? 'all'}';

      List<Friend> parse(dynamic raw) =>
          ((raw as List<dynamic>?) ?? const []).map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            return Friend(
              id: m['id'] as String,
              name: m['name'] as String,
              longestStreak: (m['longest_streak'] as num?)?.toInt() ?? 0,
              currentStreak: (m['current_streak'] as num?)?.toInt() ?? 0,
              totalChants: (m['total_chants'] as num?)?.toInt() ?? 0,
              isSelf: m['is_self'] == true,
              streakActive: m['streak_active'] == true,
            );
          }).toList();

      final cached = box.get(cacheKey);
      if (cached != null) yield parse(cached);

      final session = ref.watch(sessionProvider).value;
      if (session == null) {
        if (cached == null) yield const <Friend>[];
        return;
      }

      try {
        final api = ref.watch(apiClientProvider);
        final mantraParam = filter.mantraId != null
            ? '&mantra_id=${filter.mantraId}'
            : '';
        final res = await api.dio.get<Map<String, dynamic>>(
          '/api/v1/leaderboard?sort=$sortParam$mantraParam',
        );
        final entries = (res.data?['entries'] as List<dynamic>?) ?? const [];
        await box.put(cacheKey, entries);
        yield parse(entries);
      } catch (e, st) {
        debugPrint('[leaderboard] fetch error: $e\n$st');
        if (cached == null) rethrow; // surface the error so UI can show Retry
      }
    });

/// Set of store item IDs the active member has already redeemed.
/// Empty when no profile is selected.
final redeemedItemIdsProvider = StreamProvider<Set<String>>((ref) async* {
  final profile = ref.watch(activeProfileProvider).value;
  if (profile == null) {
    yield const <String>{};
    return;
  }
  yield* ref.watch(rewardRepositoryProvider).watchRedeemedItemIds(profile.id);
});

// ── Global Sadhana ────────────────────────────────────────────────────────────

final globalSadhanaRepositoryProvider =
    Provider<GlobalSadhanaRepository>((ref) {
  return GlobalSadhanaRepository(
    api: ref.watch(apiClientProvider),
    cache: cacheBox(),
  );
});

/// Active global sadhanas. Seeds from Hive cache immediately, refreshes
/// from network and re-emits. Refreshes every 60 s while a screen is mounted.
final activeGlobalSadhanaProvider =
    StreamProvider<List<GlobalSadhana>>((ref) async* {
  final repo = ref.watch(globalSadhanaRepositoryProvider);
  // Instant from cache
  yield repo.cachedActive();
  // Network fetch
  final fresh = await repo.fetchActive();
  yield fresh;
  // Periodic background refresh while the stream is alive.
  await for (final _ in Stream<void>.periodic(const Duration(seconds: 60))) {
    yield await repo.fetchActive();
  }
});

/// Enrollment status for the active profile in a specific sadhana.
/// Null means not enrolled (or still loading).
final globalSadhanaEnrollmentProvider = FutureProvider.autoDispose
    .family<GlobalSadhanaEnrollment?, String>((ref, sadhanaId) async {
  final profile = ref.watch(activeProfileProvider).value;
  if (profile == null) return null;
  final repo = ref.watch(globalSadhanaRepositoryProvider);
  return repo.fetchEnrollment(sadhanaId, profile.id);
});

// ── Quotes ───────────────────────────────────────────────────────────────────

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return QuoteRepository(api: ref.watch(apiClientProvider), cache: cacheBox());
});

/// Active quotes from the server. Seeds from Hive cache immediately, then
/// fetches with mantra_ids filtered to the active member's programs.
final quotesProvider = StreamProvider<List<Quote>>((ref) async* {
  final repo = ref.watch(quoteRepositoryProvider);
  final programs = ref.watch(programsForActiveProfileProvider).value ?? [];
  final mantraIds = programs.map((p) => p.mantraId).toList();

  // Instant from cache (no mantra filtering at cache layer)
  yield repo.cachedQuotes();

  // Network fetch with mantra filter
  final fresh = await repo.fetchActive(mantraIds: mantraIds);
  yield fresh;

  // Refresh every 5 minutes
  await for (final _ in Stream<void>.periodic(const Duration(minutes: 5))) {
    yield await repo.fetchActive(mantraIds: mantraIds);
  }
});

/// Incremented each time a practice session is finished so that
/// DailyProgressScreen knows to reload its data.
class _SessionCompletedNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void increment() => state++;
}

final sessionCompletedProvider =
    NotifierProvider<_SessionCompletedNotifier, int>(
      _SessionCompletedNotifier.new,
    );

/// Sum of chants recorded across all sessions that started today (local time).
/// Rebuilds whenever [sessionCompletedProvider] increments.
final todayChantTotalProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(sessionCompletedProvider); // rebuild on session finish
  final db = ref.watch(appDatabaseProvider);
  final profile = ref.watch(activeProfileProvider).value;
  if (profile == null) return 0;
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final rows = await (db.select(db.sessions)
        ..where(
          (t) =>
              t.memberId.equals(profile.id) &
              t.startedAt.isBiggerOrEqualValue(startOfDay),
        ))
      .get();
  return rows.fold<int>(0, (sum, r) => sum + r.countAdded);
});
