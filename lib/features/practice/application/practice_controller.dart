import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/storage/app_database.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../enrolment/voice/data/voice_enrolment_service.dart';
import '../../mantras/domain/mantra.dart';
import '../../programs/domain/program.dart';
import '../../programs/domain/program_repository.dart';
import '../../programs/domain/session.dart';
import '../../settings/domain/settings_repository.dart';

/// View-state for a single program's practice screen.
@immutable
class PracticeState {
  const PracticeState({
    required this.program,
    required this.modality,
    required this.isRunning,
    required this.sessionCount,
    required this.todaysTotal,
    required this.streak,
    this.activeSessionId,
    this.errorMessage,
    this.micPermanentlyDenied = false,
    this.targetReached = false,
    this.dailyGoalReached = false,
    this.draftCount,
    this.draftModality,
  });

  final Program program;
  final SessionModality modality;
  final bool isRunning;

  /// Counts emitted within the current session (resets to 0 on each start).
  final int sessionCount;

  /// Sum of every session today including [sessionCount] of the current open one.
  final int todaysTotal;
  final int streak;

  final String? activeSessionId;
  final String? errorMessage;

  /// True when the user has permanently denied the mic permission and the
  /// only way out is to open system settings.
  final bool micPermanentlyDenied;

  /// True when totalProgress just crossed targetWritings — triggers full-program dedication.
  final bool targetReached;

  /// True when todaysTotal just crossed effectiveDailyTarget — triggers daily goal sheet.
  final bool dailyGoalReached;

  /// Non-null when a draft session exists for this program (app was killed mid-session).
  final int? draftCount;
  final SessionModality? draftModality;

  PracticeState copyWith({
    Program? program,
    SessionModality? modality,
    bool? isRunning,
    int? sessionCount,
    int? todaysTotal,
    int? streak,
    String? activeSessionId,
    bool clearSession = false,
    String? errorMessage,
    bool clearError = false,
    bool? micPermanentlyDenied,
    bool? targetReached,
    bool? dailyGoalReached,
    int? draftCount,
    SessionModality? draftModality,
    bool clearDraft = false,
  }) => PracticeState(
    program: program ?? this.program,
    modality: modality ?? this.modality,
    isRunning: isRunning ?? this.isRunning,
    sessionCount: sessionCount ?? this.sessionCount,
    todaysTotal: todaysTotal ?? this.todaysTotal,
    streak: streak ?? this.streak,
    activeSessionId: clearSession
        ? null
        : (activeSessionId ?? this.activeSessionId),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    micPermanentlyDenied: micPermanentlyDenied ?? this.micPermanentlyDenied,
    targetReached: targetReached ?? this.targetReached,
    dailyGoalReached: dailyGoalReached ?? this.dailyGoalReached,
    draftCount: clearDraft ? null : (draftCount ?? this.draftCount),
    draftModality: clearDraft ? null : (draftModality ?? this.draftModality),
  );
}

/// Owns the live counting loop for one program. UI watches it for state;
/// it owns the (one) open Session row and the Vosk pipe in voice mode.
///
/// Riverpod 3 family pattern: the program id is supplied through the
/// constructor by the family provider's factory below.
class PracticeController extends AsyncNotifier<PracticeState> {
  PracticeController(this.programId);
  final String programId;

  VoiceEnrolmentService? _voice;
  StreamSubscription<VoiceTrainingEvent>? _voiceSub;
  StreamSubscription<double>? _levelSub;
  Timer? _flushTimer;
  int _pendingFlush = 0;

  /// Live mic input level (0..1) while a voice session captures. Drives the
  /// reactive voice waves without rebuilding the whole screen.
  final ValueNotifier<double> micLevel = ValueNotifier<double>(0);

  void _bindLevels() {
    _levelSub?.cancel();
    _levelSub = _voice?.levels.listen((lvl) => micLevel.value = lvl);
  }

  ProgramRepository get _programs => ref.read(programRepositoryProvider);

  AppDatabase get _db => ref.read(appDatabaseProvider);

