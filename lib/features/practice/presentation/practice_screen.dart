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
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
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
  Timer? _statsRefreshTimer;

  @override
  void initState() {
    super.initState();
    _statsRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(globalStatsProvider(widget.state.program.mantraId));
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
    final progress = target <= 0
        ? 0.0
        : (total / target).clamp(0, 1).toDouble();
    final todaysCount = widget.state.todaysCount;
    final streak = widget.state.currentStreak;

    return DecoratedBox(
      decoration: const BoxDecoration(
        // Lighter, warmer radial-ish gradient — bright saffron centre, soft at edges
        gradient: RadialGradient(
          center: Alignment(0, -0.1),
          radius: 1.1,
          colors: [
            Color(0xFFFFCF80), // very light golden centre
            Color(0xFFFFAA44), // warm bright mid
            Color(0xFFE07828), // saffron outer
            Color(0xFFA04010), // deeper burnt edge
          ],
          stops: [0.0, 0.30, 0.62, 1.0],
        ),
      ),
      child: SafeArea(
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
              child: Column(
                children: [
                  _DashboardHeader(
                    title: title,
                    onBack: () => context.popOrGo(KvlRoute.home),
                    onProfileTap: () => context.push(KvlRoute.profile),
                  ),
                  SizedBox(height: tight ? KvlSpacing.xs : gap),

                  // ── Community stats ─────────────────────────────────────
                  _LiveStatsBar(
                    mantraId: program.mantraId,
                    mantraName: title,
                    myTotal: total,
                    todaysCount: todaysCount,
                    compact: compact,
                  ),
                  SizedBox(height: tight ? KvlSpacing.xs : gap),

                  // ── Progress ring ───────────────────────────────────────
                  Expanded(
                    child: _ProgressRing(
                      progress: progress,
                      total: total,
                      target: target,
                      todaysCount: todaysCount,
                      compact: compact,
                      size: ringSize,
                    ),
                  ),
                  SizedBox(height: tight ? KvlSpacing.xs : gap),

                  // ── Two stat cards: Today's chant | Session Stats ───────
                  _StatsRow(
                    todaysCount: todaysCount,
                    onSessionStats: () => context.push(
                      '${KvlRoute.dailyProgress}/${program.id}',
                    ),
                    compact: compact,
                  ),
                  SizedBox(height: tight ? KvlSpacing.xs : gap),

                  // ── Streak pill ─────────────────────────────────────────
                  _StreakNote(streak: streak, compact: compact),
                  SizedBox(height: tight ? KvlSpacing.sm : KvlSpacing.md),

                  // ── START (always) ──────────────────────────────────────
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
            );
          },
        ),
      ),
    );
  }
}

