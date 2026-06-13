import 'dart:math' as math;

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
import '../../mantras/domain/mantra.dart';
import '../../programs/domain/program.dart';
import '../../settings/domain/settings_repository.dart';
import '../../../l10n/l10n.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  String? _selectedProgramId;

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(_practiceDashboardProvider(_selectedProgramId));
    final programs =
        (ref.watch(programsForActiveProfileProvider).value ?? const <Program>[])
            .where((program) => !program.isCompleted)
            .toList();

    return dashboard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e', style: KvlText.body())),
      data: (state) {
        if (state == null) return const _EmptyPractice();
        final liveUsers =
            ref.watch(_openSessionCountProvider(state.program.id)).value ?? 0;
        return _PracticeDashboard(
          state: state,
          liveUsers: liveUsers,
          programs: programs,
          onSelectProgram: (program) {
            setState(() => _selectedProgramId = program.id);
          },
        );
      },
    );
  }
}

class _PracticeDashboardState {
  const _PracticeDashboardState({
    required this.program,
    required this.mantra,
    required this.todaysCount,
    required this.currentStreak,
  });

  final Program program;
  final Mantra? mantra;
  final int todaysCount;
  final int currentStreak;
}

final _practiceDashboardProvider =
    FutureProvider.family<_PracticeDashboardState?, String?>((
      ref,
      programId,
    ) async {
      ref.watch(programsForActiveProfileProvider);
      Program? program;
      if (programId != null) {
        program = await ref.watch(programRepositoryProvider).getById(programId);
      }
      program ??= await ref.watch(mostRecentProgramProvider.future);
      if (program == null) return null;

      final repo = ref.watch(programRepositoryProvider);
      final today = DateTime.now();
      final todaysCount = await repo.countForDay(program.id, today);
      final currentStreak = await repo.currentStreak(program.id);
      final mantra = ref.watch(mantraByIdProvider(program.mantraId));

      return _PracticeDashboardState(
        program: program,
        mantra: mantra,
        todaysCount: todaysCount,
        currentStreak: currentStreak,
      );
    });

final _openSessionCountProvider = StreamProvider.family<int, String>((
  ref,
  programId,
) async* {
  final repo = ref.watch(programRepositoryProvider);
  yield* repo
      .watchSessionsForProgram(programId)
      .map((sessions) => sessions.where((s) => s.isOpen).length);
});

class _PracticeDashboard extends ConsumerStatefulWidget {
  const _PracticeDashboard({
    required this.state,
    required this.liveUsers,
    required this.programs,
    required this.onSelectProgram,
  });

  final _PracticeDashboardState state;
  final int liveUsers;
  final List<Program> programs;
  final ValueChanged<Program> onSelectProgram;

  @override
  ConsumerState<_PracticeDashboard> createState() => _PracticeDashboardView();
}

class _PracticeDashboardView extends ConsumerState<_PracticeDashboard> {
  bool _showProgramPicker = false;

