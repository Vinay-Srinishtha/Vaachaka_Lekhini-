import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers.dart';
import '../../../core/audio/reward_sound_service.dart';
import '../../../l10n/l10n.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/phone/phone_mode_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../programs/domain/session.dart';
import '../../global_sadhana/domain/global_sadhana.dart';
import '../../programs/presentation/book_preview_sheet.dart';
import '../../programs/presentation/daily_progress_screen.dart';
import '../../settings/domain/settings_repository.dart';
import '../application/practice_controller.dart';

/// Live device ringer mode (silent / vibrate / ring), synced from the OS.
final _ringerModeProvider = StreamProvider.autoDispose<RingerMode>((ref) {
  return RingerModeService().watch();
});

/// Background Sruthi / ambient music toggle for the chant screen.
final _ambientOnProvider =
    NotifierProvider.autoDispose<_AmbientNotifier, bool>(_AmbientNotifier.new);

class _AmbientNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final _ambientPlayerProvider = Provider.autoDispose<AudioPlayer>((ref) {
  // Keep the player alive across reads — otherwise the autoDispose provider is
  // torn down right after the Sruthi tap (it's only read, never watched),
  // which stops playback instantly.
  ref.keepAlive();
  final player = AudioPlayer();
  player.setReleaseMode(ReleaseMode.loop);
  // Background Sruthi at 50% — present but never overpowering the chanting.
  player.setVolume(0.5);
  // Audio context: plays through silent/ringer switch on both platforms.
  // iOS: playback category bypasses the silent switch (unlike ambient/soloAmbient).
  // Android: usageType.media is not muted by silent mode (only ringtones are).
  player.setAudioContext(AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: true,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {
        AVAudioSessionOptions.mixWithOthers,
        AVAudioSessionOptions.defaultToSpeaker,
      },
    ),
  ));
  // Pre-load the asset so the first play is instant (no decode delay).
  // The source stays buffered; toggle uses resume()/pause() from here on.
  player.setSourceAsset('audio/ambient_loop.mp3');
  // Gapless fallback: if the native loop still fires a completion event,
  // seek back to zero and resume immediately so there is no audible gap.
  player.onPlayerComplete.listen((_) async {
    await player.seek(Duration.zero);
    await player.resume();
  });
  ref.onDispose(() {
    player.stop();
    player.dispose();
  });
  return player;
});

