import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/providers.dart';
import '../../../l10n/l10n.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/reward_event.dart';

class RewardHistoryScreen extends ConsumerStatefulWidget {
  const RewardHistoryScreen({super.key});

  @override
  ConsumerState<RewardHistoryScreen> createState() => _RewardHistoryScreenState();
}

class _RewardHistoryScreenState extends ConsumerState<RewardHistoryScreen> {
  RewardKind? _filter;

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(rewardTotalProvider);
    final points = pointsAsync.value ?? 0;
    final profile = ref.watch(activeProfileProvider).value;
    final historyStream = profile == null
        ? const Stream<List<RewardEvent>>.empty()
        : ref.watch(rewardRepositoryProvider).watchHistory(profile.id, filter: _filter);

    return KvlScaffold(
      title: context.l10n.rewardPointsHistory,
      scrollable: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KvlCard(
            padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md, vertical: KvlSpacing.md),
            child: Column(
              children: [
                Text(context.l10n.yourTotalPoints, style: KvlText.caption(11.5)),
                const SizedBox(height: 4),
                Text(
                  IndianNumberFormat.format(points),
                  style: KvlText.bigNumber(34).copyWith(color: KvlColors.gold),
                ),
                const SizedBox(height: KvlSpacing.sm),
                KvlButton(
                  size: KvlButtonSize.tiny,
                  expand: false,
                  label: context.l10n.visitRewardStore,
                  onPressed: () => context.go(KvlRoute.store),
                ),
              ],
            ),
          ),
          const SizedBox(height: KvlSpacing.md),
          Text(context.l10n.pointsHistory, style: KvlText.title(13)),
          const SizedBox(height: KvlSpacing.sm),
          _FilterRow(filter: _filter, onChanged: (k) => setState(() => _filter = k)),
          const SizedBox(height: KvlSpacing.sm),
          Expanded(
            child: StreamBuilder<List<RewardEvent>>(
              stream: historyStream,
              builder: (_, snap) {
                final list = snap.data ?? const <RewardEvent>[];
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(KvlSpacing.lg),
                      child: Text(
                        context.l10n.noRewardActivity,
                        textAlign: TextAlign.center,
                        style: KvlText.muted(12),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: KvlSpacing.sm),
                  itemBuilder: (_, i) => _Row(event: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.filter, required this.onChanged});
  final RewardKind? filter;
  final ValueChanged<RewardKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pill(label: context.l10n.filterAll, selected: filter == null, onTap: () => onChanged(null)),
        const SizedBox(width: 6),
        _Pill(label: context.l10n.filterEarned, selected: filter == RewardKind.earn, onTap: () => onChanged(RewardKind.earn)),
        const SizedBox(width: 6),
        _Pill(label: context.l10n.filterSpent, selected: filter == RewardKind.spend, onTap: () => onChanged(RewardKind.spend)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: KvlRadius.brMD,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? KvlColors.primary : KvlColors.surface,
          border: Border.all(color: selected ? KvlColors.primary : KvlColors.border),
          borderRadius: KvlRadius.brMD,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : KvlColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.event});
  final RewardEvent event;

  @override
  Widget build(BuildContext context) {
    final isEarn = event.kind == RewardKind.earn;
    return KvlCard(
      padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(event.source, style: KvlText.ui(12, FontWeight.w600)),
                Text(DateFormat.yMMMd().format(event.occurredAt), style: KvlText.muted(10)),
              ],
            ),
          ),
          Text(
            (isEarn ? '+' : '−') + IndianNumberFormat.format(event.amount),
            style: KvlText.ui(13, FontWeight.w700).copyWith(
              color: isEarn ? KvlColors.success : KvlColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
