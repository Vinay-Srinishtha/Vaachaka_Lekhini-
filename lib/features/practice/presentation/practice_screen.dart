import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import 'counter_screen.dart';

/// Default landing for the Practice bottom tab. If the user has an active
/// program, we render its counter directly; otherwise we show an empty
/// state inviting them to create one.
class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(mostRecentProgramProvider);

    return recent.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e', style: KvlText.body())),
      data: (program) {
        if (program == null) return const _EmptyPractice();
        return CounterScreen(programId: program.id);
      },
    );
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
            const Icon(Icons.self_improvement_rounded, color: KvlColors.muted, size: 56),
            const SizedBox(height: KvlSpacing.sm),
            Text('No active practice yet', style: KvlText.title(15)),
            const SizedBox(height: 4),
            Text(
              'Pick a mantra and set a target to begin chanting or writing.',
              textAlign: TextAlign.center,
              style: KvlText.caption(11.5),
            ),
            const SizedBox(height: KvlSpacing.md),
            KvlButton(
              label: 'Choose a Mantra',
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
