import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/phone/phone_mode_service.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../programs/domain/session.dart';
import '../../rewards/domain/reward_rules.dart';
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
    final phoneModeEnabled = ref.watch(_phoneModeEnabledProvider).value ?? false;
    final statsAsync = ref.watch(globalStatsProvider(state.program.mantraId));
    final globalCount = (statsAsync.value?.globalChantCount ?? 0) + state.sessionCount;
    final liveUsers = statsAsync.value?.memberCount ?? 0;
    final mantraTitle = mantra?.name.displayForLanguage(settings.languageCode) ?? '';
    final totalProgress = state.program.totalProgress + state.sessionCount;
    final targetWritings = state.program.targetWritings.clamp(1, 999999999);
    final nextMilestone = _nextMilestone(state.program.totalProgress + state.sessionCount);

    return Scaffold(
      backgroundColor: KvlColors.bg,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, c) {
            final compact = c.maxHeight < 760;
            final bottomPad = MediaQuery.of(context).padding.bottom + (compact ? 8.0 : 14.0);
            return Padding(
              padding: EdgeInsets.fromLTRB(16, compact ? 4 : 10, 16, 0),
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────────────────
                  _TopBar(
                    title: mantraTitle,
                    profile: profile,
                    onBack: () => context.pop(),
                    onProfileTap: () => context.push(KvlRoute.profile),
                  ),
                  SizedBox(height: compact ? 10 : 14),

                  // ── Row 1: Global count + Live users ─────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: '॰',
                          iconColor: KvlColors.primary,
                          label: 'Global Count',
                          value: IndianNumberFormat.format(globalCount),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: '👥',
                          label: 'Live users',
                          value: IndianNumberFormat.format(liveUsers),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 8 : 10),

                  // ── Row 2: Action tiles ───────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.music_note_rounded,
                          label: 'Change Mantra',
                          onTap: () => context.go(KvlRoute.programs),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionTile(
                          icon: Icons.bar_chart_rounded,
                          label: 'Session Stats',
                          onTap: () => context.push('${KvlRoute.dailyProgress}/$programId'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 8 : 10),

                  // ── Row 3: Today's count + To milestone ───────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: '📅',
                          label: "Today's Count",
                          subValue:
                              '${IndianNumberFormat.format(state.todaysTotal)} / ${IndianNumberFormat.format(state.program.dailyTarget)}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: '🎉',
                          iconColor: KvlColors.primary,
                          label: 'To Milestone',
                          subValue: nextMilestone > 0
                              ? '${IndianNumberFormat.format(nextMilestone)} left'
                              : 'Completed!',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 10 : 14),

                  // ── Circular progress ring ────────────────────────────
                  Expanded(
                    child: Center(
                      child: _CircularRing(
                        value: totalProgress,
                        target: targetWritings,
                        isRunning: state.isRunning,
                        sessionCount: state.sessionCount,
                        compact: compact,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 14),

                  // ── Error card ────────────────────────────────────────
                  if (state.errorMessage != null)
                    _MicErrorCard(
                      message: state.errorMessage!,
                      requiresTraining: state.errorMessage!.startsWith('Complete voice training'),
                      showOpenSettings: state.micPermanentlyDenied,
                      onTrainVoice: () => context.go('${KvlRoute.voiceTraining}/${state.program.mantraId}'),
                      onOpenSettings: controller.openSystemSettings,
                      onSwitchManual: () {
                        controller.setModality(SessionModality.manual);
                        controller.clearError();
                      },
                      onDismiss: controller.clearError,
                    ),

                  // ── Action buttons ────────────────────────────────────
                  _BottomButtons(
                    compact: compact,
                    state: state,
                    mantra: mantra,
                    phoneModeEnabled: phoneModeEnabled,
                    controller: controller,
                    onFinish: () async {
                      if (state.activeSessionId != null) {
                        final saved = state.sessionCount;
                        await controller.finish();
                        if (!context.mounted) return;
                        ref.read(sessionCompletedProvider.notifier).increment();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: const Duration(milliseconds: 1500),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF15803D),
                            elevation: 10,
                            shape: RoundedRectangleBorder(borderRadius: KvlRadius.brMD),
                            content: Row(
                              children: [
                                Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .16),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 19),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Session saved · +${IndianNumberFormat.format(saved)} chants',
                                    style: KvlText.ui(13, FontWeight.w600).copyWith(color: Colors.white),
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
                    onPhoneMode: () async {
                      await PhoneModeService().toggle();
                      ref.invalidate(_phoneModeEnabledProvider);
                    },
                    onWritingMode: () => context.push(
                      '${KvlRoute.handwritingWrite}/${state.program.mantraId}?programId=$programId',
                    ),
                  ),
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
          await controller.finish();
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

  int _nextMilestone(int total) {
    for (final t in RewardRules.milestoneThresholds) {
      if (total < t) return t - total;
    }
    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.profile,
    required this.onBack,
    required this.onProfileTap,
  });
  final String title;
  final dynamic profile;
  final VoidCallback onBack;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF3B210F)),
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KvlText.ui(19, FontWeight.w800).copyWith(color: const Color(0xFF3B210F)),
          ),
        ),
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 44, height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFFFFB572), KvlColors.primary]),
            ),
            alignment: Alignment.center,
            child: Text(
              profile?.initials ?? '?',
              style: KvlText.ui(16, FontWeight.w700).copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat tile (shows a large number or sub-value string)
// ─────────────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    this.iconColor = const Color(0xFF1A8080),
    this.value,
    this.subValue,
  });
  final String icon;
  final Color iconColor;
  final String label;
  final String? value;   // large red number
  final String? subValue; // smaller grey text

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: KvlText.caption(12).copyWith(color: KvlColors.inkSoft, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (value != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value!,
                style: KvlText.ui(22, FontWeight.w800).copyWith(color: const Color(0xFFCC2222)),
              ),
            ),
          if (subValue != null)
            Text(
              subValue!,
              style: KvlText.caption(12).copyWith(color: KvlColors.inkSoft),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action tile (tappable card with icon + label)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: KvlRadius.brMD,
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1A8080)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: KvlText.ui(13, FontWeight.w600).copyWith(color: KvlColors.ink),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circular progress ring
// ─────────────────────────────────────────────────────────────────────────────