class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key, required this.programId});
  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(practiceControllerProvider(programId));
    return stateAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => KvlScaffold(
        title: 'Practice',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Could not load this Sadhana.\nIt may have been deleted.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (state) => _Body(programId: programId, state: state),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.programId, required this.state});
  final String programId;
  final PracticeState state;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _dedicationShown = false;
  bool _draftDialogShown = false;
  late final PracticeController _controllerForDispose;
  late final AudioPlayer _ambientPlayer;

  @override
  void initState() {
    super.initState();
    // Capture the notifier now — reading `ref` inside dispose() is unsafe in
    // Riverpod 3 and was crashing on navigation away from this screen.
    _controllerForDispose =
        ref.read(practiceControllerProvider(widget.programId).notifier);
    _ambientPlayer = ref.read(_ambientPlayerProvider);
    if ((widget.state.draftCount ?? 0) > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_draftDialogShown) {
          _draftDialogShown = true;
          _showRestoreDraftDialog(context);
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_maybeShowChantingTip());
    });
  }

  @override
  void dispose() {
    // Stop this program's voice/mic when leaving the screen. The Vosk
    // recogniser and the mic are single shared resources; leaving a session
    // running and then starting voice in another program drives two captures
    // into the one recogniser at once and crashes the app natively. Full
    // release (not just pause) so the mic recorder is disposed — otherwise the
    // next program's capture collides with this one and crashes on the second
    // session. Uses the notifier captured in initState — `ref` is unsafe here.
    Future.microtask(_controllerForDispose.releaseVoice);
    _ambientPlayer.stop(); // don't let ambient bleed into other screens
    super.dispose();
  }

  Future<void> _maybeShowChantingTip() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('tip_chanting_v2') == true) return;
    if (!mounted) return;
    var dontShowAgain = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _TipSheet(
        title: 'Chanting Tips',
        bullets: const [
          '• Press Start and chant along with the count',
          '• Tap Pause any time and resume when ready',
          '• Tap Finish to record your session',
          '• 📖 Tap the book badge (top-right) to preview your personal chanting book',
        ],
        initialDontShowAgain: dontShowAgain,
        onChanged: (v) => dontShowAgain = v,
      ),
    );
    if (dontShowAgain) {
      await prefs.setBool('tip_chanting_v2', true);
    }
  }

  Future<void> _showRestoreDraftDialog(BuildContext context) async {
    final controller = ref.read(
      practiceControllerProvider(widget.programId).notifier,
    );
    final count = widget.state.draftCount ?? 0;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: KvlRadius.brLG),
        title: const Text('Restore Draft Session?'),
        content: Text(
          'You have an unsaved session with '
          '${IndianNumberFormat.format(count)} chants.\n'
          'Would you like to restore it?',
          style: KvlText.body(13).copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.discardDraft();
            },
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.restoreDraft();
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final programId = widget.programId;
    final state = widget.state;

    ref.listen(practiceControllerProvider(programId), (_, next) {
      if (next.value?.targetReached == true &&
          !_dedicationShown &&
          context.mounted) {
        _dedicationShown = true;
        _showDedicationDialog(context, ref, programId);
      }
    });

    final mantra = ref.watch(mantraByIdProvider(state.program.mantraId));
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final controller = ref.read(practiceControllerProvider(programId).notifier);
    final ringerMode =
        ref.watch(_ringerModeProvider).value ?? RingerMode.unknown;
    final statsAsync = ref.watch(globalStatsProvider(state.program.mantraId));
    // If the user is enrolled in an active Global Sadhana for this mantra, show
    // that sadhana's live progress as the "Global" base instead of the broad
    // community chant stat — this is the programme the user is contributing to.
    final sadhanas = ref.watch(activeGlobalSadhanaProvider).value ?? const [];
    final gsRepo = ref.read(globalSadhanaRepositoryProvider);
    int? enrolledGlobalCount;
    for (final gs in sadhanas) {
      if (gs.mantraId == state.program.mantraId &&
          gsRepo.cachedEnrollment(gs.id) != null) {
        enrolledGlobalCount = gs.currentCount;
        break;
      }
    }
    final globalBase =
        enrolledGlobalCount ?? (statsAsync.value?.globalChantCount ?? 0);
    final globalCount = globalBase + state.sessionCount;
    final mantraLabel =
        mantra?.name.displayForLanguage(settings.languageCode) ??
        state.program.mantraId;

    return Scaffold(
      backgroundColor: KvlColors.bg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, c) {
            final h = c.maxHeight;
            final compact = h < 760;
            final micSize = compact ? 76.0 : 96.0;
            final bottomPad =
                MediaQuery.of(context).padding.bottom + (compact ? 8.0 : 14.0);

            return Padding(
              padding: EdgeInsets.fromLTRB(
                KvlSpacing.lg,
                compact ? 4 : 10,
                KvlSpacing.lg,
                0,
              ),
              child: Column(
                children: [
                  _TopBar(
                    compact: compact,
                    sessionCount: state.sessionCount,
                    mantraId: state.program.mantraId,
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(KvlRoute.programs);
                      }
                    },
                    onWritingMode: () => context.push(
                      '${KvlRoute.handwritingWrite}/${state.program.mantraId}?programId=$programId',
                    ),
                    ringerMode: ringerMode,
                    onCycleRinger: () => _cycleRingerMode(ref),
                  ),
                  SizedBox(height: compact ? 10 : 16),
                  Expanded(
                    child: _HeroMic(
                      micSize: micSize,
                      mantraLabel: mantraLabel,
                      compact: compact,
                      isRunning: state.isRunning,
                      isVoiceMode: state.modality == SessionModality.voice,
                      sessionCount: state.sessionCount,
                      level: controller.micLevel,
                      onTap: state.isRunning
                          ? controller.pause
                          : () => controller.start(mantra: mantra),
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  _Counts(
                    globalCount: globalCount,
                    added: state.sessionCount,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  _ActionRow(
                    compact: compact,
                    showFinish: state.activeSessionId != null,
                    startLabel: state.activeSessionId == null
                        ? context.l10n.startButton
                        : state.isRunning
                        ? context.l10n.pauseButton
                        : context.l10n.resumeButton,
                    startIcon: state.isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    onStart: state.isRunning
                        ? controller.pause
                        : () => controller.start(mantra: mantra),
                    onFinish: () async {
                      if (state.activeSessionId == null) return;

                      // Goal-less ("open") program: finish then ask build/bonus.
                      if (!state.program.hasGoal) {
                        final beforeTotal = state.program.totalProgress;
                        await controller.finish();
                        if (!context.mounted) return;
                        ref.read(sessionCompletedProvider.notifier).increment();
                        ref.invalidate(globalStatsProvider(state.program.mantraId));
                        final afterState = ref.read(practiceControllerProvider(programId)).value;
                        final sessionTotal = (afterState != null)
                            ? (afterState.program.totalProgress - beforeTotal).clamp(0, 999999)
                            : state.sessionCount;
                        final build = await _askBuildOrBonus(context, sessionTotal);
                        if (!context.mounted) return;
                        if (build == true) {
                          context.go(
                            '${KvlRoute.setTargetWritings}/${state.program.mantraId}'
                            '?programId=${state.program.id}',
                          );
                        } else {
                          context.go(KvlRoute.home);
                        }
                        return;
                      }

                      // Program with goal: check if daily target is met BEFORE finishing.
                      final dailyTarget = state.program.effectiveDailyTarget;
                      final todaysTotal = ref.read(practiceControllerProvider(programId)).value?.todaysTotal ?? 0;
                      final projected = todaysTotal + state.sessionCount;
                      if (dailyTarget > 0 && projected < dailyTarget) {
                        final remaining = dailyTarget - projected;
                        final shouldContinue = await _showGoalIncompleteSheet(context, remaining);
                        if (!context.mounted) return;
                        if (shouldContinue == true) return; // user chose to continue chanting
                        // User chose "Complete Session" — fall through to finish.
                      }

                      await controller.finish();
                      if (!context.mounted) return;
                      ref.read(sessionCompletedProvider.notifier).increment();
                      ref.invalidate(globalStatsProvider(state.program.mantraId));

                      // Show goal-completed celebration if target was just hit.
                      final afterState = ref.read(practiceControllerProvider(programId)).value;
                      if (afterState != null && dailyTarget > 0 &&
                          (afterState.todaysTotal >= dailyTarget)) {
                        await _showDailyGoalSheet(context, ref, programId);
                        if (!context.mounted) return;
                      }

                      context.go(KvlRoute.home);
                    },
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    _MicErrorCard(
                      message: state.errorMessage!,
                      requiresTraining: state.errorMessage!.startsWith(
                        'Complete voice training',
                      ),
                      showOpenSettings: state.micPermanentlyDenied,
                      onTrainVoice: () => context.push(
                        '${KvlRoute.voiceTraining}/${state.program.mantraId}?retrain=1',
                      ),
                      onOpenSettings: controller.openSystemSettings,
                      onSwitchManual: () {
                        controller.setModality(SessionModality.manual);
                        controller.clearError();
                      },
                      onDismiss: controller.clearError,
                    ),
                  ] else ...[
                    SizedBox(height: compact ? 6 : 8),
                    _ProgressCard(state: state, compact: compact),
                  ],
                  SizedBox(height: bottomPad),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Asked on Finish when the program has no goal yet. Returns true to build
  /// it into a targeted program, false (or null) to keep it as bonus chants.
  Future<bool?> _askBuildOrBonus(BuildContext context, int sessionTotal) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: KvlRadius.brLG),
        backgroundColor: Colors.white,
        title: Text(
          'Build this into a program?',
          style: KvlText.title(16),
        ),
        content: Text(
          'You completed ${IndianNumberFormat.format(sessionTotal)} chants. '
          'Set a goal to make this a tracked program, or keep them as bonus chants.',
          style: KvlText.body().copyWith(height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: Text(
              'Keep as bonus',
              style: KvlText.ui(13, FontWeight.w600)
                  .copyWith(color: KvlColors.primaryDeep),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: KvlColors.primary,
              shape: RoundedRectangleBorder(borderRadius: KvlRadius.brMD),
            ),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(
              'Build a program',
              style: KvlText.ui(13, FontWeight.w700)
                  .copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDedicationDialog(
    BuildContext context,
    WidgetRef ref,
    String programId,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DedicationDialog(
        onDedicate: () async {
          Navigator.of(context).pop();

          // Mark the session as finished and the program as completed.
          final controller = ref.read(
            practiceControllerProvider(programId).notifier,
          );
          final mantraId = ref
              .read(practiceControllerProvider(programId))
              .value
              ?.program
              .mantraId;
          await controller.finish();
          if (mantraId != null) ref.invalidate(globalStatsProvider(mantraId));
          final program = ref
              .read(practiceControllerProvider(programId))
              .value
              ?.program;
          final mantraName = mantraId != null
              ? (ref.read(mantraByIdProvider(mantraId))?.name.devanagari ?? '')
              : '';
          if (program != null && !program.isCompleted) {
            await ref
                .read(programRepositoryProvider)
                .update(program.copyWith(completedAt: DateTime.now()));
          }

          if (!context.mounted) return;

          // Show the dedication sheet before leaving the counter screen.
          await DedicateSheet.show(
            context,
            programId: programId,
            mantraName: mantraName,
          );

          if (!context.mounted) return;
          // Navigate to the programs list so the user sees the completed
          // program card (disabled) — clears the full navigation stack.
          context.go(KvlRoute.programs);
        },
      ),
    );
  }

  /// Shows the "daily goal incomplete" sheet. Returns true if user wants to
  /// continue chanting, false/null if they chose "Complete Session".
  Future<bool?> _showGoalIncompleteSheet(BuildContext context, int remaining) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalIncompleteSheet(remaining: remaining),
    );
  }

  /// Shows the "daily goal reached" celebration sheet on explicit Finish.
  Future<void> _showDailyGoalSheet(
    BuildContext context,
    WidgetRef ref,
    String programId,
  ) async {
    final programState =
        ref.read(practiceControllerProvider(programId)).value;
    final mantraId = programState?.program.mantraId;
    final todaysCount = programState?.todaysTotal ?? 0;

    // Check if there's an active Global Sadhana for this mantra that the user
    // is enrolled in — if so show the Global Sadhana celebration sheet instead.
    GlobalSadhana? gsMatch;
    if (mantraId != null) {
      final sadhanas =
          ref.read(activeGlobalSadhanaProvider).value ?? const [];
      final gsRepo = ref.read(globalSadhanaRepositoryProvider);
      for (final s in sadhanas) {
        if (s.mantraId == mantraId && s.isActive) {
          final enr = gsRepo.cachedEnrollment(s.id);
          if (enr != null) {
            gsMatch = s;
            break;
          }
        }
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DailyGoalSheet(
        mantraId: mantraId,
        globalSadhana: gsMatch,
        todaysCount: todaysCount,
      ),
    );
  }

  Future<void> _cycleRingerMode(WidgetRef ref) async {
    // The OS broadcast drives _ringerModeProvider, so the UI updates itself.
    await RingerModeService().cycle();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.compact,
    required this.sessionCount,
    required this.onBack,
    required this.onWritingMode,
    required this.ringerMode,
    required this.onCycleRinger,
    required this.mantraId,
  });
  final bool compact;
  final int sessionCount;
  final VoidCallback onBack;
  final VoidCallback onWritingMode;
  final RingerMode ringerMode;
  final VoidCallback onCycleRinger;
  final String mantraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Single diameter shared by every top-bar button so back / ringer /
    // writing all render at exactly the same size.
    final double btn = compact ? 44 : 50;
    final double labelH = compact ? 15 : 18;

    final (ringerIcon, ringerLabel) = switch (ringerMode) {
      RingerMode.silent => (Icons.notifications_off_rounded, 'Silent'),
      RingerMode.vibrate => (Icons.vibration_rounded, 'Vibrate'),
      RingerMode.normal => (Icons.notifications_active_rounded, 'Ring'),
      RingerMode.unknown => (Icons.notifications_none_rounded, 'Ringer'),
    };

    // One identically-shaped slot per button: a [btn]-sized circle on top and
    // a fixed-height label area below (kept even when empty) so every column
    // is the same height — equal top/bottom padding for all four.
    Widget slot({
      required Widget circle,
      required VoidCallback onTap,
      String? label,
    }) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: btn,
                height: btn,
                child: Center(child: circle),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: labelH,
                child: label == null
                    ? null
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: KvlText.caption(
                            compact ? 11 : 12,
                          ).copyWith(color: KvlColors.inkSoft),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    Widget iconCircle(IconData icon) =>
        Icon(icon, size: btn * 0.62, color: const Color(0xFF252525));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: slot(
            circle: iconCircle(Icons.arrow_back_rounded),
            onTap: onBack,
          ),
        ),
        Expanded(
          child: slot(
            circle: iconCircle(ringerIcon),
            onTap: onCycleRinger,
            label: ringerLabel,
          ),
        ),
        Expanded(
          child: slot(
            circle: iconCircle(Icons.draw_outlined),
            onTap: onWritingMode,
            label: 'Write',
          ),
        ),
        Expanded(
          child: slot(
            circle: iconCircle(ref.watch(_ambientOnProvider)
                ? Icons.music_note_rounded
                : Icons.music_off_rounded),
            label: 'Ambient',
            onTap: () async {
              ref.read(_ambientOnProvider.notifier).toggle();
              final player = ref.read(_ambientPlayerProvider);
              if (ref.read(_ambientOnProvider)) {
                // Source is pre-loaded — resume is instant with no gap.
                await player.resume();
              } else {
                await player.pause();
              }
            },
          ),
        ),
        // Reward points + book count stacked in the top-right.
        // Matches slot() height: btn circle area + 2px gap + labelH label area.
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: btn,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _PointsBadge(compact: compact, sessionCount: sessionCount),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: labelH,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: _BookCountBadge(compact: compact, mantraId: mantraId),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Book count badge — icon + number only, sits below the points chip
// ─────────────────────────────────────────────────────────────────────────────

class _BookCountBadge extends ConsumerWidget {
  const _BookCountBadge({required this.compact, required this.mantraId});
  final bool compact;
  final String mantraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(bookAssetsProvider(mantraId)).value?.length ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => BookPreviewButton.openSheet(context, mantraId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: KvlColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KvlColors.border, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: compact ? 13 : 15,
              color: KvlColors.primaryDeep,
            ),
            const SizedBox(width: 4),
            Text(
              IndianNumberFormat.format(count),
              style: KvlText.ui(compact ? 11 : 12, FontWeight.w800)
                  .copyWith(color: KvlColors.primaryDeep),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero mic with ripple animations
// ─────────────────────────────────────────────────────────────────────────────

class _HeroMic extends StatefulWidget {
  const _HeroMic({
    required this.micSize,
    required this.mantraLabel,
    required this.compact,
    required this.isRunning,
    required this.isVoiceMode,
    required this.onTap,
    required this.sessionCount,
    required this.level,
  });
  final double micSize;
  final String mantraLabel;
  final bool compact;
  final bool isRunning;
  final bool isVoiceMode;
  final VoidCallback onTap;
  final int sessionCount;

  /// Live mic level (0..1) driving the reactive voice waves.
  final ValueListenable<double> level;

  @override
  State<_HeroMic> createState() => _HeroMicState();
}

class _HeroMicState extends State<_HeroMic> with TickerProviderStateMixin {
  static const _poolSize = 4;

  // Darker, more saturated ripple palette so the rings read clearly against
  // the cream background.
  static const _ringColors = [
    Color(0xFFD2691E),
    Color(0xFFC75D24),
    Color(0xFFB8521C),
    Color(0xFFCC6A2B),
    Color(0xFFA8481A),
    Color(0xFFBE5E20),
  ];

  late List<AnimationController> _pool;
  int _nextSlot = 0;
  DateTime? _lastCountTime;
  final List<double> _slotIntensity = List.filled(_poolSize, 0.5);
  late AnimationController _textCtrl;

  @override
  void initState() {
    super.initState();
    _pool = List.generate(
      _poolSize,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      ),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    if (widget.isRunning) _textCtrl.reset();
  }

  @override
  void didUpdateWidget(_HeroMic old) {
    super.didUpdateWidget(old);
    if (widget.isRunning && !old.isRunning) {
      _textCtrl.reset();
    } else if (!widget.isRunning && old.isRunning) {
      _stopAll();
    }
    if (widget.sessionCount != old.sessionCount && widget.isRunning) {
      if (widget.isVoiceMode) _fireRipple();
      _textCtrl.forward(from: 0);
    }
  }

  void _fireRipple() {
    final now = DateTime.now();
    double intensity = 0.5;
    if (_lastCountTime != null) {
      final ms = now.difference(_lastCountTime!).inMilliseconds;
      intensity = (1.0 - ((ms - 300) / 2700)).clamp(0.18, 0.82);
    }
    _lastCountTime = now;

    final slot = _nextSlot % _poolSize;
    _nextSlot++;
    _slotIntensity[slot] = intensity;

    _pool[slot].duration = Duration(
      milliseconds: (1900 - intensity * 450).round(),
    );
    _pool[slot].forward(from: 0);
  }

  void _stopAll() {
    for (final c in _pool) {
      c.stop();
      c.reset();
    }
    _textCtrl.stop();
    _textCtrl.reset();
  }

  @override
  void dispose() {
    for (final c in _pool) {
      c.dispose();
    }
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final micDiam = widget.micSize * 1.4;
        // Visible orb is smaller than the ripple base, and the waves scale to it.
        final orbDiam = widget.micSize * 1.05;
        final maxDiam = constraints.biggest.longestSide * 3.2;

        // Vertical position of the "Shankara" title — the midpoint between the
        // stack top and the mic orb's top edge. The soft glow shares this so it
        // reads as centred on the title.
        final titleAlignY = () {
          final h = constraints.maxHeight;
          final micCenterY = h / 2 + 0.76 * (h / 2);
          final micTopY = micCenterY - orbDiam / 2;
          final midY = micTopY / 2;
          return (midY - h / 2) / (h / 2);
        }();

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Soft static glow — centred on the "Shankara" title.
            Align(
              alignment: Alignment(0, titleAlignY),
              child: Container(
                width: widget.micSize * 3.0,
                height: widget.micSize * 3.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(
                        0xFFFFC58A,
                      ).withValues(alpha: widget.isRunning ? 0.26 : 0.12),
                      const Color(
                        0xFFFF8C42,
                      ).withValues(alpha: widget.isRunning ? 0.12 : 0.05),
                      KvlColors.primary.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // Outward ripples — fired on each voice count. Emanate from the
            // centre of the "Shankara" title and grow outwards.
            for (var i = 0; i < _poolSize; i++)
              Align(
                alignment: Alignment(0, titleAlignY),
                child: AnimatedBuilder(
                  animation: _pool[i],
                  builder: (ctx2, _) {
                    final raw = _pool[i].value;
                    if (raw == 0.0) return const SizedBox.shrink();
                    final t = Curves.easeOut.transform(raw);
                    final intensity = _slotIntensity[i];
                    final reach = micDiam + (maxDiam - micDiam) * intensity;
                    // Grow from the centre point (≈0) outward, so the ring
                    // emanates from the title's centre rather than popping in
                    // already-large (which read as the circle drifting down).
                    final diam = reach * t;
                    final opacity = ((1.0 - t) * 0.34 * intensity).clamp(
                      0.0,
                      0.34,
                    );
                    final color = _ringColors[i % _ringColors.length];
                    return Container(
                      width: diam,
                      height: diam,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            color.withValues(alpha: 0.0),
                            color.withValues(alpha: opacity * 0.3),
                            color.withValues(alpha: opacity),
                          ],
                          stops: const [0.0, 0.60, 1.0],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Mantra title — FIXED position & size in both idle and running.
            // Vertically centred in the gap between the top bar (stack top)
            // and the top edge of the mic orb (orb centre sits at y=0.76).
            Align(
              alignment: Alignment(0, titleAlignY),
              child: AnimatedBuilder(
                animation: _textCtrl,
                builder: (ctx2, _) {
                  // Per-count pulse: quick shrink-and-back with a colour flash,
                  // anchored in place (does not move the title).
                  final dip = math.sin(_textCtrl.value * math.pi); // 0→1→0
                  final scale = 1.0 - 0.06 * dip;
                  final color = Color.lerp(
                    const Color(0xFFCC7A3A),
                    const Color(0xFF7E2F08),
                    dip,
                  )!;
                  return Transform.scale(
                    scale: scale,
                    child: SizedBox(
                      width: constraints.maxWidth * 0.9,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.mantraLabel,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: TextStyle(
                            // Reduced from 0.40 / 90 cap per design — smaller
                            // Sri Rama heading on the practice screen.
                            fontSize: (constraints.maxWidth * 0.28).clamp(
                              26.0,
                              60.0,
                            ),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Reactive curved sound waves — centred on the mic, only while a
            // voice session is capturing.
            if (widget.isRunning && widget.isVoiceMode)
              Align(
                // Slightly lower than the orb (0.76) so the arcs centre on the
                // mic button rather than riding its top edge.
                alignment: const Alignment(0, 0.92),
                child: IgnorePointer(
                  child: SizedBox(
                    width: orbDiam * 2.7,
                    height: orbDiam * 1.7,
                    child: _VoiceWaves(level: widget.level),
                  ),
                ),
              ),

            // Mic orb — FIXED size & position in both states (a bit smaller).
            // Same alignment as the waves so they flank the mic (not below it).
            Align(
              alignment: const Alignment(0, 0.76),
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  width: orbDiam,
                  height: orbDiam,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Richer multi-stop sheen — bright top-left highlight into
                    // a deep base for a premium, glossy orb.
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFE0BE),
                        Color(0xFFFFC08A),
                        KvlColors.primary,
                        KvlColors.primaryDeep,
                        Color(0xFFB8521C),
                      ],
                      stops: [0.0, 0.22, 0.55, 0.85, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: KvlColors.primaryDeep.withValues(alpha: 0.30),
                        blurRadius: 32,
                        spreadRadius: 2,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: KvlColors.primary.withValues(alpha: 0.42),
                        blurRadius: 26,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.55),
                        blurRadius: 2,
                        spreadRadius: -2,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: orbDiam * 0.5,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Animated curved sound waves that flank the mic while capturing voice.
/// Concentric theme-coloured arcs radiate outward on both sides, with a
/// travelling shimmer driven by a looping controller.
class _VoiceWaves extends StatefulWidget {
  const _VoiceWaves({required this.level});

  /// Live mic level (0..1) — more/brighter layers as the input gets louder.
  final ValueListenable<double> level;

  @override
  State<_VoiceWaves> createState() => _VoiceWavesState();
}

class _VoiceWavesState extends State<_VoiceWaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  // Smoothed level so the layers ease in/out instead of jittering per chunk.
  double _smooth = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_ctrl, widget.level]),
      builder: (_, _) {
        final target = widget.level.value.clamp(0.0, 1.0);
        // Ease toward the target; rise quickly, fall a little slower.
        _smooth += (target - _smooth) * (target > _smooth ? 0.45 : 0.18);
        return CustomPaint(
          size: Size.infinite,
          painter: _VoiceWavesPainter(phase: _ctrl.value, level: _smooth),
        );
      },
    );
  }
}

class _VoiceWavesPainter extends CustomPainter {
  _VoiceWavesPainter({required this.phase, required this.level});
  final double phase;
  final double level; // 0..1 smoothed mic level

  // Deeper warm palette — saffron/amber tints, darker than before so the
  // curved waves stand out against the cream background.
  static const _waveColors = [
    Color(0xFFE0915A),
    Color(0xFFD17E45),
    Color(0xFFD9874F),
    Color(0xFFC56E38),
    Color(0xFFDB9A66),
  ];

  static const _maxLayers = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.height; // scale everything to the band height
    final micR = unit * 0.31; // start just outside the mic
    final spacing = unit * 0.078; // tighter spacing → smaller wave footprint

    // One faint layer at rest; extra layers fade in as volume rises.
    final activeLayers = (1 + level * (_maxLayers - 1));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Right side anchored at 0 rad, left side at pi.
    for (final side in [0.0, math.pi]) {
      for (var k = 0; k < _maxLayers; k++) {
        // How "present" this layer is (0..1) — partial fade as it activates.
        final presence = (activeLayers - k).clamp(0.0, 1.0);
        if (presence <= 0.01) continue;

        final radius = micR + spacing * (k + 1);
        // Travelling shimmer: peaks move outward as phase advances.
        final wave = math.sin(2 * math.pi * phase - k * 0.9);
        final amp = (0.45 + 0.55 * ((wave + 1) / 2)).clamp(0.0, 1.0);
        final color = _waveColors[k % _waveColors.length];
        paint
          ..color = color.withValues(alpha: (0.16 + 0.42 * amp) * presence)
          ..strokeWidth = unit * 0.034;
        // Arc length grows with amplitude and the live level.
        final half = (0.34 + 0.16 * amp + 0.12 * level);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          side - half,
          half * 2,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_VoiceWavesPainter old) =>
      old.phase != phase || old.level != level;
}

// ─────────────────────────────────────────────────────────────────────────────
// Count display
// ─────────────────────────────────────────────────────────────────────────────

class _Counts extends StatelessWidget {
  const _Counts({
    required this.globalCount,
    required this.added,
    required this.compact,
  });

  /// Live global total for this mantra INCLUDING this session's [added].
  final int globalCount;

  /// This session's live count (the green "+N" that grows on every chant).
  final int added;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Server total "till now" (excludes the live session adds shown separately).
    final globalBase = (globalCount - added).clamp(0, globalCount);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: KvlSpacing.lg,
          vertical: compact ? 7 : 9,
        ),
        decoration: BoxDecoration(
          borderRadius: KvlRadius.brPill,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFFF1E2)],
          ),
          border: Border.all(
            color: KvlColors.primary.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: KvlColors.primary.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.public_rounded,
                size: compact ? 15 : 17,
                color: KvlColors.primaryDeep,
              ),
              const SizedBox(width: 7),
              Text(
                'Global  ',
                style: KvlText.ui(
                  compact ? 12 : 13,
                  FontWeight.w600,
                ).copyWith(color: KvlColors.inkSoft),
              ),
              Text(
                IndianNumberFormat.format(globalBase),
                style: KvlText.ui(
                  compact ? 16 : 19,
                  FontWeight.w800,
                ).copyWith(color: const Color(0xFFCC6A2B)),
              ),
              Text(
                '  +  ',
                style: KvlText.ui(
                  compact ? 16 : 19,
                  FontWeight.w600,
                ).copyWith(color: const Color(0xFF9A8678)),
              ),
              // The live session count pops on each increment so the number
              // animates in lockstep with the title pulse + ripple (same
              // rebuild), instead of snapping instantly while they ease.
              TweenAnimationBuilder<double>(
                key: ValueKey(added),
                tween: Tween(begin: added > 0 ? 1.14 : 1.0, end: 1.0),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Text(
                  IndianNumberFormat.format(added),
                  style: KvlText.ui(
                    compact ? 16 : 19,
                    FontWeight.w800,
                  ).copyWith(color: const Color(0xFF16A34A)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointsBadge extends ConsumerStatefulWidget {
  const _PointsBadge({required this.compact, required this.sessionCount});
  final bool compact;
  final int sessionCount;

  @override
  ConsumerState<_PointsBadge> createState() => _PointsBadgeState();
}

class _PointsBadgeState extends ConsumerState<_PointsBadge>
    with SingleTickerProviderStateMixin {
  // Tracks completed 11-count milestones in the current session.
  int _prevSessionMilestones = 0;
  int _delta = 0;
  late final AnimationController _anim;
  late final Animation<double> _offsetAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _offsetAnim = Tween<double>(begin: 0, end: -28).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
    _fadeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_anim);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_PointsBadge old) {
    super.didUpdateWidget(old);
    if (old.sessionCount != widget.sessionCount) {
      // Run after the current frame so setState is safe.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkSessionMilestone(widget.sessionCount);
      });
    }
  }

  // Animate only when another 11-chant milestone is crossed in the session.
  void _checkSessionMilestone(int sessionCount) {
    final milestones = sessionCount ~/ 11;
    if (milestones > _prevSessionMilestones) {
      final gained = milestones - _prevSessionMilestones;
      setState(() => _delta = gained);
      _anim.forward(from: 0);
      unawaited(RewardSoundService.instance.playBell());
      _prevSessionMilestones = milestones;
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(rewardTotalProvider).value;
    if (points == null) return const SizedBox.shrink();
    final compact = widget.compact;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 13,
            vertical: compact ? 4 : 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF3D8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8C04A), width: 1.1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: compact ? 13 : 15, color: KvlColors.gold),
              const SizedBox(width: 4),
              Text(
                '${IndianNumberFormat.format(points)} pts',
                style: KvlText.ui(compact ? 12 : 13, FontWeight.w700)
                    .copyWith(color: const Color(0xFF5a4400)),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, child) {
            if (_anim.isDismissed) return const SizedBox.shrink();
            return Positioned(
              top: _offsetAnim.value,
              child: Opacity(opacity: _fadeAnim.value, child: child),
            );
          },
          child: Text(
            '+${IndianNumberFormat.format(_delta)} pts',
            style: KvlText.ui(compact ? 12 : 13, FontWeight.w800)
                .copyWith(color: const Color(0xFF16A34A)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action row (PAUSE / Finish buttons)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.compact,
    required this.startLabel,
    required this.startIcon,
    required this.onStart,
    required this.onFinish,
    required this.showFinish,
  });
  final bool compact;
  final String startLabel;
  final IconData startIcon;
  final VoidCallback onStart;
  final VoidCallback? onFinish;

  /// Finish only appears once a session is active — before the first START
  /// the Start button spans the full width on its own.
  final bool showFinish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Before a session: Start spans full width (flex doesn't matter, it's
        // the only child). After start: Pause/Resume takes 1/4, Finish 3/4.
        Expanded(
          flex: 1,
          child: _ActionButton(
            label: startLabel,
            icon: startIcon,
            color: KvlColors.primary,
            onTap: onStart,
            compact: compact,
          ),
        ),
        if (showFinish) ...[
          const SizedBox(width: KvlSpacing.md),
          Expanded(
            flex: 3,
            child: _ActionButton(
              label: context.l10n.finishButton,
              color: KvlColors.accent,
              onTap: onFinish,
              compact: compact,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    required this.compact,
    this.icon,
  });
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool compact;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final radius = BorderRadius.circular(compact ? 16 : 20);

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: Colors.white,
          border: Border.all(color: color, width: 1.8),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: color.withValues(alpha: 0.10),
            highlightColor: color.withValues(alpha: 0.06),
            child: SizedBox(
              height: compact ? 48 : 54,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: color, size: 21),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: KvlText.ui(
                          compact ? 15 : 18,
                          FontWeight.w800,
                        ).copyWith(color: color, letterSpacing: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today's progress card
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.state, required this.compact});
  final PracticeState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final total = state.program.totalProgress + state.sessionCount;
    final goal = state.program.targetWritings;
    final progress = goal == 0 ? 0.0 : (total / goal).clamp(0, 1).toDouble();
    return Padding(
      // Transparent — blends with the screen background (no card surface).
      padding: const EdgeInsets.symmetric(
        horizontal: KvlSpacing.md,
        vertical: KvlSpacing.xs,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Progress',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KvlText.title(
                    compact ? 13 : 15,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: KvlSpacing.sm),
              Flexible(
                flex: 0,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${IndianNumberFormat.format(total)} / ${IndianNumberFormat.format(goal)}',
                    maxLines: 1,
                    style: KvlText.caption(
                      compact ? 11 : 12,
                    ).copyWith(color: KvlColors.inkSoft),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KvlSpacing.sm),
          _GradientProgressBar(progress: progress),
        ],
      ),
    );
  }
}

/// Rounded gradient progress bar with a soft track. The fill animates to the
/// current [progress] (0–1) and keeps a pill cap even at small values.
class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: KvlRadius.brPill,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const height = 11.0;
          final fullWidth = constraints.maxWidth;
          // Keep a visible rounded cap once there's any progress.
          final fillWidth = progress <= 0
              ? 0.0
              : (progress * fullWidth).clamp(height, fullWidth);
          return Stack(
            children: [
              // Track
              Container(
                height: height,
                width: fullWidth,
                color: KvlColors.primary.withValues(alpha: 0.12),
              ),
              // Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                height: height,
                width: fillWidth,
                decoration: BoxDecoration(
                  borderRadius: KvlRadius.brPill,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFB572),
                      KvlColors.primary,
                      KvlColors.primaryDeep,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: KvlColors.primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mic error card
// ─────────────────────────────────────────────────────────────────────────────

class _MicErrorCard extends StatelessWidget {
  const _MicErrorCard({
    required this.message,
    required this.requiresTraining,
    required this.showOpenSettings,
    required this.onTrainVoice,
    required this.onOpenSettings,
    required this.onSwitchManual,
    required this.onDismiss,
  });
  final String message;
  final bool requiresTraining;
  final bool showOpenSettings;
  final VoidCallback onTrainVoice;
  final VoidCallback onOpenSettings;
  final VoidCallback onSwitchManual;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      variant: KvlCardVariant.warm,
      border: Border.all(color: KvlColors.primary.withValues(alpha: .4)),
      padding: const EdgeInsets.all(KvlSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mic_off_rounded,
                color: KvlColors.primaryDeep,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Microphone needed',
                  style: KvlText.ui(13, FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(message, style: KvlText.caption(12).copyWith(height: 1.4)),
          const SizedBox(height: KvlSpacing.sm),
          Row(
            children: [
              if (showOpenSettings)
                Expanded(
                  child: KvlButton(
                    label: 'Open Settings',
                    onPressed: onOpenSettings,
                  ),
                )
              else if (requiresTraining)
                Expanded(
                  child: KvlButton(
                    label: 'Train Voice',
                    onPressed: onTrainVoice,
                  ),
                )
              else
                Expanded(
                  child: KvlButton(
                    label: 'Try Voice Again',
                    onPressed: onDismiss,
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: KvlButton(
                  variant: KvlButtonVariant.secondary,
                  label: 'Use Manual',
                  onPressed: onSwitchManual,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dedication dialog
// ─────────────────────────────────────────────────────────────────────────────

class _DedicationDialog extends StatelessWidget {
  const _DedicationDialog({required this.onDedicate});
  final VoidCallback onDedicate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: KvlRadius.brLG),
      child: Padding(
        padding: const EdgeInsets.all(KvlSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFB572), KvlColors.primary],
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.self_improvement_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: KvlSpacing.md),
            Text(
              'Program Complete!',
              style: KvlText.ui(
                20,
                FontWeight.w800,
              ).copyWith(color: KvlColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KvlSpacing.sm),
            Text(
              'You have completed your sankalpa.\nWould you like to dedicate this practice?',
              style: KvlText.caption(
                13.5,
              ).copyWith(color: KvlColors.inkSoft, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KvlSpacing.lg),
            KvlButton(label: 'Dedicate & Complete', onPressed: onDedicate),
          ],
        ),
      ),
    );
  }
}

/// One-time tip bottom sheet with a "Don't show again" checkbox.
class _TipSheet extends StatefulWidget {
  const _TipSheet({
    required this.title,
    required this.bullets,
    required this.initialDontShowAgain,
    required this.onChanged,
  });

  final String title;
  final List<String> bullets;
  final bool initialDontShowAgain;
  final ValueChanged<bool> onChanged;

  @override
  State<_TipSheet> createState() => _TipSheetState();
}

class _TipSheetState extends State<_TipSheet> {
  late bool _dontShowAgain = widget.initialDontShowAgain;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: KvlColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: KvlColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_rounded,
                    color: KvlColors.primaryDeep, size: 22),
                const SizedBox(width: 8),
                Text(widget.title, style: KvlText.ui(16, FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    b,
                    style: KvlText.body(13.5)
                        .copyWith(height: 1.4, color: KvlColors.inkSoft),
                  ),
                )),
            const SizedBox(height: 6),
            InkWell(
              onTap: () {
                setState(() => _dontShowAgain = !_dontShowAgain);
                widget.onChanged(_dontShowAgain);
              },
              child: Row(
                children: [
                  Checkbox(
                    value: _dontShowAgain,
                    onChanged: (v) {
                      setState(() => _dontShowAgain = v ?? false);
                      widget.onChanged(_dontShowAgain);
                    },
                  ),
                  Text("Don't show again",
                      style: KvlText.body(13).copyWith(color: KvlColors.ink)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: KvlButton(
                label: 'Got it!',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily Goal Celebration sheet
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Goal incomplete sheet — shown on Finish when daily target not yet met
// ─────────────────────────────────────────────────────────────────────────────

class _GoalIncompleteSheet extends StatelessWidget {
  const _GoalIncompleteSheet({required this.remaining});
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: KvlColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        KvlSpacing.lg, KvlSpacing.lg, KvlSpacing.lg, KvlSpacing.lg + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: KvlSpacing.md),
              decoration: BoxDecoration(
                color: KvlColors.muted.withValues(alpha: .3),
                borderRadius: KvlRadius.brPill,
              ),
            ),
          ),
          const Text('🙏', style: TextStyle(fontSize: 44), textAlign: TextAlign.center),
          const SizedBox(height: KvlSpacing.sm),
          Text(
            '${IndianNumberFormat.format(remaining)} chants left',
            textAlign: TextAlign.center,
            style: KvlText.ui(20, FontWeight.w800),
          ),
          const SizedBox(height: KvlSpacing.xs),
          Text(
            'to complete your daily sadhana goal.\nDo you want to continue?',
            textAlign: TextAlign.center,
            style: KvlText.caption(13).copyWith(color: KvlColors.muted),
          ),
          const SizedBox(height: KvlSpacing.lg),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: KvlColors.primary,
              shape: RoundedRectangleBorder(borderRadius: KvlRadius.brMD),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Continue This Session',
              style: KvlText.ui(14, FontWeight.w700).copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: KvlSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Complete Session',
              style: KvlText.ui(14, FontWeight.w600).copyWith(color: KvlColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily Goal Celebration sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DailyGoalSheet extends StatelessWidget {
  const _DailyGoalSheet({
    this.mantraId,
    this.globalSadhana,
    this.todaysCount = 0,
  });
  final String? mantraId;
  final GlobalSadhana? globalSadhana;
  final int todaysCount;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final isGlobal = globalSadhana != null;

    return Container(
      decoration: const BoxDecoration(
        color: KvlColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        KvlSpacing.lg, KvlSpacing.lg, KvlSpacing.lg, KvlSpacing.lg + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: KvlSpacing.md),
              decoration: BoxDecoration(
                color: KvlColors.muted.withValues(alpha: .3),
                borderRadius: KvlRadius.brPill,
              ),
            ),
          ),

          if (isGlobal) ...[
            // ── Global Sadhana celebration ─────────────────────────────────
            // Banner image or placeholder
            ClipRRect(
              borderRadius: KvlRadius.brLG,
              child: globalSadhana!.imageUrl != null
                  ? Image.network(
                      globalSadhana!.imageUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _GsPlaceholder(sadhana: globalSadhana!),
                    )
                  : _GsPlaceholder(sadhana: globalSadhana!),
            ),
            const SizedBox(height: KvlSpacing.md),
            Text(
              '🕉  ${globalSadhana!.title}',
              textAlign: TextAlign.center,
              style: KvlText.ui(16, FontWeight.w700),
            ),
            const SizedBox(height: KvlSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KvlSpacing.md,
                vertical: KvlSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: KvlColors.primaryGhost,
                borderRadius: KvlRadius.brMD,
              ),
              child: Text(
                'You contributed ${IndianNumberFormat.format(todaysCount)} chants today for this initiative 🙏',
                textAlign: TextAlign.center,
                style: KvlText.ui(14, FontWeight.w600)
                    .copyWith(color: KvlColors.primaryDeep, height: 1.4),
              ),
            ),
          ] else ...[
            // ── Generic daily goal celebration ──────────────────────────────
            const Text('🎉', style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
            const SizedBox(height: KvlSpacing.sm),
            Text(
              'You reached your goal today 🙏',
              textAlign: TextAlign.center,
              style: KvlText.ui(20, FontWeight.w800),
            ),
            const SizedBox(height: KvlSpacing.xs),
            Text(
              'Your daily sadhana is complete. Keep the streak alive!',
              textAlign: TextAlign.center,
              style: KvlText.caption(13).copyWith(color: KvlColors.muted),
            ),
          ],

          // Preview My Book — shown for all programs that have writings
          if (mantraId != null) ...[
            const SizedBox(height: KvlSpacing.md),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: KvlColors.primary.withValues(alpha: .5)),
                shape: RoundedRectangleBorder(borderRadius: KvlRadius.brMD),
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                BookPreviewButton.openSheet(context, mantraId!);
              },
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: Text(
                'Preview My Book',
                style: KvlText.ui(13, FontWeight.w600).copyWith(color: KvlColors.primary),
              ),
            ),
          ],
          const SizedBox(height: KvlSpacing.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Complete Session',
              style: KvlText.ui(14, FontWeight.w600).copyWith(color: KvlColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _GsPlaceholder extends StatelessWidget {
  const _GsPlaceholder({required this.sadhana});
  final GlobalSadhana sadhana;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF8C42), Color(0xFFE07020)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.language_rounded, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          Text(
            sadhana.title,
            style: KvlText.title(15).copyWith(color: Colors.white),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
