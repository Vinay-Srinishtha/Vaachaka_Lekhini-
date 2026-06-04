import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../programs/domain/program.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider).value;
    final programsAsync = ref.watch(programsForActiveProfileProvider);
    final programs = programsAsync.value ?? const <Program>[];
    final recent = programs.isEmpty ? null : programs.first;

    final greeting = profile == null ? 'Welcome' : 'Welcome, ${profile.name}!';
    final subline = programs.isEmpty
        ? 'Start your spiritual journey'
        : "You're doing great! ${programs.length} ${programs.length == 1 ? 'Program' : 'Programs'} Active";
    final points = ref.watch(rewardTotalProvider).value ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(KvlSpacing.lg, KvlSpacing.sm, KvlSpacing.lg, KvlSpacing.lg),
      children: [
        Text(greeting, style: KvlText.title(20)),
        const SizedBox(height: 4),
        Text(subline, style: KvlText.caption(12)),
        const SizedBox(height: KvlSpacing.md),

        _RewardPointsTile(points: points),
        const SizedBox(height: KvlSpacing.md),

        if (recent != null) _DailyReminder(program: recent),
        if (recent != null) const SizedBox(height: KvlSpacing.md),

        _HeroQuote(),
        const SizedBox(height: KvlSpacing.md),

        KvlButton(
          label: recent == null ? 'Quick Start Practice' : 'Continue Practice',
          icon: Icons.play_arrow_rounded,
          onPressed: () {
            if (recent != null) {
              context.push('${KvlRoute.practice}/${recent.id}');
            } else {
              context.push(KvlRoute.quickStart);
            }
          },
        ),
        const SizedBox(height: KvlSpacing.sm),
        KvlButton(
          variant: KvlButtonVariant.secondary,
          label: programs.isEmpty ? 'Browse Mantras' : 'Select from your Programs',
          onPressed: () => context.go(programs.isEmpty ? KvlRoute.mantraSelection : KvlRoute.programs),
        ),
        const SizedBox(height: KvlSpacing.sm),
        KvlButton(
          variant: KvlButtonVariant.ghost,
          label: 'Create a New Program',
          icon: Icons.add,
          onPressed: () => context.push(KvlRoute.mantraSelection),
        ),
      ],
    );
  }
}

class _RewardPointsTile extends StatelessWidget {
  const _RewardPointsTile({required this.points});
  final int points;
  @override
  Widget build(BuildContext context) {
    return KvlCard(
      padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md, vertical: KvlSpacing.sm),
      onTap: () => GoRouter.of(context).push(KvlRoute.rewardHistory),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: KvlColors.gold, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: KvlSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: KvlText.body(11.5),
                children: [
                  const TextSpan(text: 'Total Reward Points: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: IndianNumberFormat.format(points)),
                ],
              ),
            ),
          ),
          Text('Go to Store ›',
              style: KvlText.caption(10).copyWith(color: KvlColors.primaryDeep, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DailyReminder extends ConsumerWidget {
  const _DailyReminder({required this.program});
  final Program program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mantra = ref.watch(mantraByIdProvider(program.mantraId));
    return KvlCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [KvlColors.primarySoft, KvlColors.primaryGhost],
      ),
      border: Border.all(color: KvlColors.primarySoft),
      onTap: () => context.push('${KvlRoute.practice}/${program.id}'),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.notifications_active_rounded, color: KvlColors.primaryDeep, size: 18),
          ),
          const SizedBox(width: KvlSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAILY PRACTICE REMINDER',
                    style: KvlText.caption(9.5)
                        .copyWith(color: KvlColors.primaryDeep, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                Text(mantra?.name.roman ?? program.mantraId,
                    style: KvlText.ui(12, FontWeight.w600)),
                Text(
                  'Day ${program.daysElapsed} of ${program.targetDays}',
                  style: KvlText.caption(10.5),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: KvlColors.primaryDeep),
        ],
      ),
    );
  }
}

class _HeroQuote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return KvlCard(
      variant: KvlCardVariant.warm,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: KvlRadius.brLG,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE0985B), Color(0xFFC97328), Color(0xFF8a4814)],
                  ),
                ),
                child: Center(
                  child: Text('ॐ',
                      style: KvlText.mantraDevanagari(72).copyWith(color: Colors.white.withValues(alpha: .7))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(KvlSpacing.md, KvlSpacing.sm, KvlSpacing.md, KvlSpacing.sm),
              child: Column(
                children: [
                  Text(
                    '"దుష్టులను క్షమించడం ధర్మం కాదు."',
                    textAlign: TextAlign.center,
                    style: KvlText.mantraTelugu(13).copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text('— Ramayana', style: KvlText.muted(10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