  @override
  Future<PracticeState> build() async {
    ref.onDispose(_cleanup);
    final program = await _programs.getById(programId);
    if (program == null) {
      throw StateError('Program $programId not found');
    }
    final today = DateTime.now();
    final todaysTotal = await _programs.countForDay(programId, today);
    final streak = await _programs.currentStreak(programId);

    // Load any draft saved before last app kill.
    final draft = await _db.getDraft(programId);

    // When the DB changes (e.g. sync pulls updated streak / session data from
    // the server), refresh program stats so the counter screen never shows
    // stale values.  Skip while a session is active to avoid mid-session jumps.
    ref.listen(programsForActiveProfileProvider, (_, programs) async {
      final s = state.value;
      if (s == null || s.isRunning || s.activeSessionId != null) return;
      final updated = programs.value?.where((p) => p.id == programId).firstOrNull;
      if (updated == null) return;
      final today = DateTime.now();
      final newTotal = await _programs.countForDay(programId, today);
      final newStreak = await _programs.currentStreak(programId);
      state = AsyncData(
        s.copyWith(program: updated, todaysTotal: newTotal, streak: newStreak),
      );
    });

    return PracticeState(
      program: program,
      modality: SessionModality.voice,
      isRunning: false,
      sessionCount: 0,
      todaysTotal: todaysTotal,
      streak: streak,
      draftCount: (draft != null && draft.sessionCount > 0) ? draft.sessionCount : null,
      draftModality: draft != null ? SessionModality.fromName(draft.modality) : null,
    );
  }

  void setModality(SessionModality m) {
    final s = state.value;
    if (s == null || s.isRunning) return;
    state = AsyncData(s.copyWith(modality: m));
  }

  Future<void> start({Mantra? mantra}) async {
    final s = state.value;
    if (s == null || s.isRunning) return;

    // Resuming an already-open session — just restart the audio, keep count.
    if (s.activeSessionId != null) {
      state = AsyncData(s.copyWith(isRunning: true, clearError: true));
      if (s.modality == SessionModality.voice && mantra != null) {
        final sensitivity = ref.read(settingsProvider).value?.micSensitivity
            ?? MicSensitivity.medium;
        // Cancel any lingering voice session before starting a new one.
        await _voiceSub?.cancel();
        _voiceSub = null;
        await _voice?.dispose();
        _voice = VoiceEnrolmentService(
          recognizer: ref.read(voskRecognizerProvider).value,
        );
        _voiceSub = _voice!.events.listen((e) {
          if (e.count > 0) _bump(s.sessionCount + e.count);
        }, onError: (Object err) => _failVoice("Voice recogniser stopped: $err"));
        _bindLevels();
        try {
          await _voice!.start(mantra, target: 1 << 30, sensitivity: sensitivity);
        } catch (e) {
          _failVoice("Couldn't start the mic. Try again, or switch to Manual.");
        }
      }
      _flushTimer ??= Timer.periodic(const Duration(seconds: 4), (_) => _flush());
      return;
    }

    // Voice mode requires mic permission. Check up front and surface a
    // friendly state instead of crashing inside the audio stream.
    if (s.modality == SessionModality.voice) {
      final ok = await _ensureMicReady();
      if (!ok) return;
    }

    final profile = ref.read(activeProfileProvider).value;
    final session = await _programs.startSession(
      programId: s.program.id,
      memberId: profile?.id ?? s.program.memberId,
      modality: s.modality,
    );

    state = AsyncData(
      s.copyWith(
        isRunning: true,
        sessionCount: 0,
        activeSessionId: session.id,
        clearError: true,
      ),
    );

    if (s.modality == SessionModality.voice && mantra != null) {
      final sensitivity = ref.read(settingsProvider).value?.micSensitivity
          ?? MicSensitivity.medium;
      _voice = VoiceEnrolmentService(
        recognizer: ref.read(voskRecognizerProvider).value,
      );
      _voiceSub = _voice!.events.listen((e) {
        if (e.count > 0) _bump(e.count);
      }, onError: (Object err) => _failVoice("Voice recogniser stopped: $err"));
      _bindLevels();
      try {
        // High target so the service doesn't auto-stop while counting.
        await _voice!.start(mantra, target: 1 << 30, sensitivity: sensitivity);
      } catch (e) {
        _failVoice("Couldn't start the mic. Try again, or switch to Manual.");
      }
    }

    _flushTimer ??= Timer.periodic(const Duration(seconds: 4), (_) => _flush());
  }

