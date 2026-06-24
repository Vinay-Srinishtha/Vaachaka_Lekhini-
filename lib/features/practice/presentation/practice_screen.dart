import 'dart:async';
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
        return _PracticeDashboard(
          state: state,
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

class _PracticeDashboard extends ConsumerStatefulWidget {
  const _PracticeDashboard({
    required this.state,
    required this.programs,
    required this.onSelectProgram,
  });

  final _PracticeDashboardState state;
  final List<Program> programs;
  final ValueChanged<Program> onSelectProgram;

  @override
  ConsumerState<_PracticeDashboard> createState() => _PracticeDashboardView();
}

class _PracticeDashboardView extends ConsumerState<_PracticeDashboard> {
  bool _showProgramPicker = false;
  Timer? _statsRefreshTimer;

  @override
  void initState() {
    super.initState();
    // Re-poll global stats every 30 s so counters roll live.
    _statsRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(
          globalStatsProvider(widget.state.program.mantraId),
        );
      }
    });
  }

  @override
  void dispose() {
    _statsRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.state.program;
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final title =
        widget.state.mantra?.name.displayForLanguage(settings.languageCode) ??
        program.mantraId;
    final total = program.totalProgress;
    final target = program.targetWritings;
    final toGoal = (target - total).clamp(0, target);
    final progress = target <= 0
        ? 0.0
        : (total / target).clamp(0, 1).toDouble();

    // todaysCount only — stats are watched inside _LiveStatsBar to scope rebuilds.
    final todaysCount = widget.state.todaysCount;

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final compact = height < 760;
          final tight = height < 700;
          final gap = tight ? KvlSpacing.sm : KvlSpacing.md;
          final ringSize = tight ? 200.0 : compact ? 232.0 : 260.0;

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

                    // ── Community stats ───────────────────────────────────────
                    _LiveStatsBar(
                      mantraId: program.mantraId,
                      mantraName: title,
                      myTotal: total,
                      todaysCount: todaysCount,
                      compact: compact,
                    ),
                    SizedBox(height: tight ? KvlSpacing.xs : gap),

                    // ── Progress ring (hero) ──────────────────────────────────
                    Expanded(
                      child: _ProgressRing(
                        progress: progress,
                        total: total,
                        target: target,
                        todaysCount: widget.state.todaysCount,
                        compact: compact,
                        size: ringSize,
                      ),
                    ),
                    SizedBox(height: tight ? KvlSpacing.xs : gap),

                    // ── Today / Milestone ─────────────────────────────────────
                    _StatsRow(
                      todaysCount: widget.state.todaysCount,
                      dailyTarget: program.dailyTarget,
                      toGoal: toGoal,
                      compact: compact,
                    ),
                    SizedBox(height: tight ? KvlSpacing.xs : gap),

                    // ── Quick actions ─────────────────────────────────────────
                    _ActionsRow(
                      compact: compact,
                      onSessionStats: () => context.push(
                        '${KvlRoute.dailyProgress}/${program.id}',
                      ),
                      programs: widget.programs,
                      currentProgramId: program.id,
                      onSwitchProgram: widget.onSelectProgram,
                    ),
                    SizedBox(height: tight ? KvlSpacing.xs : gap),

                    // ── Days note ─────────────────────────────────────────────
                    _TotalDaysNote(days: program.daysElapsed, compact: compact),
                    SizedBox(height: tight ? KvlSpacing.sm : KvlSpacing.md),

                    // ── START ─────────────────────────────────────────────────
                    Center(
                      child: SizedBox(
                        width: tight ? 220 : 260,
                        child: total >= target
                            ? KvlButton(
                                label: '🎉 Congratulations!',
                                onPressed: null,
                              )
                            : KvlButton(
                                label: 'START',
                                onPressed: () => context.push(
                                  '${KvlRoute.practice}/${program.id}',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                // ── Program picker overlay ────────────────────────────────────
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
}

// ── Live stats bar — no containers, rolling digits, JioHotstar-style ─────────

// Watches globalStatsProvider internally — only this widget rebuilds on stats
// refresh, never the full screen (fixing the whole-page flash on 30s poll).
class _LiveStatsBar extends ConsumerWidget {
  const _LiveStatsBar({
    required this.mantraId,
    required this.mantraName,
    required this.myTotal,
    required this.todaysCount,
    required this.compact,
  });

  final String mantraId;
  final String mantraName;
  final int myTotal;
  final int todaysCount;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(globalStatsProvider(mantraId));
    final loading = statsAsync.isLoading && !statsAsync.hasValue;
    final serverGlobal = statsAsync.value?.globalChantCount ?? 0;
    final communityTotal = [serverGlobal, myTotal, serverGlobal + todaysCount]
        .reduce((a, b) => a > b ? a : b);
    final liveUsers = statsAsync.value?.liveCount ?? 0;

    final numSize = compact ? 20.0 : 23.0;
    final labelSize = compact ? 10.0 : 11.0;

    Widget divider() => Container(
          width: 1, height: 32,
          color: KvlColors.border.withValues(alpha: .5),
        );

    Widget stat({
      required Widget leading,
      required int value,
      required String label,
      required Color color,
      bool showShimmer = false,
    }) =>
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  leading,
                  const SizedBox(width: 4),
                  if (showShimmer)
                    _Shimmer(width: 44, height: numSize)
                  else
                    _RollingCounter(value: value, fontSize: numSize, color: color),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KvlText.caption(labelSize)
                    .copyWith(color: KvlColors.inkSoft, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // ── Total Sadhanas ──────────────────────────────────────────────────
        stat(
          leading: Icon(Icons.public_rounded,
              size: compact ? 18 : 20, color: KvlColors.primaryDeep),
          value: communityTotal,
          label: 'Total Sadhanas',
          color: KvlColors.primaryDeep,
          showShimmer: loading,
        ),

        divider(),

        // ── Live Devotees ───────────────────────────────────────────────────
        stat(
          leading: const _LivePulseDot(),
          value: liveUsers,
          label: 'Live Devotees',
          color: KvlColors.accent,
          showShimmer: loading,
        ),

        divider(),

        // ── My total for this mantra ────────────────────────────────────────
        stat(
          leading: const SizedBox.shrink(),
          value: myTotal,
          label: 'Total $mantraName',
          color: const Color(0xFF7E2F08),
          showShimmer: false,
        ),
      ],
    );
  }
}

// ── Rolling digit counter ─────────────────────────────────────────────────────

class _RollingCounter extends StatelessWidget {
  const _RollingCounter({
    required this.value,
    required this.fontSize,
    required this.color,
  });

  final int value;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final formatted = IndianNumberFormat.format(value);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
          for (var i = 0; i < formatted.length; i++)
            _RollingDigit(
              key: ValueKey('$i-${formatted[i]}-$value'),
              char: formatted[i],
              fontSize: fontSize,
              color: color,
            ),
        ],
    );
  }
}

