import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/storage/repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/store_item.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  StoreCategory? _filter;
  String _query = '';

  Future<void> _redeem(StoreItem item) async {
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null) return;
    final result = await ref.read(rewardRepositoryProvider).spend(
          profileId: profile.id,
          amount: item.pricePoints,
          source: 'Store: ${item.title}',
        );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Ok():
        messenger.showSnackBar(SnackBar(content: Text('Redeemed ${item.title}')));
      case Err(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(rewardTotalProvider);
    final points = pointsAsync.value ?? 0;
    final items = kStoreSeed
        .where((i) => _filter == null || i.category == _filter)
        .where((i) => _query.isEmpty || i.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(KvlSpacing.lg, KvlSpacing.sm, KvlSpacing.lg, KvlSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(child: Text('Reward Store', style: KvlText.title(17))),
            GestureDetector(
              onTap: () => context.push(KvlRoute.rewardHistory),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('★ ${IndianNumberFormat.format(points)}',
                      style: KvlText.ui(12, FontWeight.w700).copyWith(color: KvlColors.gold)),
                  Text('See History',
                      style: KvlText.caption(9.5).copyWith(color: KvlColors.primaryDeep, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: KvlSpacing.md),
        _PromoBanner(),
        const SizedBox(height: KvlSpacing.md),
        KvlInput(
          hint: 'Search for rewards…',
          prefix: const Icon(Icons.search_rounded, size: 18, color: KvlColors.muted),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: KvlSpacing.sm),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _SegmentChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
              for (final c in StoreCategory.values) ...[
                const SizedBox(width: 8),
                _SegmentChip(
                  label: c.label,
                  selected: _filter == c,
                  onTap: () => setState(() => _filter = c),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: KvlSpacing.md),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.62,
          children: [for (final i in items) _StoreCard(item: i, points: points, onRedeem: () => _redeem(i))],
        ),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(KvlSpacing.lg),
            child: Center(child: Text('No rewards match your search', style: KvlText.muted(12))),
          ),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: KvlRadius.brLG,
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7C9BB8), Color(0xFF3F5B7E)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(KvlSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                KvlChip(label: 'SPECIAL OFFER', variant: KvlChipVariant.gold),
                const SizedBox(height: 4),
                Text('Guided Meditation Series',
                    style: KvlText.title(15).copyWith(color: Colors.white)),
                Text('Unlock peace with our new 7-day series',
                    style: KvlText.caption(10.5).copyWith(color: Colors.white.withValues(alpha: .92))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded-rectangle segment button — same style we use everywhere else
/// for selectable filters / tabs. (KvlChip stays a pill for read-only tags.)
class _SegmentChip extends StatelessWidget {
  const _SegmentChip({required this.label, required this.selected, required this.onTap});
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
          border: Border.all(color: selected ? KvlColors.primary : KvlColors.border, width: 1),
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

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.item, required this.points, required this.onRedeem});
  final StoreItem item;
  final int points;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final canAfford = points >= item.pricePoints;
    return Container(
      decoration: BoxDecoration(
        color: KvlColors.surface,
        borderRadius: KvlRadius.brLG,
        border: Border.all(color: KvlColors.border),
      ),
      child: ClipRRect(
        borderRadius: KvlRadius.brLG,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(item.background.first), Color(item.background.last)],
                  ),
                ),
                child: Center(
                  child: Text(item.glyph, style: const TextStyle(fontSize: 36)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(KvlSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(item.title,
                        style: KvlText.ui(12, FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('★ ${IndianNumberFormat.format(item.pricePoints)} Points',
                        style: KvlText.caption(10.5).copyWith(color: KvlColors.gold, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    KvlButton(
                      label: canAfford ? 'Redeem' : 'Not enough',
                      variant: canAfford ? KvlButtonVariant.primary : KvlButtonVariant.secondary,
                      onPressed: canAfford ? onRedeem : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