class _CircularRing extends StatelessWidget {
  const _CircularRing({
    required this.value,
    required this.target,
    required this.isRunning,
    required this.sessionCount,
    required this.compact,
  });
  final int value;
  final int target;
  final bool isRunning;
  final int sessionCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    final size = compact ? 180.0 : 220.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(progress: progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRunning && sessionCount > 0)
                Text(
                  '+${IndianNumberFormat.format(sessionCount)}',
                  style: KvlText.caption(compact ? 12 : 14)
                      .copyWith(color: const Color(0xFF16A34A), fontWeight: FontWeight.w700),
                ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  IndianNumberFormat.format(value),
                  style: KvlText.ui(compact ? 28 : 34, FontWeight.w800)
                      .copyWith(color: const Color(0xFF3B210F)),
                ),
              ),
              Text(
                '/ ${IndianNumberFormat.format(target)}',
                style: KvlText.caption(compact ? 12 : 14)
                    .copyWith(color: KvlColors.inkSoft),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final strokeW = size.width * 0.1;
    final radius = (size.width - strokeW) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Track
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = const Color(0xFFE2E2E2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFF8C42), Color(0xFFFFB572)],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom buttons
// ─────────────────────────────────────────────────────────────────────────────

class _BottomButtons extends StatelessWidget {
  const _BottomButtons({
    required this.compact,
    required this.state,
    required this.mantra,
    required this.phoneModeEnabled,
    required this.controller,
    required this.onFinish,
    required this.onPhoneMode,
    required this.onWritingMode,
  });
  final bool compact;
  final PracticeState state;
  final dynamic mantra;
  final bool phoneModeEnabled;
  final PracticeController controller;
  final VoidCallback onFinish;
  final VoidCallback onPhoneMode;
  final VoidCallback onWritingMode;

  @override
  Widget build(BuildContext context) {
    final isActive = state.activeSessionId != null;
    final isRunning = state.isRunning;

    final startLabel = !isActive
        ? context.l10n.startButton
        : isRunning
        ? context.l10n.pauseButton
        : context.l10n.resumeButton;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tool row (writing / phone mode)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SmallTool(
              icon: Icons.draw_outlined,
              label: context.l10n.ownWritingModeLabel,
              onTap: onWritingMode,
            ),
            const SizedBox(width: 24),
            _SmallTool(
              icon: phoneModeEnabled
                  ? Icons.notifications_off_rounded
                  : Icons.notifications_none_rounded,
              label: context.l10n.phoneMode,
              onTap: onPhoneMode,
              active: phoneModeEnabled,
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 10),
        // Main START / PAUSE button
        SizedBox(
          width: double.infinity,
          height: compact ? 48 : 54,
          child: Material(
            color: KvlColors.primary,
            borderRadius: KvlRadius.brMD,
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: .15),
            child: InkWell(
              borderRadius: KvlRadius.brMD,
              onTap: isRunning
                  ? controller.pause
                  : () => controller.start(mantra: mantra),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    startLabel,
                    style: KvlText.ui(compact ? 15 : 17, FontWeight.w800)
                        .copyWith(color: Colors.white, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isActive) ...[
          SizedBox(height: compact ? 6 : 8),
          SizedBox(
            width: double.infinity,
            height: compact ? 40 : 44,
            child: Material(
              color: Colors.transparent,
              borderRadius: KvlRadius.brMD,
              child: InkWell(
                borderRadius: KvlRadius.brMD,
                onTap: onFinish,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: KvlRadius.brMD,
                    border: Border.all(color: KvlColors.accent, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    context.l10n.finishButton,
                    style: KvlText.ui(compact ? 13 : 15, FontWeight.w700)
                        .copyWith(color: KvlColors.accent),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SmallTool extends StatelessWidget {
  const _SmallTool({required this.icon, required this.label, required this.onTap, this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: active ? KvlColors.primaryDeep : KvlColors.inkSoft),
          const SizedBox(height: 2),
          Text(
            label,
            style: KvlText.caption(10.5).copyWith(
              color: active ? KvlColors.primaryDeep : KvlColors.inkSoft,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: KvlCard(
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dedication dialog (shown when program target is crossed)
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
              width: 64, height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFFFFB572), KvlColors.primary]),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.self_improvement_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: KvlSpacing.md),
            Text('Program Complete!',
                style: KvlText.ui(20, FontWeight.w800).copyWith(color: KvlColors.ink),
                textAlign: TextAlign.center),
            const SizedBox(height: KvlSpacing.sm),
            Text(
              'You have completed your sankalpa.\nWould you like to dedicate this practice?',
              style: KvlText.caption(13.5).copyWith(color: KvlColors.inkSoft, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KvlSpacing.lg),
            KvlButton(label: 'Dedicate & Complete', onPressed: onDedicate),
            const SizedBox(height: KvlSpacing.sm),
            KvlButton(label: 'Keep Practising', variant: KvlButtonVariant.secondary, onPressed: onContinue),
          ],
        ),
      ),
    );
  }
}