class _RollingDigit extends StatelessWidget {
  const _RollingDigit({
    super.key,
    required this.char,
    required this.fontSize,
    required this.color,
  });

  final String char;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDigit = char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
    return AnimatedSwitcher(
      duration: Duration(milliseconds: isDigit ? 380 : 0),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.8),
          end: Offset.zero,
        ).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Text(
        char,
        key: ValueKey(char),
        style: KvlText.ui(fontSize, FontWeight.w800).copyWith(color: color),
      ),
    );
  }
}

// ── Pulsing live dot ──────────────────────────────────────────────────────────

class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot();

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE53935).withValues(alpha: .5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.width, required this.height});
  final double width;
  final double height;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: KvlColors.border.withValues(alpha: .3 + _ctrl.value * .3),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ── Stats row (Today / Milestone) ─────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.todaysCount,
    required this.dailyTarget,
    required this.toGoal,
    required this.compact,
  });

  final int todaysCount;
  final int dailyTarget;
  final int toGoal;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 82.0 : 92.0;
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            height: h,
            icon: Icons.calendar_today_rounded,
            iconColor: KvlColors.accent,
            iconBg: KvlColors.accentSoft,
            label: context.l10n.todaysCount,
            value:
                '${IndianNumberFormat.format(todaysCount)} / ${IndianNumberFormat.format(dailyTarget)}',
            valueColor: KvlColors.accent,
            compact: compact,
          ),
        ),
        const SizedBox(width: KvlSpacing.md),
        Expanded(
          child: _StatChip(
            height: h,
            icon: Icons.emoji_events_rounded,
            iconColor: KvlColors.gold,
            iconBg: const Color(0xFFFFF3CC),
            label: context.l10n.toMilestone,
            value: toGoal == 0
                ? context.l10n.milestoneCompleted
                : context.l10n.milestoneLeft(toGoal),
            valueColor: KvlColors.primaryDeep,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.height,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.compact,
  });

  final double height;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final Color valueColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12.0 : 14.0,
        vertical: compact ? 10.0 : 12.0,
      ),
      decoration: BoxDecoration(
        color: KvlColors.surface,
        borderRadius: KvlRadius.brLG,
        border: Border.all(color: KvlColors.border.withValues(alpha: .5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 34 : 38,
            height: compact ? 34 : 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: compact ? 18 : 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KvlText.caption(compact ? 10.5 : 11.5).copyWith(
                    color: KvlColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: KvlText.ui(compact ? 13 : 14.5, FontWeight.w700)
                        .copyWith(color: valueColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Actions row ───────────────────────────────────────────────────────────────

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.compact,
    required this.onSessionStats,
    required this.programs,
    required this.currentProgramId,
    required this.onSwitchProgram,
  });

  final bool compact;
  final VoidCallback onSessionStats;
  final List<Program> programs;
  final String currentProgramId;
  final ValueChanged<Program> onSwitchProgram;

  void _showSwitchSheet(BuildContext context) {
    final switchable = programs
        .where((p) => p.id != currentProgramId && !p.isCompleted && p.hasGoal)
        .toList();
    if (switchable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other active programs to switch to.')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SwitchProgramSheet(
        programs: switchable,
        onSelect: onSwitchProgram,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = compact ? 50.0 : 56.0;
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            height: h,
            icon: Icons.bar_chart_rounded,
            iconBg: KvlColors.accentSoft,
            iconColor: KvlColors.accent,
            label: context.l10n.sessionStats,
            compact: compact,
            onTap: onSessionStats,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            height: h,
            icon: Icons.swap_horiz_rounded,
            iconBg: KvlColors.primary.withValues(alpha: 0.10),
            iconColor: KvlColors.primaryDeep,
            label: 'Switch Program',
            compact: compact,
            onTap: () => _showSwitchSheet(context),
          ),
        ),
      ],
    );
  }
}

