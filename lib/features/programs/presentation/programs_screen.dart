import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/i18n/language_options.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/program.dart';

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

class _Body extends ConsumerWidget {
  const _Body({required this.programs});
  final List<Program> programs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overallProgress = programs.isEmpty
        ? 0.0
        : programs.map((p) => p.progressFraction).reduce((a, b) => a + b) /
              programs.length;
    final totalChants = programs.fold<int>(0, (a, p) => a + p.totalProgress);
    final daysAvg = programs.isEmpty
        ? 0
        : (programs.map((p) => p.daysElapsed).reduce((a, b) => a + b) /
                  programs.length)
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
                programs.isEmpty
                    ? 'Every journey begins with a single step.'
                    : '"Every chant is a step closer to the divine. Keep going!"',
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
                    label: 'Total Chants',
                    value: IndianNumberFormat.compact(totalChants),
                    onDark: true,
                  ),
                  _Kpi(
                    label: 'Complete',
                    value: '${(overallProgress * 100).round()}%',
                    onDark: true,
                  ),
                  _Kpi(
                    label: 'Days Practising',
                    value: '$daysAvg',
                    onDark: true,
                  ),
                  _Kpi(
                    label: 'Programs',
                    value: '${programs.length}',
                    onDark: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: KvlSpacing.md),
        Center(child: _OverallRing(progress: overallProgress)),
        const SizedBox(height: KvlSpacing.md),
        KvlButton(
          label: 'Create New Program',
          icon: Icons.add,
          onPressed: () => context.push(KvlRoute.mantraSelection),
        ),
        const SizedBox(height: KvlSpacing.md),
        Text('My Recitation Programs', style: KvlText.title(16)),
        const SizedBox(height: KvlSpacing.sm),
        if (programs.isEmpty)
          KvlCard(
            child: Column(
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: KvlColors.muted,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text('No programs yet', style: KvlText.title(13)),
                const SizedBox(height: 4),
                Text(
                  'Pick a mantra and set a target to start your first program.',
                  textAlign: TextAlign.center,
                  style: KvlText.caption(11.5),
                ),
              ],
            ),
          )
        else
          for (final p in programs) ...[
            _ProgramCard(program: p),
            const SizedBox(height: KvlSpacing.sm),
          ],
      ],
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
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(130, 130),
            painter: _RingPainter(progress: progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: KvlText.bigNumber(20),
              ),
              Text('Overall Progress', style: KvlText.muted(9.5)),
            ],
          ),
        ],
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
    final pct = (program.progressFraction * 100).round();
    final complete = program.status == ProgramStatus.completed;
    return KvlCard(
      onTap: () => context.push('${KvlRoute.dailyProgress}/${program.id}'),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(44, 44),
                  painter: _RingPainter(progress: program.progressFraction),
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KvlSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: KvlText.bodyByScript(
                    script,
                    15,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  complete
                      ? '${IndianNumberFormat.format(program.totalProgress)} / ${IndianNumberFormat.format(program.targetWritings)} · Completed ✓'
                      : '${IndianNumberFormat.format(program.totalProgress)} / ${IndianNumberFormat.format(program.targetWritings)}',
                  style: KvlText.muted(12).copyWith(
                    color: complete ? KvlColors.success : KvlColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: KvlColors.inkSoft),
        ],
      ),
    );
  }
}
