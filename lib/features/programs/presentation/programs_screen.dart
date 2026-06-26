import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/program.dart';
import 'book_preview_sheet.dart';

class ProgramsScreen extends ConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(programsForActiveProfileProvider);
    return programsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e', style: KvlText.body())),
      data: (programs) => _Body(programs: programs),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.programs});
  final List<Program> programs;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body>
    with SingleTickerProviderStateMixin {
  bool _showCompleted = false;
  late AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Animation<double> _itemAnim(int index) {
    final start = (index * 0.08).clamp(0.0, 0.7);
    final end = (start + 0.4).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _animated(Widget child, int index) {
    final anim = _itemAnim(index);
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - anim.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final programs = widget.programs;
    // Goal-less programs are split out into the Bonus Chants section below.
    final active =
        programs.where((p) => p.hasGoal && !p.isGoalReached).toList();
    final completed =
        programs.where((p) => p.hasGoal && p.isGoalReached).toList();

    // Bonus chants: goal-less programs with recorded chants, grouped per mantra
    // (most-recent program per mantra is the representative the card opens).
    final bonusByMantra = <String, List<Program>>{};
    for (final p in programs.where((p) => p.isBonus)) {
      (bonusByMantra[p.mantraId] ??= []).add(p);
    }

    // Overall progress is based on active programs only
    final activeTarget = active.fold<int>(0, (a, p) => a + p.targetWritings);
    final overallProgress = (active.isEmpty || activeTarget == 0)
        ? 0.0
        : (active.fold<int>(0, (a, p) => a + p.totalProgress) / activeTarget)
            .clamp(0.0, 1.0);
    final totalChants = programs.fold<int>(0, (a, p) => a + p.totalProgress);
    final daysAvg = active.isEmpty
        ? 0
        : (active.map((p) => p.daysElapsed).reduce((a, b) => a + b) /
                  active.length)
              .round();

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        KvlSpacing.lg,
        KvlSpacing.lg + 100,
        KvlSpacing.lg,
        bottomInset + 104,
      ),
      children: [
        _animated(
          KvlCard(
            variant: KvlCardVariant.soft,
            padding: const EdgeInsets.fromLTRB(
              KvlSpacing.lg,
              KvlSpacing.lg,
              KvlSpacing.lg,
              KvlSpacing.md,
            ),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFBC70), KvlColors.primary],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active.isEmpty && completed.isNotEmpty
                      ? context.l10n.allSadhanasComplete
                      : active.isEmpty
                          ? context.l10n.everyJourneyBegins
                          : context.l10n.keepChanting,
                  style: KvlText.body(13).copyWith(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: KvlSpacing.md),
                Wrap(
                  spacing: KvlSpacing.lg,
                  runSpacing: KvlSpacing.sm,
                  children: [
                    _Kpi(
                      label: context.l10n.totalChants,
                      value: IndianNumberFormat.compact(totalChants),
                      onDark: true,
                    ),
                    _Kpi(
                      label: context.l10n.complete,
                      value: '${(overallProgress * 100).round()}%',
                      onDark: true,
                    ),
                    _Kpi(
                      label: context.l10n.daysPractising,
                      value: '$daysAvg',
                      onDark: true,
                    ),
                    _Kpi(
                      label: context.l10n.programs,
                      value: '${active.length}',
                      onDark: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          0,
        ),
        const SizedBox(height: KvlSpacing.md),
        _animated(
          Center(child: _OverallRing(progress: overallProgress)),
          1,
        ),
        const SizedBox(height: KvlSpacing.md),
        _animated(
          KvlButton(
            label: context.l10n.createNewProgramButton,
            icon: Icons.add,
            onPressed: () => context.push(KvlRoute.mantraSelection),
          ),
          2,
        ),
        const SizedBox(height: KvlSpacing.sm),
        _animated(
          OutlinedButton.icon(
            onPressed: () => context.push(KvlRoute.globalSadhanaList),
            icon: const Icon(Icons.public_rounded, size: 18),
            label: Text(context.l10n.browseGlobalSadhanas),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: KvlColors.primary,
              side: BorderSide(color: KvlColors.primary),
            ),
          ),
          3,
        ),
        const SizedBox(height: KvlSpacing.md),
        _animated(
          Text(context.l10n.myRecitationPrograms, style: KvlText.title(16)),
          4,
        ),
        const SizedBox(height: KvlSpacing.sm),
        if (active.isEmpty && completed.isEmpty)
          _animated(
            KvlCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    color: KvlColors.muted,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(context.l10n.noProgramsYet, style: KvlText.title(13)),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.pickMantraAndTargetToStart,
                    textAlign: TextAlign.center,
                    style: KvlText.caption(11.5),
                  ),
                ],
              ),
            ),
            5,
          )
        else if (active.isEmpty)
          _animated(
            KvlCard(
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: KvlColors.primary, size: 36),
                  const SizedBox(height: 8),
                  Text('No active Sadhanas', style: KvlText.title(13)),
                  const SizedBox(height: 4),
                  Text(
                    'Start a new one to keep your practice going.',
                    textAlign: TextAlign.center,
                    style: KvlText.caption(11.5),
                  ),
                ],
              ),
            ),
            5,
          )
        else ...[
          for (var i = 0; i < active.length; i++) ...[
            _animated(_ProgramCard(program: active[i]), 5 + i),
            const SizedBox(height: KvlSpacing.sm),
          ],
        ],
        if (completed.isNotEmpty) ...[
          const SizedBox(height: KvlSpacing.sm),
          _animated(
            _ViewCompletedButton(
              count: completed.length,
              expanded: _showCompleted,
              onTap: () => setState(() => _showCompleted = !_showCompleted),
            ),
            5 + active.length,
          ),
          if (_showCompleted) ...[
            const SizedBox(height: KvlSpacing.sm),
            for (var i = 0; i < completed.length; i++) ...[
              _animated(
                _ProgramCard(program: completed[i]),
                6 + active.length + i,
              ),
              const SizedBox(height: KvlSpacing.sm),
            ],
          ],
        ],
        if (bonusByMantra.isNotEmpty) ...[
          const SizedBox(height: KvlSpacing.lg),
          _animated(
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    size: 18, color: KvlColors.primary),
                const SizedBox(width: 6),
                Text('Bonus Chants', style: KvlText.title(16)),
              ],
            ),
            5 + active.length + 1,
          ),
          const SizedBox(height: KvlSpacing.sm),
          for (var i = 0; i < bonusByMantra.entries.length; i++) ...[
            _animated(
              _BonusCard(
                programs: bonusByMantra.values.elementAt(i),
                total: bonusByMantra.values
                    .elementAt(i)
                    .fold<int>(0, (a, p) => a + p.totalProgress),
              ),
              6 + active.length + i,
            ),
            const SizedBox(height: KvlSpacing.sm),
          ],
        ],
      ],
    );
  }
}