class _SwitchProgramSheet extends ConsumerWidget {
  const _SwitchProgramSheet({required this.programs, required this.onSelect});
  final List<Program> programs;
  final ValueChanged<Program> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFDF8F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: KvlColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Switch Program', style: KvlText.title(16)),
          const SizedBox(height: 4),
          Text(
            'Select a program to practice',
            style: KvlText.caption(12).copyWith(color: KvlColors.inkSoft),
          ),
          const SizedBox(height: 14),
          ...programs.map((p) {
            final mantra = ref.watch(mantraByIdProvider(p.mantraId));
            final label = mantra?.name.displayForLanguage(settings.languageCode)
                ?? p.mantraId;
            final progress = p.targetWritings > 0
                ? (p.totalProgress / p.targetWritings).clamp(0.0, 1.0)
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onSelect(p);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white,
                    border: Border.all(
                      color: KvlColors.primary.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: KvlColors.primary.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD49A), KvlColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          mantra?.name.thumbGlyph() ?? '🕉',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label,
                                style: KvlText.ui(14, FontWeight.w700)),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 4,
                                backgroundColor:
                                    KvlColors.primary.withValues(alpha: 0.12),
                                valueColor: const AlwaysStoppedAnimation(
                                    KvlColors.primary),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${IndianNumberFormat.format(p.totalProgress)} / ${IndianNumberFormat.format(p.targetWritings)}',
                              style: KvlText.caption(11)
                                  .copyWith(color: KvlColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: KvlColors.inkSoft, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.height,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.compact,
    required this.onTap,
  });