// ── Live stats bar ────────────────────────────────────────────────────────────

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
    final totalSadhanas = statsAsync.value?.memberCount ?? 0;
    final totalChants = statsAsync.value?.globalChantCount ?? 0;
    final liveUsers = statsAsync.value?.liveCount ?? 0;

    final topNumSize = compact ? 17.0 : 19.0;
    final bottomNumSize = compact ? 22.0 : 25.0;
    final labelSize = compact ? 9.5 : 10.5;

    Widget vDivider() => Container(
          width: 1, height: 28,
          color: Colors.white.withValues(alpha: .30),
        );

    Widget topStat({
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
                children: [
                  leading,
                  const SizedBox(width: 4),
                  if (showShimmer)
                    _Shimmer(width: 38, height: topNumSize)
                  else
                    _RollingCounter(value: value, fontSize: topNumSize, color: color),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KvlText.caption(labelSize)
                    .copyWith(color: Colors.white.withValues(alpha: .85), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: KvlSpacing.xs,
        vertical: compact ? 4 : 6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              topStat(
                leading: Icon(Icons.people_alt_rounded,
                    size: compact ? 14 : 15, color: Colors.white),
                value: totalSadhanas,
                label: 'Total Sadhanas',
                color: Colors.white,
                showShimmer: loading,
              ),
              vDivider(),
              topStat(
                leading: const _LivePulseDot(),
                value: liveUsers,
                label: 'Live Devotees',
                color: const Color(0xFFB8F0C8),
                showShimmer: loading,
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: .30),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                _Shimmer(width: 80, height: bottomNumSize)
              else
                _RollingCounter(
                  value: totalChants,
                  fontSize: bottomNumSize,
                  color: Colors.white,
                ),
              const SizedBox(height: 2),
              Text(
                'Total $mantraName',
                style: KvlText.caption(labelSize + 0.5).copyWith(
                  color: Colors.white.withValues(alpha: .85),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
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
          color: const Color(0xFF22C55E),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: .5),
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
          color: Colors.white.withValues(alpha: .15 + _ctrl.value * .15),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

// ── Stats row: Today's chant + Session Stats ──────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.todaysCount,
    required this.onSessionStats,
    required this.compact,
  });

  final int todaysCount;
  final VoidCallback onSessionStats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final h = compact ? 82.0 : 92.0;
    return Row(
      children: [
        // Today's chant — just a big number
        Expanded(
          child: _PremiumCard(
            height: h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  IndianNumberFormat.format(todaysCount),
                  style: KvlText.ui(compact ? 26 : 30, FontWeight.w800)
                      .copyWith(color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  "Today's Chants",
                  style: KvlText.caption(compact ? 10 : 11).copyWith(
                    color: Colors.white.withValues(alpha: .80),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: KvlSpacing.md),
        // Session Stats
        Expanded(
          child: GestureDetector(
            onTap: onSessionStats,
            child: _PremiumCard(
              height: h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: compact ? 34 : 38,
                    height: compact ? 34 : 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .20),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                      size: compact ? 18 : 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Session\nStats',
                      style: KvlText.ui(compact ? 13 : 14, FontWeight.w700)
                          .copyWith(color: Colors.white),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: .60),
                    size: compact ? 18 : 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Premium glass card ────────────────────────────────────────────────────────

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.height, required this.child});
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .28),
            Colors.white.withValues(alpha: .12),
          ],
        ),
        borderRadius: KvlRadius.brLG,
        border: Border.all(color: Colors.white.withValues(alpha: .35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
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
            CustomPaint(
              size: Size.square(size),
              painter: _RingGlowPainter(progress: progress),
            ),
            CustomPaint(
              size: Size.square(size),
              painter: _ProgressRingPainter(progress: progress),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    IndianNumberFormat.format(total),
                    style: KvlText.ui(compact ? 26 : 30, FontWeight.w800)
                        .copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '/ ${IndianNumberFormat.format(target)}',
                  style: KvlText.caption(compact ? 13 : 14.5)
                      .copyWith(color: Colors.white.withValues(alpha: .75)),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pct%',
                    style: KvlText.ui(compact ? 11 : 12, FontWeight.w700)
                        .copyWith(color: Colors.white),
                  ),
                ),
                if (todaysCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Today: ${IndianNumberFormat.format(todaysCount)}',
                      style: KvlText.caption(compact ? 10 : 11).copyWith(
                        color: Colors.white,
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
      ..color = Colors.white.withValues(alpha: .20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(rect, -math.pi / 2,
        2 * math.pi * progress.clamp(0, 1), false, glow);
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

    final track = Paint()
      ..color = Colors.white.withValues(alpha: .20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final sweepAngle = 2 * math.pi * progress.clamp(0, 1);
    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + sweepAngle,
      colors: const [Color(0xFFFFEE88), Color(0xFFFFBB44), Color(0xFFFF7700)],
      tileMode: TileMode.clamp,
    ).createShader(rect);

    final fg = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, fg);

    final endAngle = -math.pi / 2 + sweepAngle;
    final dotCenter = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );
    canvas.drawCircle(dotCenter, 9, Paint()..color = const Color(0xFFFF8800));
    canvas.drawCircle(dotCenter, 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}

// ── Streak note ───────────────────────────────────────────────────────────────

class _StreakNote extends StatelessWidget {
  const _StreakNote({required this.streak, required this.compact});
  final int streak;
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
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: .28),
            Colors.white.withValues(alpha: .14),
          ],
        ),
        borderRadius: KvlRadius.brPill,
        border: Border.all(color: Colors.white.withValues(alpha: .35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text.rich(
            TextSpan(
              style: KvlText.ui(compact ? 13.5 : 15, FontWeight.w500)
                  .copyWith(color: Colors.white.withValues(alpha: .90)),
              children: [
                const TextSpan(text: 'Practice streak: '),
                TextSpan(
                  text: streak == 1 ? '1 day' : '$streak days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
          color: Colors.white,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KvlText.ui(18, FontWeight.w700).copyWith(color: Colors.white),
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
                color: Colors.white.withValues(alpha: .40),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: KvlText.ui(16, FontWeight.w800).copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
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