/// One card per mantra summarising chants done without a set goal.
/// Tapping resumes the most-recent bonus program so further chants accumulate.
class _BonusCard extends ConsumerWidget {
  const _BonusCard({required this.programs, required this.total});
  final List<Program> programs;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = programs.first; // most-recent (list ordered desc updatedAt)
    final mantra = ref.watch(mantraByIdProvider(program.mantraId));
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final script = mantra?.name.scriptForLanguage(settings.languageCode) ??
        settings.languageCode.mantraScriptForLanguage;
    final name = mantra?.name.displayForLanguage(settings.languageCode) ??
        program.mantraId;
    final imgUrl = mantra?.previewImageUrl ?? mantra?.imageUrl;
    final glyph = mantra?.name.thumbGlyph() ?? '';

    return KvlCard(
      onTap: () => context.push('${KvlRoute.practice}/${program.id}'),
      child: Row(
        children: [
          MantraThumb(glyph: glyph, imageUrl: imgUrl, size: 46),
          const SizedBox(width: KvlSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: KvlText.bodyByScript(script, 15)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${IndianNumberFormat.format(total)} bonus chants · no goal',
                  style: KvlText.muted(12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => BookPreviewButton.openSheet(context, program.mantraId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 20,
                color: KvlColors.primaryDeep,
              ),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right, color: KvlColors.inkSoft),
        ],
      ),
    );
  }
}

