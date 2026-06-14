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
    final baseProgress = state.program.totalProgress;
    final statsAsync = ref.watch(globalStatsProvider(state.program.mantraId));
    final globalCount =
        (statsAsync.value?.globalChantCount ?? 0) + state.sessionCount;
    final title =
        mantra?.name.displayForLanguage(settings.languageCode) ?? '';
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
                    title: title,
                    initial: profile?.initials ?? '?',
                    onBack: () => context.pop(),
                    onProfileTap: () => context.push(KvlRoute.profile),
                  ),
                  SizedBox(height: compact ? 10 : 16),
                  _ToolRow(
                    compact: compact,
                    onChangeMantra: () => context.go(KvlRoute.programs),
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
                      onTap: state.isRunning
                          ? controller.pause
                          : () => controller.start(mantra: mantra),
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  _Counts(
                    globalCount: globalCount,
                    yours: baseProgress,
                    added: state.sessionCount,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  _ActionRow(
                    compact: compact,
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
          final controller = ref.read(practiceControllerProvider(programId).notifier);
          final mantraId = ref.read(practiceControllerProvider(programId)).value?.program.mantraId;
          await controller.finish();
          if (mantraId != null) ref.invalidate(globalStatsProvider(mantraId));
          final program = ref.read(practiceControllerProvider(programId)).value?.program;
          if (program != null && !program.isCompleted) {
            await ref.read(programRepositoryProvider).update(
              program.copyWith(completedAt: DateTime.now()),
            );
          }
          if (!context.mounted) return;
          context.go('${KvlRoute.dailyProgress}/$programId');
        },
        onContinue: () => Navigator.of(context).pop(),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.initial,
    required this.onBack,
    required this.onProfileTap,
  });
  final String title;
  final String initial;
  final VoidCallback onBack;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          color: KvlColors.ink,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KvlText.ui(
              20,
              FontWeight.w800,
            ).copyWith(color: const Color(0xFF3B210F)),
          ),
        ),
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(24),
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
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tool row
// ─────────────────────────────────────────────────────────────────────────────

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.compact,
    required this.onChangeMantra,
    required this.onWritingMode,
    required this.phoneModeEnabled,
    required this.onPhoneMode,
  });
  final bool compact;
  final VoidCallback onChangeMantra;
  final VoidCallback onWritingMode;
  final bool phoneModeEnabled;
  final VoidCallback onPhoneMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Tool(
            icon: Icons.keyboard_command_key_rounded,
            label: 'Change Mantra',
            onTap: onChangeMantra,
            compact: compact,
          ),
        ),
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
      ],
    );
  }
}

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
  });
  final double micSize;
  final String mantraLabel;
  final bool compact;
  final bool isRunning;
  final bool isVoiceMode;
  final VoidCallback onTap;
  final int sessionCount;

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
        duration: const Duration(milliseconds: 2200),
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
      milliseconds: (2200 - intensity * 700).round(),
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

            // Mantra text: visible from session start, shrinks on each count
            if (widget.isRunning)
              AnimatedBuilder(
                animation: _textCtrl,
                builder: (ctx2, _) {
                  final t = Curves.easeIn.transform(_textCtrl.value);
                  final maxFs = (constraints.maxWidth * 0.42).clamp(32.0, 96.0);
                  final minFs = widget.compact ? 12.0 : 14.0;
                  final fontSize = maxFs - (maxFs - minFs) * t;
                  final opacity = t < 0.75
                      ? 1.0
                      : ((1.0 - t) / 0.25).clamp(0.0, 1.0);
                  final textColor = Color.lerp(
                    const Color(0xFFCC7A3A),
                    const Color(0xFF4A1A02),
                    t,
                  )!;
                  return SizedBox(
                    width: constraints.maxWidth * 0.88,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.mantraLabel,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: fontSize.clamp(minFs, maxFs),
                          fontWeight: t > 0.65 ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: ((1.0 - t) * 3.0).clamp(0.0, 3.0),
                          color: textColor.withValues(alpha: opacity * 0.80),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Mic icon: shrinks + moves to bottom when running
            Positioned(
              bottom: widget.isRunning ? constraints.maxHeight * 0.04 : null,
              child: GestureDetector(
                onTap: widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  width: widget.isRunning ? widget.micSize * 1.6 : widget.micSize * 2.4,
                  height: widget.isRunning ? widget.micSize * 1.6 : widget.micSize * 2.4,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    width: widget.isRunning ? widget.micSize * 0.75 : widget.micSize * 1.35,
                    height: widget.isRunning ? widget.micSize * 0.75 : widget.micSize * 1.35,
                    child: const CustomPaint(painter: _MicPainter()),
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

class _MicPainter extends CustomPainter {
  const _MicPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final fill = Paint()
      ..color = const Color(0xFF3A3D42)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF3A3D42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .055
      ..strokeCap = StrokeCap.round;

    // Capsule body
    final capsuleW = size.width * .44;
    final capsuleH = size.height * .52;
    final capsuleTop = size.height * .03;
    final capsuleRect = Rect.fromLTWH(cx - capsuleW / 2, capsuleTop, capsuleW, capsuleH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(capsuleRect, Radius.circular(capsuleW / 2)),
      fill,
    );

    // Grille lines
    final grillePaint = Paint()
      ..color = Colors.white.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .035
      ..strokeCap = StrokeCap.round;
    final grilleL = cx - capsuleW * .38;
    final grilleR = cx + capsuleW * .38;
    final grilleStartY = capsuleTop + capsuleH * .30;
    final grilleSpacing = capsuleH * .18;
    for (var i = 0; i < 3; i++) {
      final y = grilleStartY + i * grilleSpacing;
      canvas.drawLine(Offset(grilleL, y), Offset(grilleR, y), grillePaint);
    }

    // Stand arc
    final arcCenterY = capsuleTop + capsuleH * .9;
    final arcRect = Rect.fromCenter(
      center: Offset(cx, arcCenterY),
      width: size.width * .72,
      height: size.height * .38,
    );
    canvas.drawArc(arcRect, 0, 3.14159, false, strokePaint);

    // Vertical stem
    final stemTop = arcCenterY + arcRect.height / 2;
    final stemBot = size.height * .93;
    canvas.drawLine(Offset(cx, stemTop), Offset(cx, stemBot), strokePaint);

    // Horizontal base
    canvas.drawLine(
      Offset(cx - size.width * .26, stemBot),
      Offset(cx + size.width * .26, stemBot),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Count display
// ─────────────────────────────────────────────────────────────────────────────

class _Counts extends StatelessWidget {
  const _Counts({
    required this.globalCount,
    required this.yours,
    required this.added,
    required this.compact,
  });
  final int globalCount;
  final int yours;
  final int added;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.sm),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              context.l10n.countDisplay(IndianNumberFormat.format(globalCount)),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: KvlText.ui(
                compact ? 14 : 16,
                FontWeight.w400,
              ).copyWith(color: const Color(0xFF3A2B22)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KvlSpacing.md,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              borderRadius: KvlRadius.brPill,
              border: Border.all(color: const Color(0xFFFF2E2E), width: 1),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  style: KvlText.ui(
                    compact ? 17 : 20,
                    FontWeight.w700,
                  ).copyWith(color: KvlColors.ink),
                  children: [
                    TextSpan(text: context.l10n.yoursDisplay),
                    TextSpan(
                      text: IndianNumberFormat.format(yours),
                      style: const TextStyle(color: Color(0xFFE02020)),
                    ),
                    const TextSpan(text: ' + '),
                    TextSpan(
                      text: IndianNumberFormat.format(added),
                      style: const TextStyle(color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ),
            ),
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
  });
  final bool compact;
  final String startLabel;
  final IconData startIcon;
  final VoidCallback onStart;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: startLabel,
            icon: startIcon,
            color: KvlColors.primary,
            onTap: onStart,
            compact: compact,
          ),
        ),
        const SizedBox(width: KvlSpacing.md),
        Expanded(
          child: _ActionButton(
            label: context.l10n.finishButton,
            color: KvlColors.accent,
            onTap: onFinish,
            compact: compact,
          ),
        ),
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
    return Material(
      color: disabled ? color.withValues(alpha: .42) : color,
      borderRadius: KvlRadius.brMD,
      elevation: disabled ? 0 : 6,
      shadowColor: Colors.black.withValues(alpha: .15),
      child: InkWell(
        onTap: onTap,
        borderRadius: KvlRadius.brMD,
        child: SizedBox(
          height: compact ? 44 : 48,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: KvlText.ui(
                  compact ? 14 : 17,
                  FontWeight.w700,
                ).copyWith(color: Colors.white),
              ),
            ],
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
    final progress = state.program.dailyTarget == 0
        ? 0.0
        : (state.todaysTotal / state.program.dailyTarget).clamp(0, 1).toDouble();
    return KvlCard(
      padding: EdgeInsets.fromLTRB(
        KvlSpacing.md,
        KvlSpacing.sm,
        KvlSpacing.md,
        KvlSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's Progress",
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
                    '${IndianNumberFormat.format(state.todaysTotal)} / ${IndianNumberFormat.format(state.program.dailyTarget)}',
                    maxLines: 1,
                    style: KvlText.caption(compact ? 11 : 12).copyWith(color: KvlColors.inkSoft),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KvlSpacing.sm),
          ClipRRect(
            borderRadius: KvlRadius.brPill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFE2E2E2),
              valueColor: const AlwaysStoppedAnimation(KvlColors.accent),
            ),
          ),
        ],
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
  const _DedicationDialog({required this.onDedicate, required this.onContinue});
  final VoidCallback onDedicate;
  final VoidCallback onContinue;

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
            const SizedBox(height: KvlSpacing.sm),
            KvlButton(
              label: 'Keep Practising',
              variant: KvlButtonVariant.secondary,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