  /// Returns true if the mic is usable (granted now or just granted by the
  /// system prompt). Returns false and sets an actionable error state when
  /// the user has denied — including a `micPermanentlyDenied` flag so the
  /// UI can offer "Open Settings".
  Future<bool> _ensureMicReady() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    final next = await Permission.microphone.request();
    if (next.isGranted) return true;

    final permanentlyDenied =
        next.isPermanentlyDenied || status.isPermanentlyDenied;
    final s = state.value;
    if (s != null) {
      state = AsyncData(
        s.copyWith(
          errorMessage: permanentlyDenied
              ? 'Mic access is blocked. Open Settings to enable it, or tap Manual to count by hand.'
              : 'Mic access is needed to count chants. Allow it, or switch to Manual.',
          micPermanentlyDenied: permanentlyDenied,
        ),
      );
    }
    return false;
  }

/// Triggered from the UI's "Open Settings" CTA when mic was permanently denied.
  Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  /// Clear the error after the user resolves it.
  void clearError() {
    final s = state.value;
    if (s != null) {
      state = AsyncData(
        s.copyWith(clearError: true, micPermanentlyDenied: false),
      );
    }
  }

  /// Manual tap-to-count entry point.
  Future<void> tap() async {
    final s = state.value;
    if (s == null || !s.isRunning) return;
    if (s.modality != SessionModality.manual) return;
    _bump(s.sessionCount + 1);
    unawaited(HapticFeedback.selectionClick());
  }

  /// VoiceEnrolmentService emits absolute counts; persist each net delta.
  void _bump(int newCount) {
    final s = state.value;
    if (s == null) return;
    final delta = newCount - s.sessionCount;
    if (delta <= 0) return;
    _pendingFlush += delta;

    final newTotal = s.todaysTotal + delta;
    final programTotal = s.program.totalProgress + newCount;
    final hitProgramTarget = !s.targetReached &&
        s.program.targetWritings > 0 &&
        programTotal >= s.program.targetWritings;
    final dailyGoal = s.program.effectiveDailyTarget;
    final hitDailyGoal = !s.dailyGoalReached &&
        dailyGoal > 0 &&
        s.todaysTotal < dailyGoal &&
        newTotal >= dailyGoal;

    state = AsyncData(s.copyWith(
      sessionCount: newCount,
      todaysTotal: newTotal,
      targetReached: hitProgramTarget ? true : null,
      dailyGoalReached: hitDailyGoal ? true : null,
    ));

    if (hitProgramTarget) {
      // Auto-pause so the dedication prompt can be shown.
      Future(() async {
        await _voice?.stop();
        await _flush();
        final cur = state.value;
        if (cur != null) state = AsyncData(cur.copyWith(isRunning: false));
      });
    }
  }

  Future<void> _flush() async {
    final s = state.value;
    final id = s?.activeSessionId;
    if (id == null || _pendingFlush <= 0) return;
    final delta = _pendingFlush;
    _pendingFlush = 0;
    await _programs.incrementSession(id, by: delta);
    // Keep draft in sync so the count survives an app kill.
    if (s != null && s.sessionCount > 0) {
      await _db.saveDraft(
        programId: programId,
        count: s.sessionCount,
        modality: s.modality.name,
      );
    }
  }

  /// Reload just the program object from DB (e.g. after a handwriting session
  /// updates totalWritings) without resetting the active voice/manual session.
  Future<void> reloadProgram() async {
    final s = state.value;
    if (s == null) return;
    final program = await _programs.getById(s.program.id);
    if (program == null) return;
    state = AsyncData(s.copyWith(program: program));
  }

  Future<void> pause() async {
    final s = state.value;
    if (s == null || !s.isRunning) return;
    await _voice?.stop();
    await _flush();
    state = AsyncData(s.copyWith(isRunning: false));
  }

  Future<void> finish() async {
    final s = state.value;
    final id = s?.activeSessionId;
    if (s == null || id == null) return;
    _flushTimer?.cancel();
    _flushTimer = null;
    await _voice?.stop();
    await _flush();
    final before = s.program.totalChants + s.program.totalWritings;
    await _programs.finishSession(id);
    final program = await _programs.getById(s.program.id) ?? s.program;
    final streak = await _programs.currentStreak(s.program.id);
    final today = await _programs.countForDay(s.program.id, DateTime.now());

    final after = program.totalChants + program.totalWritings;
    if (today >= program.dailyTarget && s.todaysTotal < program.dailyTarget) {
      unawaited(HapticFeedback.mediumImpact());
    }
    final rules = ref.read(rewardRulesProvider);
    if (rules.milestoneCrossedLabel(before, after) != null) {
      unawaited(HapticFeedback.heavyImpact());
    }

    // Session completed — discard any draft for this program.
    await _db.deleteDraft(programId);

    state = AsyncData(
      s.copyWith(
        isRunning: false,
        sessionCount: 0,
        program: program,
        todaysTotal: today,
        streak: streak,
        clearSession: true,
        targetReached: false,
        dailyGoalReached: false,
        clearDraft: true,
      ),
    );

    // Optimistically credit any enrolled global sadhana for this mantra so the
    // count/percentage/contribution update instantly, before the server pull.
    final added = after - before;
    if (added > 0) {
      final gsRepo = ref.read(globalSadhanaRepositoryProvider);
      final bumped = await gsRepo.applyLocalContribution(
        mantraId: s.program.mantraId,
        count: added,
      );
      if (bumped) {
        ref.invalidate(activeGlobalSadhanaProvider);
        ref.invalidate(globalSadhanaEnrollmentProvider);
      }
    }

    // Drain outbox → server computes reward points → pull /api/v1/me →
    // reconcileFromServer writes local earn event → rewardTotalProvider updates live.
    unawaited(ref.read(syncEngineProvider).syncNow());
  }

  /// Restore a draft session: opens a new Session row with the saved count.
  Future<void> restoreDraft() async {
    final s = state.value;
    if (s == null || s.draftCount == null || s.activeSessionId != null) return;

    final profile = ref.read(activeProfileProvider).value;
    final modality = s.draftModality ?? SessionModality.manual;
    final session = await _programs.startSession(
      programId: s.program.id,
      memberId: profile?.id ?? s.program.memberId,
      modality: modality,
    );

    final count = s.draftCount!;
    _pendingFlush = count;
    await _flush();

    state = AsyncData(
      s.copyWith(
        isRunning: false,
        sessionCount: count,
        modality: modality,
        activeSessionId: session.id,
        clearDraft: true,
        clearError: true,
      ),
    );
  }

  /// Discard a draft without restoring it.
  Future<void> discardDraft() async {
    await _db.deleteDraft(programId);
    final s = state.value;
    if (s != null) state = AsyncData(s.copyWith(clearDraft: true));
  }

  void _failVoice(String message) {
    final s = state.value;
    if (s != null) {
      state = AsyncData(s.copyWith(errorMessage: message));
    }
  }

  /// Fully release the mic + audio recorder when leaving the screen. The
  /// `record` plugin's recorder is a shared native resource — `pause()`/
  /// `finish()` only stop it, they don't dispose it, so a second program's
  /// capture collides with the first still-allocated recorder and the app
  /// crashes on the second session. This disposes it (the shared Vosk
  /// recogniser is left intact — the voice service doesn't own it). Pending
  /// counts are flushed first, so nothing is lost. Safe to call when idle.
  Future<void> releaseVoice() async {
    await _cleanup();
    final s = state.value;
    if (s != null && s.isRunning) {
      state = AsyncData(s.copyWith(isRunning: false));
    }
  }

  Future<void> _cleanup() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _voiceSub?.cancel();
    _voiceSub = null;
    await _levelSub?.cancel();
    _levelSub = null;
    micLevel.value = 0;
    await _voice?.dispose();
    _voice = null;
    await _flush();
  }
}

final practiceControllerProvider =
    AsyncNotifierProvider.family<PracticeController, PracticeState, String>(
      PracticeController.new,
    );