  @override
  Widget build(BuildContext context) {
    final program = widget.state.program;
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final title =
        widget.state.mantra?.name.displayForLanguage(settings.languageCode) ??
        program.mantraId;
    final total = program.totalProgress;
    final target = program.targetWritings;
    final milestoneLeft = _chantsToNextMilestone(total);
    final progress = target <= 0
        ? 0.0
        : (total / target).clamp(0, 1).toDouble();

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final compact = height < 760;
          final tight = height < 700;
          final metricHeight = tight
              ? 116.0
              : compact
              ? 124.0
              : 132.0;
          final actionHeight = tight ? 52.0 : 58.0;
          final statHeight = tight
              ? 96.0
              : compact
              ? 104.0
              : 114.0;
          final ringSize = tight
              ? 228.0
              : compact
              ? 264.0
              : 292.0;
          final gap = tight ? KvlSpacing.sm : KvlSpacing.md;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              KvlSpacing.lg,
              tight ? KvlSpacing.xs : KvlSpacing.sm,
              KvlSpacing.lg,
              tight ? KvlSpacing.sm : KvlSpacing.md,
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    _DashboardHeader(
                      title: title,
                      onBack: () => context.popOrGo(KvlRoute.home),
                      onProfileTap: () => context.push(KvlRoute.profile),
                    ),
                    SizedBox(height: tight ? KvlSpacing.xs : gap),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.self_improvement_rounded,
                            iconColor: KvlColors.primary,
                            label: 'Global Count',
                            value: IndianNumberFormat.format(total),
                            valueColor: Colors.red,
                            height: metricHeight,
                            compact: compact,
                          ),
                        ),
                        const SizedBox(width: KvlSpacing.md),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.people_alt_rounded,
                            iconColor: KvlColors.accent,
                            label: 'Open sessions',
                            value: IndianNumberFormat.format(widget.liveUsers),
                            valueColor: Colors.red,
                            height: metricHeight,
                            compact: compact,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: tight ? KvlSpacing.xs : gap),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.music_note_rounded,
                            label: 'Change Mantra',
                            height: actionHeight,
                            compact: compact,
                            onTap: () => setState(
                              () => _showProgramPicker = !_showProgramPicker,
                            ),
                          ),
                        ),
                        const SizedBox(width: KvlSpacing.md),
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.bar_chart_rounded,
                            label: context.l10n.sessionStats,
                            height: actionHeight,
                            compact: compact,
                            onTap: () => context.push(
                              '${KvlRoute.dailyProgress}/${program.id}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: tight ? KvlSpacing.xs : gap),
                    Row(
                      children: [
                        Expanded(
                          child: _SmallStatCard(
                            icon: Icons.calendar_today_outlined,
                            iconColor: KvlColors.accent,
                            label: context.l10n.todaysCount,
                            value:
                                '${IndianNumberFormat.format(widget.state.todaysCount)} / ${IndianNumberFormat.format(program.dailyTarget)}',
                            height: statHeight,
                            compact: compact,
                          ),
                        ),
                        const SizedBox(width: KvlSpacing.md),
                        Expanded(
                          child: _SmallStatCard(
                            icon: Icons.celebration_outlined,
                            iconColor: const Color(0xFFFFB572),
                            label: context.l10n.toMilestone,
                            value: milestoneLeft == 0
                                ? context.l10n.milestoneCompleted
                                : context.l10n.milestoneLeft(milestoneLeft),
                            height: statHeight,
                            compact: compact,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: tight ? KvlSpacing.xs : gap),
                    Expanded(
                      child: _ProgressRing(
                        progress: progress,
                        total: total,
                        target: target,
                        compact: compact,
                        size: ringSize,
                      ),
                    ),
                    _TotalDaysNote(days: program.daysElapsed, compact: compact),
                    SizedBox(height: tight ? KvlSpacing.xs : gap),
                    Center(
                      child: SizedBox(
                        width: tight ? 220 : 260,
                        child: KvlButton(
                          label: 'START',
                          onPressed: () => context.push(
                            '${KvlRoute.practice}/${program.id}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showProgramPicker)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => setState(() => _showProgramPicker = false),
                    ),
                  ),
                if (_showProgramPicker)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: tight ? 58 : 66,
                    child: _ProgramPickerPanel(
                      currentProgramId: program.id,
                      programs: widget.programs,
                      settings: settings,
                      onSelect: (selected) {
                        widget.onSelectProgram(selected);
                        setState(() => _showProgramPicker = false);
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _chantsToNextMilestone(int total) {
    for (final threshold in ref.read(rewardRulesProvider).milestoneThresholds) {
      if (total < threshold) return threshold - total;
    }
    return 0;
  }
}

class _ProgramPickerPanel extends ConsumerWidget {
  const _ProgramPickerPanel({
    required this.currentProgramId,
    required this.programs,
    required this.settings,
    required this.onSelect,
  });

  final String currentProgramId;
  final List<Program> programs;
  final KvlSettings settings;
  final ValueChanged<Program> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        constraints: const BoxConstraints(maxHeight: 336),
        decoration: BoxDecoration(
          color: KvlColors.surface.withValues(alpha: .96),
          borderRadius: KvlRadius.brLG,
          border: Border.all(color: KvlColors.border.withValues(alpha: .55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: KvlRadius.brLG,
          child: programs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(KvlSpacing.lg),
                  child: Text(
                    context.l10n.noActivePrograms,
                    textAlign: TextAlign.center,
                    style: KvlText.body().copyWith(color: KvlColors.inkSoft),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [KvlColors.primaryGhost, Color(0xFFFFF8EA)],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          KvlSpacing.lg,
                          KvlSpacing.md,
                          KvlSpacing.lg,
                          KvlSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: KvlColors.primarySoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: KvlColors.primary.withValues(
                                    alpha: .18,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.music_note_rounded,
                                color: KvlColors.primaryDeep,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: KvlSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.chooseMantra,
                                    style: KvlText.ui(
                                      16,
                                      FontWeight.w800,
                                    ).copyWith(color: KvlColors.primaryDeep),
                                  ),
                                  Text(
                                    context.l10n.selectActiveProgramDescription,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: KvlText.caption(
                                      11,
                                    ).copyWith(color: KvlColors.inkSoft),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: KvlColors.border.withValues(alpha: .42),
                    ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: programs.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: KvlColors.border.withValues(alpha: .38),
                        ),
                        itemBuilder: (context, index) {
                          final program = programs[index];
                          final mantra = ref.watch(
                            mantraByIdProvider(program.mantraId),
                          );
                          final title =
                              mantra?.name.displayForLanguage(
                                settings.languageCode,
                              ) ??
                              program.mantraId;
                          final selected = program.id == currentProgramId;
                          return InkWell(
                            onTap: () => onSelect(program),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: KvlSpacing.lg,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: selected
                                          ? KvlColors.primarySoft
                                          : KvlColors.bg,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      selected
                                          ? Icons.check_rounded
                                          : Icons.self_improvement_rounded,
                                      color: selected
                                          ? KvlColors.primary
                                          : KvlColors.accent,
                                      size: 23,
                                    ),
                                  ),
                                  const SizedBox(width: KvlSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: KvlText.ui(
                                            17,
                                            FontWeight.w800,
                                          ).copyWith(color: KvlColors.ink),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${IndianNumberFormat.format(program.totalProgress)} / ${IndianNumberFormat.format(program.targetWritings)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: KvlText.caption(
                                            12.5,
                                          ).copyWith(color: KvlColors.inkSoft),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader({
    required this.title,
    required this.onBack,
    required this.onProfileTap,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider).value;
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 28),
          color: const Color(0xFF333333),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KvlText.ui(
              18,
              FontWeight.w700,
            ).copyWith(color: const Color(0xFF323232)),
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
              profile?.initials ?? '?',
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.height,
    required this.compact,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      height: height,
      padding: EdgeInsets.all(compact ? KvlSpacing.md : KvlSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: compact ? 23 : 26),
          const SizedBox(height: KvlSpacing.xs),
          SizedBox(
            height: compact ? 30 : 34,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: KvlText.ui(compact ? 16 : 18, FontWeight.w400),
                ),
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: compact ? 28 : 32,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: KvlText.ui(
                    compact ? 22 : 25,
                    FontWeight.w600,
                  ).copyWith(color: valueColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.height,
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double height;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? KvlSpacing.md : KvlSpacing.lg,
        vertical: KvlSpacing.sm,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: KvlColors.accent, size: compact ? 23 : 26),
          const SizedBox(width: KvlSpacing.sm),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: KvlText.ui(compact ? 15 : 17, FontWeight.w400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  const _SmallStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.height,
    required this.compact,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      height: height,
      padding: EdgeInsets.all(compact ? KvlSpacing.md : KvlSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: compact ? 22 : 25),
          const Spacer(),
          SizedBox(
            height: compact ? 24 : 28,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: KvlText.ui(compact ? 14.5 : 16.5, FontWeight.w400),
                ),
              ),
            ),
          ),
          const SizedBox(height: KvlSpacing.xs),
          SizedBox(
            height: compact ? 20 : 22,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: KvlText.caption(
                    compact ? 12.5 : 14,
                  ).copyWith(color: KvlColors.muted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalDaysNote extends StatelessWidget {
  const _TotalDaysNote({required this.days, required this.compact});

  final int days;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: compact ? 2 : 6),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? KvlSpacing.md : KvlSpacing.lg,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: KvlColors.surface.withValues(alpha: .34),
        borderRadius: KvlRadius.brPill,
        border: Border.all(color: KvlColors.border.withValues(alpha: .28)),
      ),
      child: Text.rich(
        TextSpan(
          style: KvlText.ui(
            compact ? 13.5 : 15,
            FontWeight.w500,
          ).copyWith(color: KvlColors.inkSoft),
          children: [
            TextSpan(text: context.l10n.practisingFor),
            TextSpan(
              text: days == 1 ? context.l10n.practiceDay(days) : context.l10n.practiceDays(days),
              style: const TextStyle(
                color: KvlColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.height,
    this.onTap,
    this.padding = const EdgeInsets.all(KvlSpacing.lg),
  });

  final Widget child;
  final double? height;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: KvlColors.surface.withValues(alpha: .72),
        borderRadius: KvlRadius.brLG,
        border: Border.all(color: KvlColors.border.withValues(alpha: .45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(onTap: onTap, borderRadius: KvlRadius.brLG, child: card),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.total,
    required this.target,
    required this.compact,
    required this.size,
  });

  final double progress;
  final int total;
  final int target;
  final bool compact;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _ProgressRingPainter(progress: progress),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  IndianNumberFormat.format(total),
                  style: KvlText.ui(compact ? 18 : 19, FontWeight.w400),
                ),
                const SizedBox(height: 5),
                Text(
                  '/ ${IndianNumberFormat.format(target)}',
                  style: KvlText.caption(
                    compact ? 13.5 : 15,
                  ).copyWith(color: KvlColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 15;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final bg = Paint()
      ..color = const Color(0xFFE0E2E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = const Color(0xFFFF9A34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _EmptyPractice extends StatelessWidget {
  const _EmptyPractice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KvlSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.self_improvement_rounded,
              color: KvlColors.muted,
              size: 56,
            ),
            const SizedBox(height: KvlSpacing.sm),
            Text(context.l10n.noActivePractice, style: KvlText.title(15)),
            const SizedBox(height: 4),
            Text(
              context.l10n.pickMantraAndTarget,
              textAlign: TextAlign.center,
              style: KvlText.caption(11.5),
            ),
            const SizedBox(height: KvlSpacing.md),
            KvlButton(
              label: context.l10n.chooseAMantra,
              icon: Icons.play_arrow_rounded,
              expand: false,
              onPressed: () => context.go(KvlRoute.mantraSelection),
            ),
          ],
        ),
      ),
    );
  }
}
