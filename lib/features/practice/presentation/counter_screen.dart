import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/navigation/back_navigation.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../programs/domain/session.dart';
import '../../settings/domain/settings_repository.dart';
import '../application/practice_controller.dart';

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

class _Body extends ConsumerWidget {
  const _Body({required this.programId, required this.state});
  final String programId;
  final PracticeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mantra = ref.watch(mantraByIdProvider(state.program.mantraId));
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final profile = ref.watch(activeProfileProvider).value;
    final controller = ref.read(practiceControllerProvider(programId).notifier);
    final current = state.program.totalProgress + state.sessionCount;
    final globalCount = 10000000 + current;
    final title =
        mantra?.name.displayForLanguage(settings.languageCode) ??
        'Sri Rama lekhanam';
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
            final micSize = compact ? 152.0 : 192.0;
            final bottomPad = MediaQuery.of(context).padding.bottom +
                (compact ? 8.0 : 14.0);

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
                    onBack: () => context.popOrGo(KvlRoute.practice),
                    onProfileTap: () => context.push(KvlRoute.profile),
                  ),
                  SizedBox(height: compact ? 10 : 16),
                  _ToolRow(
                    compact: compact,
                    onChangeMantra: () => context.go(KvlRoute.programs),
                    onWritingMode: () => context.push(
                      '${KvlRoute.handwritingWrite}/${state.program.mantraId}?programId=$programId',
                    ),
                    onAmbience: () {},
                    onPhoneMode: () {},
                  ),
                  SizedBox(height: compact ? 10 : 16),
                  Expanded(
                    child: _HeroMic(
                      micSize: micSize,
                      mantraLabel: mantraLabel,
                      compact: compact,
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  _Counts(
                    globalCount: globalCount,
                    yours: current,
                    added: state.sessionCount,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  _ActionRow(
                    compact: compact,
                    startLabel: state.activeSessionId == null
                        ? 'START'
                        : state.isRunning
                        ? 'PAUSE'
                        : 'RESUME',
                    startIcon: state.isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    onStart: state.isRunning
                        ? controller.pause
                        : () => controller.start(mantra: mantra),
                    onFinish: state.activeSessionId == null
                        ? null
                        : () async {
                            final saved = state.sessionCount;
                            await controller.finish();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Session saved · +${IndianNumberFormat.format(saved)} chants',
                                ),
                                backgroundColor: KvlColors.accent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            if (context.canPop()) context.pop();
                          },
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    _MicErrorCard(
                      message: state.errorMessage!,
                      showOpenSettings: state.micPermanentlyDenied,
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
}

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

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.compact,
    required this.onChangeMantra,
    required this.onWritingMode,
    required this.onAmbience,
    required this.onPhoneMode,
  });
  final bool compact;
  final VoidCallback onChangeMantra;
  final VoidCallback onWritingMode;
  final VoidCallback onAmbience;
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
            label: 'Writing mode',
            onTap: onWritingMode,
            compact: compact,
          ),
        ),
        Expanded(
          child: _Tool(
            icon: Icons.music_note_rounded,
            label: 'Ambience Sound',
            onTap: onAmbience,
            compact: compact,
          ),
        ),
        Expanded(
          child: _Tool(
            icon: Icons.notifications_off_outlined,
            label: 'Phone Mode',
            onTap: onPhoneMode,
            compact: compact,
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
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: KvlRadius.brSM,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          children: [
            Icon(icon, size: compact ? 29 : 34, color: const Color(0xFF252525)),
            const SizedBox(height: 6),
            SizedBox(
              height: compact ? 15 : 18,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: KvlText.caption(
                    compact ? 11.5 : 13,
                  ).copyWith(color: KvlColors.inkSoft),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMic extends StatelessWidget {
  const _HeroMic({
    required this.micSize,
    required this.mantraLabel,
    required this.compact,
  });
  final double micSize;
  final String mantraLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: compact ? 0 : 8,
              left: 0,
              right: 0,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Consumer(
                    builder: (context, ref, _) {
                      final settings =
                          ref.watch(settingsProvider).value ??
                          KvlSettings.fallback;
                      final script =
                          settings.languageCode.mantraScriptForLanguage;
                      return Text(
                        mantraLabel,
                        maxLines: 1,
                        style: KvlText.mantraByScript(script, compact ? 64 : 84)
                            .copyWith(
                              color: const Color(
                                0xFFB8B3A2,
                              ).withValues(alpha: .24),
                              fontWeight: FontWeight.w400,
                            ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, h * .14),
              child: SizedBox(
                width: micSize,
                height: micSize,
                child: const CustomPaint(painter: _MicPainter()),
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
    final stroke = Paint()
      ..color = const Color(0xFF202020)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .024
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final centerX = size.width / 2;
    final capsule = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height * .36),
        width: size.width * .31,
        height: size.height * .49,
      ),
      Radius.circular(size.width * .17),
    );
    canvas.drawRRect(capsule, stroke);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, size.height * .47),
        width: size.width * .74,
        height: size.height * .65,
      ),
      0,
      3.14159,
      false,
      stroke,
    );
    canvas.drawLine(
      Offset(centerX, size.height * .77),
      Offset(centerX, size.height * .96),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * .34, size.height * .96),
      Offset(size.width * .66, size.height * .96),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
              'Global Mantra Count : ${IndianNumberFormat.format(globalCount)}',
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
                    const TextSpan(text: 'Yours : '),
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
            label: 'Finish',
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.state, required this.compact});
  final PracticeState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = state.program.dailyTarget == 0
        ? 0.0
        : (state.todaysTotal / state.program.dailyTarget)
              .clamp(0, 1)
              .toDouble();
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
                    '${IndianNumberFormat.format(state.todaysTotal)} / ${IndianNumberFormat.format(state.program.dailyTarget)}',
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

class _MicErrorCard extends StatelessWidget {
  const _MicErrorCard({
    required this.message,
    required this.showOpenSettings,
    required this.onOpenSettings,
    required this.onSwitchManual,
    required this.onDismiss,
  });
  final String message;
  final bool showOpenSettings;
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