class _ViewCompletedButton extends StatelessWidget {
  const _ViewCompletedButton({
    required this.count,
    required this.expanded,
    required this.onTap,
  });
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md, vertical: 12),
        decoration: BoxDecoration(
          color: KvlColors.primaryGhost,
          borderRadius: KvlRadius.brMD,
          border: Border.all(color: KvlColors.primarySoft, width: 1.2),
        ),
        child: Row(
          children: [
            const Icon(Icons.archive_rounded, size: 18, color: KvlColors.primary),
            const SizedBox(width: KvlSpacing.sm),
            Expanded(
              child: Text(
                expanded
                    ? 'Hide Completed Sadhanas'
                    : 'View Completed Sadhanas ($count)',
                style: KvlText.ui(13, FontWeight.w600).copyWith(color: KvlColors.primaryDeep),
              ),
            ),
            Icon(
              expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: KvlColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, this.onDark = false});
  final String label;
  final String value;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: KvlText.muted(12).copyWith(
              color: onDark ? Colors.white.withValues(alpha: .88) : null,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: KvlText.bigNumber(
              20,
            ).copyWith(color: onDark ? Colors.white : null),
          ),
        ],
      ),
    );
  }
}

class _OverallRing extends StatelessWidget {
  const _OverallRing({required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, value, __) => SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(140, 140),
              painter: _RingPainter(progress: value),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value * 100).round()}%',
                  style: KvlText.bigNumber(22),
                ),
                Text(context.l10n.overallProgress, style: KvlText.muted(9.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final bg = Paint()
      ..color = KvlColors.primarySoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..shader = const LinearGradient(
        colors: [KvlColors.primary, KvlColors.primaryDeep],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _ProgramCard extends ConsumerWidget {
  const _ProgramCard({required this.program});
  final Program program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mantra = ref.watch(mantraByIdProvider(program.mantraId));
    final settings = ref.watch(settingsProvider).value ?? KvlSettings.fallback;
    final script =
        mantra?.name.scriptForLanguage(settings.languageCode) ??
        settings.languageCode.mantraScriptForLanguage;
    final name =
        mantra?.name.displayForLanguage(settings.languageCode) ??
        program.mantraId;
    final complete = program.isCompleted;
    final imgUrl = mantra?.previewImageUrl ?? mantra?.imageUrl;
    final glyph = mantra?.name.thumbGlyph() ?? '';

    return KvlCard(
      onTap: () => context.push('${KvlRoute.practice}/${program.id}'),
      child: Row(
        children: [
          MilestoneRing.fraction(
            fraction: program.progressFraction,
            strokeWidth: 3,
            gap: 2,
            child: MantraThumb(
              glyph: glyph,
              imageUrl: imgUrl,
              size: 40,
            ),
          ),
          const SizedBox(width: KvlSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: KvlText.bodyByScript(script, 14)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  complete
                      ? '${IndianNumberFormat.format(program.totalProgress)} / ${IndianNumberFormat.format(program.targetWritings)} · ${context.l10n.completedWithCheck}'
                      : '${IndianNumberFormat.format(program.totalProgress)} / ${IndianNumberFormat.format(program.targetWritings)}',
                  style: KvlText.muted(11.5).copyWith(
                    color: complete ? KvlColors.success : KvlColors.muted,
                  ),
                ),
              ],
            ),
          ),
          // Book preview button — shows writing samples for this program only
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => BookPreviewButton.openSheet(context, program.mantraId),
            child: Container(
              margin: const EdgeInsets.only(left: 4, right: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: KvlColors.primaryDeep.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: KvlColors.primaryDeep,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: KvlColors.inkSoft, size: 18),
        ],
      ),
    );
  }
}
