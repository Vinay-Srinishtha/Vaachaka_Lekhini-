import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../l10n/l10n.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/phone/phone_mode_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../programs/domain/session.dart';
import '../../programs/presentation/daily_progress_screen.dart';
import '../../settings/domain/settings_repository.dart';
import '../application/practice_controller.dart';

final _phoneModeEnabledProvider = FutureProvider.autoDispose<bool>((ref) {
  return PhoneModeService().isEnabled();
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
        body: Center(child: Text('$e')),
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

  @override
  void initState() {
    super.initState();
    if ((widget.state.draftCount ?? 0) > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_draftDialogShown) {
          _draftDialogShown = true;
          _showRestoreDraftDialog(context);
        }
      });
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
      if (next.value?.targetReached == true && !_dedicationShown && context.mounted) {
        _dedicationShown = true;
        _showDedicationDialog(context, ref, programId);
      }
    });

    final mantra = ref.watch(mantraByIdProvider(state.program.mantraId));
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final profile = ref.watch(activeProfileProvider).value;
    final controller = ref.read(practiceControllerProvider(programId).notifier);
    final phoneModeEnabled =
        ref.watch(_phoneModeEnabledProvider).value ?? false;
    final statsAsync = ref.watch(globalStatsProvider(state.program.mantraId));
    final globalCount =
        (statsAsync.value?.globalChantCount ?? 0) + state.sessionCount;
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
                    initial: profile?.initials ?? '?',
                    onProfileTap: () => context.push(KvlRoute.profile),
                    compact: compact,
                    onWritingMode: () => context.push(
                      '${KvlRoute.handwritingWrite}/${state.program.mantraId}?programId=$programId',
                    ),
                    phoneModeEnabled: phoneModeEnabled,
                    onPhoneMode: () => _togglePhoneMode(ref),
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
                      if (state.activeSessionId != null) {
                        final beforeTotal = state.program.totalProgress;
                        await controller.finish();
                        if (!context.mounted) return;
                        ref.read(sessionCompletedProvider.notifier).increment();
                        ref.invalidate(globalStatsProvider(state.program.mantraId));
                        final afterState = ref.read(practiceControllerProvider(programId)).value;
                        final sessionTotal = (afterState != null)
                            ? (afterState.program.totalProgress - beforeTotal).clamp(0, 999999)
                            : state.sessionCount;
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                          SnackBar(
                            duration: const Duration(milliseconds: 2500),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF15803D),
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: KvlRadius.brMD,
                            ),
                            content: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .16),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: KvlSpacing.sm),
                                Expanded(
                                  child: Text(
                                    '${IndianNumberFormat.format(sessionTotal)} chants completed this session',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: KvlText.ui(
                                      13,
                                      FontWeight.w600,
                                    ).copyWith(color: Colors.white),
                                  ),
                                ),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    final messenger = ScaffoldMessenger.maybeOf(context);
                                    messenger?.clearSnackBars();
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      if (!context.mounted) return;
                      context.go('${KvlRoute.dailyProgress}/$programId');
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
                      onTrainVoice: () => context.go(
                        '${KvlRoute.voiceTraining}/${state.program.mantraId}',
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

  Future<void> _showDedicationDialog(BuildContext context, WidgetRef ref, String programId) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DedicationDialog(
        onDedicate: () async {
          Navigator.of(context).pop();

          // Mark the session as finished and the program as completed.
          final controller = ref.read(practiceControllerProvider(programId).notifier);
          final mantraId = ref.read(practiceControllerProvider(programId)).value?.program.mantraId;
          await controller.finish();
          if (mantraId != null) ref.invalidate(globalStatsProvider(mantraId));
          final program = ref.read(practiceControllerProvider(programId)).value?.program;
          final mantraName = mantraId != null
              ? (ref.read(mantraByIdProvider(mantraId))?.name.devanagari ?? '')
              : '';
          if (program != null && !program.isCompleted) {
            await ref.read(programRepositoryProvider).update(
              program.copyWith(completedAt: DateTime.now()),
            );
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

  Future<void> _togglePhoneMode(WidgetRef ref) async {
    await PhoneModeService().toggle();
    ref.invalidate(_phoneModeEnabledProvider);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.initial,
    required this.onProfileTap,
    required this.compact,
    required this.onWritingMode,
    required this.phoneModeEnabled,
    required this.onPhoneMode,
  });
  final String initial;
  final VoidCallback onProfileTap;
  final bool compact;
  final VoidCallback onWritingMode;
  final bool phoneModeEnabled;
  final VoidCallback onPhoneMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(programsForActiveProfileProvider).value ?? const [];
    final completed = programs.where((p) => p.isGoalReached).length;

    return Row(
      children: [
        Expanded(
          child: _Tool(
            icon: Icons.draw_outlined,
            label: context.l10n.ownWritingModeLabel,
            onTap: onWritingMode,
            compact: compact,
          ),
        ),
        Expanded(
          child: _Tool(
            icon: phoneModeEnabled
                ? Icons.notifications_off_rounded
                : Icons.notifications_none_rounded,
            label: context.l10n.phoneMode,
            onTap: onPhoneMode,
            compact: compact,
            active: phoneModeEnabled,
          ),
        ),
        const SizedBox(width: KvlSpacing.sm),
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(24),
          child: MilestoneRing(
            completed: completed,
            total: programs.length,
            strokeWidth: 2.5,
            gap: 2.5,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFFB572), KvlColors.primary],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: KvlText.ui(
                  18,
                  FontWeight.w700,
                ).copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tool
// ─────────────────────────────────────────────────────────────────────────────

class _Tool extends StatelessWidget {
  const _Tool({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.compact,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: KvlRadius.brMD,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: compact ? 38 : 44,
              height: compact ? 38 : 44,
              decoration: BoxDecoration(
                color: active ? KvlColors.primaryGhost : Colors.transparent,
                borderRadius: KvlRadius.brMD,
                border: active
                    ? Border.all(color: KvlColors.primarySoft)
                    : null,
              ),
              alignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: compact ? 27 : 31,
                    color: active
                        ? KvlColors.primaryDeep
                        : const Color(0xFF252525),
                  ),
                  if (active)
                    Positioned(
                      right: -10,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: KvlColors.primary,
                          borderRadius: KvlRadius.brPill,
                        ),
                        child: Text(
                          'ON',
                          style: KvlText.caption(7).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: compact ? 15 : 18,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: KvlText.caption(compact ? 11.5 : 13).copyWith(
                    color: active ? KvlColors.primaryDeep : KvlColors.inkSoft,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
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
  static const _poolSize = 6;

  static const _ringColors = [
    Color(0xFFFF8C42),
    Color(0xFFFFB572),
    Color(0xFFE8622A),
    Color(0xFFFFD4A3),
    Color(0xFFFF6B35),
    Color(0xFFFFCA8A),
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
        duration: const Duration(milliseconds: 1500),
      ),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _textCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _textCtrl.reset();
        });
      }
    });
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
      intensity = (1.0 - ((ms - 300) / 2700)).clamp(0.2, 1.0);
    }
    _lastCountTime = now;

    final slot = _nextSlot % _poolSize;
    _nextSlot++;
    _slotIntensity[slot] = intensity;

    _pool[slot].duration = Duration(
      milliseconds: (1500 - intensity * 500).round(),
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
    for (final c in _pool) { c.dispose(); }
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

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Soft static background circle
            Container(
              width: widget.micSize * 2.6,
              height: widget.micSize * 2.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFB572).withValues(alpha: widget.isRunning ? 0.18 : 0.08),
                    const Color(0xFFFF8C42).withValues(alpha: widget.isRunning ? 0.08 : 0.03),
                    KvlColors.primary.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),

            // Outward ripples — fired on each voice count
            for (var i = 0; i < _poolSize; i++)
              AnimatedBuilder(
                animation: _pool[i],
                builder: (ctx2, _) {
                  final raw = _pool[i].value;
                  if (raw == 0.0) return const SizedBox.shrink();
                  final t = Curves.easeOut.transform(raw);
                  final intensity = _slotIntensity[i];
                  final reach = micDiam + (maxDiam - micDiam) * intensity;
                  final diam = micDiam + (reach - micDiam) * t;
                  final opacity = ((1.0 - t) * 0.52 * intensity).clamp(0.0, 0.52);
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

            // Mantra title — FIXED position & size in both idle and running.
            Positioned(
              top: constraints.maxHeight * 0.06,
              child: SizedBox(
                width: constraints.maxWidth * 0.9,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.mantraLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: (constraints.maxWidth * 0.40).clamp(32.0, 90.0),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: const Color(0xFFCC7A3A),
                    ),
                  ),
                ),
              ),
            ),

            // Reactive curved sound waves — centred on the mic, only while a
            // voice session is capturing.
            if (widget.isRunning && widget.isVoiceMode)
              Align(
                alignment: const Alignment(0, 0.76),
                child: IgnorePointer(
                  child: SizedBox(
                    width: orbDiam * 2.7,
                    height: orbDiam * 1.7,
                    child: _VoiceWaves(level: widget.level),
                  ),
                ),
              ),

            // Mic orb — FIXED size & position in both states (a bit smaller).
            Align(
              alignment: const Alignment(0, 0.12),
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  width: orbDiam,
                  height: orbDiam,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFC08A),
                        KvlColors.primary,
                        KvlColors.primaryDeep,
                      ],
                    ),
                    boxShadow: [
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

  // Warm theme palette — saffron → primary → deep orange.
  static const _waveColors = [
    Color(0xFFFFB572),
    KvlColors.primary,
    Color(0xFFFF8C42),
    KvlColors.primaryDeep,
    Color(0xFFFFA15C),
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
          ..color = color.withValues(alpha: (0.22 + 0.55 * amp) * presence)
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
              Text.rich(
                TextSpan(
                  style: KvlText.ui(compact ? 16 : 19, FontWeight.w800)
                      .copyWith(color: KvlColors.ink),
                  children: [
                    TextSpan(
                      text: 'Global  ',
                      style: KvlText.ui(compact ? 12 : 13, FontWeight.w600)
                          .copyWith(color: KvlColors.inkSoft),
                    ),
                    TextSpan(
                      text: IndianNumberFormat.format(globalBase),
                      style: const TextStyle(color: Color(0xFFCC6A2B)),
                    ),
                    const TextSpan(
                      text: '  +  ',
                      style: TextStyle(
                        color: Color(0xFF9A8678),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: IndianNumberFormat.format(added),
                      style: const TextStyle(color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    // Build a soft 3-stop gradient + matching glow from the base colour so
    // every action button reads as a premium pill, not a flat block.
    final hsl = HSLColor.fromColor(color);
    final lighter =
        hsl.withLightness((hsl.lightness + 0.09).clamp(0.0, 1.0)).toColor();
    final darker =
        hsl.withLightness((hsl.lightness - 0.13).clamp(0.0, 1.0)).toColor();
    final radius = BorderRadius.circular(compact ? 16 : 20);

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [lighter, color, darker],
          ),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: 0.40),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            splashColor: Colors.white.withValues(alpha: 0.18),
            highlightColor: Colors.white.withValues(alpha: 0.06),
            child: SizedBox(
              height: compact ? 48 : 54,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                // FittedBox keeps icon + label on one line and scales them down
                // to fit narrow buttons (e.g. the 1/4-width Pause/Resume).
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 21),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: KvlText.ui(
                          compact ? 15 : 18,
                          FontWeight.w800,
                        ).copyWith(color: Colors.white, letterSpacing: 0.4),
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
    final progress = goal == 0
        ? 0.0
        : (total / goal).clamp(0, 1).toDouble();
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
                  style: KvlText.title(compact ? 13 : 15).copyWith(fontWeight: FontWeight.w800),
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
                    style: KvlText.caption(compact ? 11 : 12).copyWith(color: KvlColors.inkSoft),
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
                    colors: [Color(0xFFFFB572), KvlColors.primary, KvlColors.primaryDeep],
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
              const Icon(Icons.mic_off_rounded, color: KvlColors.primaryDeep, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Microphone needed', style: KvlText.ui(13, FontWeight.w600))),
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
                Expanded(child: KvlButton(label: 'Open Settings', onPressed: onOpenSettings))
              else if (requiresTraining)
                Expanded(child: KvlButton(label: 'Train Voice', onPressed: onTrainVoice))
              else
                Expanded(child: KvlButton(label: 'Try Voice Again', onPressed: onDismiss)),
              if (!requiresTraining) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: KvlButton(
                    variant: KvlButtonVariant.secondary,
                    label: 'Use Manual',
                    onPressed: onSwitchManual,
                  ),
                ),
              ],
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
                gradient: LinearGradient(colors: [Color(0xFFFFB572), KvlColors.primary]),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.self_improvement_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: KvlSpacing.md),
            Text(
              'Program Complete!',
              style: KvlText.ui(20, FontWeight.w800).copyWith(color: KvlColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KvlSpacing.sm),
            Text(
              'You have completed your sankalpa.\nWould you like to dedicate this practice?',
              style: KvlText.caption(13.5).copyWith(color: KvlColors.inkSoft, height: 1.5),
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
