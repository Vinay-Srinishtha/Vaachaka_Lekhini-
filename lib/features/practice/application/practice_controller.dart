import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../enrolment/voice/data/voice_enrolment_service.dart';
import '../../enrolment/voice/domain/voice_enrolment.dart';
import '../../mantras/domain/mantra.dart';
import '../../programs/domain/program.dart';
import '../../programs/domain/program_repository.dart';
import '../../programs/domain/session.dart';
import '../../rewards/domain/reward_repository.dart';
import '../../rewards/domain/reward_rules.dart';
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
  Timer? _flushTimer;
  int _pendingFlush = 0;

  ProgramRepository get _programs => ref.read(programRepositoryProvider);
  RewardRepository get _rewards => ref.read(rewardRepositoryProvider);

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

    return PracticeState(
      program: program,
      modality: SessionModality.voice,
      isRunning: false,
      sessionCount: 0,
      todaysTotal: todaysTotal,
      streak: streak,
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
        _voice = VoiceEnrolmentService();
        _voiceSub = _voice!.events.listen((e) {
          if (e.count > 0) _bump(s.sessionCount + e.count);
        }, onError: (Object err) => _failVoice("Voice recogniser stopped: $err"));
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
      final trained = await _hasCompletedVoiceTraining(s.program.mantraId);
      if (!trained) return;
      final ok = await _ensureMicReady();
      if (!ok) return;
    }

    // ADDED: pass memberId so Prisma Session row has it directly
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
      _voice = VoiceEnrolmentService();
      _voiceSub = _voice!.events.listen((e) {
        if (e.count > 0) _bump(e.count);
      }, onError: (Object err) => _failVoice("Voice recogniser stopped: $err"));
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

  Future<bool> _hasCompletedVoiceTraining(String mantraId) async {
    final profile = ref.read(activeProfileProvider).value;
    final s = state.value;
    if (profile == null) {
      if (s != null) {
        state = AsyncData(
          s.copyWith(
            errorMessage: 'Select a profile before starting voice practice.',
          ),
        );
      }
      return false;
    }
    final enrolment = await ref
        .read(voiceEnrolmentRepositoryProvider)
        .get(profile.id, mantraId);
    final complete = enrolment != null && enrolment.isComplete;
    if (!complete && s != null) {
      state = AsyncData(
        s.copyWith(
          errorMessage:
              'Complete voice training (${VoiceEnrolment.requiredSamples}/${VoiceEnrolment.requiredSamples}) before using voice practice.',
        ),
      );
    }
    return complete;
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
    state = AsyncData(
      s.copyWith(sessionCount: newCount, todaysTotal: s.todaysTotal + delta),
    );
  }

  Future<void> _flush() async {
    final s = state.value;
    final id = s?.activeSessionId;
    if (id == null || _pendingFlush <= 0) return;
    final delta = _pendingFlush;
    _pendingFlush = 0;
    await _programs.incrementSession(id, by: delta);
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

    // Award points: daily-target completion + any milestone crossed.
    // CHANGED: profileId → memberId
    final after = program.totalChants + program.totalWritings;
    if (today >= program.dailyTarget && (s.todaysTotal < program.dailyTarget)) {
      await _rewards.earn(
        memberId: program.memberId,
        amount: RewardRules.dailyTarget,
        source: 'Daily Mantra Completion',
      );
      unawaited(HapticFeedback.mediumImpact());
    }
    final milestone = RewardRules.milestoneCrossedLabel(before, after);
    if (milestone != null) {
      await _rewards.earn(
        memberId: program.memberId,
        amount: RewardRules.milestoneCross,
        source: 'Milestone: $milestone',
      );
      unawaited(HapticFeedback.heavyImpact());
    }

    state = AsyncData(
      s.copyWith(
        isRunning: false,
        sessionCount: 0,
        program: program,
        todaysTotal: today,
        streak: streak,
        clearSession: true,
      ),
    );
  }

  void _failVoice(String message) {
    final s = state.value;
    if (s != null) {
      state = AsyncData(s.copyWith(errorMessage: message));
    }
  }

  Future<void> _cleanup() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await _voiceSub?.cancel();
    _voiceSub = null;
    await _voice?.dispose();
    _voice = null;
    await _flush();
  }
}

final practiceControllerProvider =
    AsyncNotifierProvider.family<PracticeController, PracticeState, String>(
      PracticeController.new,
    );
