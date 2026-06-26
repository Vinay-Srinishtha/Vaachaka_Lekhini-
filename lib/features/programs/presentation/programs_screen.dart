import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Reads dedication name from SharedPreferences for a given programId.
/// Returns null if not set.
final _dedicationProvider = FutureProvider.family<String?, String>((ref, programId) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('dedication_$programId');
  if (raw == null || !raw.contains('||')) return null;
  return raw.split('||')[0].trim().isNotEmpty ? raw.split('||')[0].trim() : null;
});

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
    final active =
        programs.where((p) => p.hasGoal && !p.isGoalReached).toList();
    final completed =
        programs.where((p) => p.hasGoal && p.isGoalReached).toList();

    final bonusByMantra = <String, List<Program>>{};
    for (final p in programs.where((p) => p.isBonus)) {
      (bonusByMantra[p.mantraId] ??= []).add(p);
    }

    final activeTarget = active.fold<int>(0, (a, p) => a + p.targetWritings);
    final overallProgress = (active.isEmpty || activeTarget == 0)
        ? 0.0
        : (active.fold<int>(0, (a, p) => a + p.totalProgress) / activeTarget)
            .clamp(0.0, 1.0);
    final totalChants = programs.fold<int>(0, (a, p) => a + p.totalProgress);
    final daysActive = active.isEmpty
        ? 0
        : (active.map((p) => p.daysElapsed).reduce((a, b) => a + b) /
                  active.length)
              .round();

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final mottoText = active.isEmpty && completed.isNotEmpty
        ? context.l10n.allSadhanasComplete
        : active.isEmpty
            ? context.l10n.everyJourneyBegins
            : context.l10n.keepChanting;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 100 + 16, 16, bottomInset + 104),
      children: [
        // ── Stats card with ring ───────────────────────────────────────────
        _animated(
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7B2D00),
                  Color(0xFFBF5000),
                  Color(0xFFE8851A),
                  Color(0xFFCC6A00),
                ],
                stops: [0.0, 0.35, 0.70, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFBF5000),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: Color(0xFF7B2D00),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mottoText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // 2×2 KPI grid
                      Row(
                        children: [
                          _Kpi(label: 'Total Chants', value: IndianNumberFormat.compact(totalChants)),
                          const SizedBox(width: 24),
                          _Kpi(label: 'Sadhanas', value: '${active.length}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Kpi(label: 'Days Active', value: '$daysActive'),
                          const SizedBox(width: 24),
                          _Kpi(label: 'Completed', value: '${completed.length}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _OverallRing(progress: overallProgress),
              ],
            ),
          ),
          0,
        ),
        const SizedBox(height: 14),

        // ── Start a New Sadhana ────────────────────────────────────────────
        _animated(
          GestureDetector(
            onTap: () => context.push(KvlRoute.mantraSelection),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF16A34A), Color(0xFF0F7A36), Color(0xFF22C55E)],
                  stops: [0.0, 0.45, 1.0],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF16A34A),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Color(0x33000000),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start your Sadhana',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Begin your spiritual journey today',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Color(0x33000000),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 17),
                  ),
                ],
              ),
            ),
          ),
          1,
        ),
        const SizedBox(height: 10),

        // ── Global Sadhanas ────────────────────────────────────────────────
        _animated(
          GestureDetector(
            onTap: () => context.push(KvlRoute.globalSadhanaList),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF8F0), Color(0xFFFFEDD5)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE8851A).withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8851A).withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                      ),
                    ),
                    child: const Icon(Icons.public_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Global Sadhanas',
                          style: KvlText.ui(14, FontWeight.w700).copyWith(color: KvlColors.primaryDeep)),
                        Text('Join a worldwide community practice',
                          style: KvlText.caption(11).copyWith(color: KvlColors.inkSoft)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: KvlColors.primaryDeep),
                ],
              ),
            ),
          ),
          2,
        ),
        const SizedBox(height: 18),

        // ── Active Sadhanas header ─────────────────────────────────────────
        _animated(
          Row(
            children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: KvlColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text('Active Sadhanas', style: KvlText.title(16)),
            ],
          ),
          3,
        ),
        const SizedBox(height: 10),

        // ── Active program cards ───────────────────────────────────────────
        if (active.isEmpty && completed.isEmpty)
          _animated(
            KvlCard(
              child: Column(
                children: [
                  const Icon(Icons.menu_book_rounded, color: KvlColors.muted, size: 36),
                  const SizedBox(height: 8),
                  Text(context.l10n.noProgramsYet, style: KvlText.title(13)),
                  const SizedBox(height: 4),
                  Text(context.l10n.pickMantraAndTargetToStart,
                      textAlign: TextAlign.center, style: KvlText.caption(11.5)),
                ],
              ),
            ),
            4,
          )
        else if (active.isEmpty)
          _animated(
            KvlCard(
              child: Column(
                children: [
                  const Icon(Icons.check_circle_rounded, color: KvlColors.primary, size: 36),
                  const SizedBox(height: 8),
                  Text('No active Sadhanas', style: KvlText.title(13)),
                  const SizedBox(height: 4),
                  Text('Start a new one to keep your practice going.',
                      textAlign: TextAlign.center, style: KvlText.caption(11.5)),
                ],
              ),
            ),
            4,
          )
        else ...[
          for (var i = 0; i < active.length; i++) ...[
            _animated(_ProgramCard(program: active[i]), 4 + i),
            const SizedBox(height: 10),
          ],
        ],

        // ── Completed Sadhanas ─────────────────────────────────────────────
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 6),
          _animated(
            _ViewCompletedButton(
              count: completed.length,
              expanded: _showCompleted,
              onTap: () => setState(() => _showCompleted = !_showCompleted),
            ),
            4 + active.length,
          ),
          if (_showCompleted) ...[
            const SizedBox(height: 10),
            for (var i = 0; i < completed.length; i++) ...[
              _animated(_ProgramCard(program: completed[i]), 5 + active.length + i),
              const SizedBox(height: 10),
            ],
          ],
        ],

        // ── Bonus Chants ───────────────────────────────────────────────────
        if (bonusByMantra.isNotEmpty) ...[
          const SizedBox(height: 18),
          _animated(
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 18, color: KvlColors.primary),
                const SizedBox(width: 6),
                Text('Bonus Chants', style: KvlText.title(16)),
              ],
            ),
            5 + active.length,
          ),
          const SizedBox(height: 10),
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
            const SizedBox(height: 10),
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
    final dedication = ref.watch(_dedicationProvider(program.id)).value;

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
                if (dedication != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded, size: 11, color: Color(0xFFE57373)),
                      const SizedBox(width: 3),
                      Text(
                        'Dedicated to $dedication',
                        style: KvlText.muted(11).copyWith(
                          color: KvlColors.primaryDeep,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
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
  const _Kpi({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)),
      ],
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
        width: 108,
        height: 108,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(108, 108),
              painter: _RingPainter(progress: value),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text('Progress',
                    style: TextStyle(color: Colors.white70, fontSize: 10)),
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
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
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
    final dedication = ref.watch(_dedicationProvider(program.id)).value;

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
                if (dedication != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded, size: 11, color: Color(0xFFE57373)),
                      const SizedBox(width: 3),
                      Text(
                        'Dedicated to $dedication',
                        style: KvlText.muted(11).copyWith(
                          color: KvlColors.primaryDeep,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
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