  final double height;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: KvlRadius.brLG,
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10.0 : 12.0,
            vertical: compact ? 8.0 : 10.0,
          ),
          decoration: BoxDecoration(
            color: KvlColors.surface,
            borderRadius: KvlRadius.brLG,
            border: Border.all(color: KvlColors.border.withValues(alpha: .5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: compact ? 17 : 19),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: KvlText.ui(compact ? 13.5 : 15, FontWeight.w600)
                        .copyWith(color: KvlColors.ink),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: KvlColors.muted,
                size: compact ? 18 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Progress ring ─────────────────────────────────────────────────────────────

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.total,
    required this.target,
    required this.todaysCount,
    required this.compact,
    required this.size,
  });

  final double progress;
  final int total;
  final int target;
  final int todaysCount;
  final bool compact;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow layer
            CustomPaint(
              size: Size.square(size),
              painter: _RingGlowPainter(progress: progress),
            ),
            // Main ring
            CustomPaint(
              size: Size.square(size),
              painter: _ProgressRingPainter(progress: progress),
            ),
            // Center content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    IndianNumberFormat.format(total),
                    style: KvlText.ui(compact ? 26 : 30, FontWeight.w800)
                        .copyWith(color: KvlColors.ink),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '/ ${IndianNumberFormat.format(target)}',
                  style: KvlText.caption(compact ? 13 : 14.5)
                      .copyWith(color: KvlColors.muted),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: KvlColors.primarySoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pct%',
                    style: KvlText.ui(compact ? 11 : 12, FontWeight.w700)
                        .copyWith(color: KvlColors.primaryDeep),
                  ),
                ),
                if (todaysCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: KvlColors.accentSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Today: ${IndianNumberFormat.format(todaysCount)}',
                      style: KvlText.caption(compact ? 10 : 11).copyWith(
                        color: KvlColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
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

class _RingGlowPainter extends CustomPainter {
  const _RingGlowPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final glow = Paint()
      ..color = const Color(0xFFE8893B).withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      glow,
    );
  }

  @override
  bool shouldRepaint(_RingGlowPainter old) => old.progress != progress;
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    final track = Paint()
      ..color = const Color(0xFFEAD8B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    // Gradient progress arc
    final sweepAngle = 2 * math.pi * progress.clamp(0, 1);
    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweepAngle,
      colors: const [Color(0xFFFFB572), Color(0xFFE8893B), Color(0xFFC97328)],
      tileMode: TileMode.clamp,
    ).createShader(rect);

    final fg = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, fg);

    // End dot
    final endAngle = -math.pi / 2 + sweepAngle;
    final dotCenter = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    canvas.drawCircle(
      dotCenter,
      9,
      Paint()..color = const Color(0xFFC97328),
    );
    canvas.drawCircle(
      dotCenter,
      5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}

// ── Days note ─────────────────────────────────────────────────────────────────

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
          style: KvlText.ui(compact ? 13.5 : 15, FontWeight.w500)
              .copyWith(color: KvlColors.inkSoft),
          children: [
            TextSpan(text: context.l10n.practisingFor),
            TextSpan(
              text: days == 1
                  ? context.l10n.practiceDay(days)
                  : context.l10n.practiceDays(days),
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

// ── Header ────────────────────────────────────────────────────────────────────

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
    final initial = (profile?.name.trim().isNotEmpty == true)
        ? profile!.name.trim()[0].toUpperCase()
        : '?';

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
            style: KvlText.ui(18, FontWeight.w700)
                .copyWith(color: const Color(0xFF323232)),
          ),
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD49A), KvlColors.primary],
              ),
              border: Border.all(
                color: KvlColors.primaryDeep.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: KvlColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: KvlText.ui(16, FontWeight.w800)
                  .copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Program picker ────────────────────────────────────────────────────────────

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
                                  color: KvlColors.primary.withValues(alpha: .18),
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
                                    style: KvlText.ui(16, FontWeight.w800)
                                        .copyWith(color: KvlColors.primaryDeep),
                                  ),
                                  Text(
                                    context.l10n.selectActiveProgramDescription,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: KvlText.caption(11)
                                        .copyWith(color: KvlColors.inkSoft),
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
                                          style: KvlText.ui(17, FontWeight.w800)
                                              .copyWith(color: KvlColors.ink),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${IndianNumberFormat.format(program.totalProgress)} / ${IndianNumberFormat.format(program.targetWritings)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: KvlText.caption(12.5)
                                              .copyWith(color: KvlColors.inkSoft),
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

// ── Empty state ───────────────────────────────────────────────────────────────

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
