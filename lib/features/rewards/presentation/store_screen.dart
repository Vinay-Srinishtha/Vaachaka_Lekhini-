import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/storage/repository.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../domain/store_item.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  String _query = '';

  Future<void> _redeem(StoreItem item) async {
    // Confirmation dialog before spending points
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _RedeemConfirmDialog(item: item),
    );
    if (confirmed != true || !mounted) return;

    final profile = ref.read(activeProfileProvider).value;
    if (profile == null) return;
    final result = await ref
        .read(rewardRepositoryProvider)
        .spend(
          memberId: profile.id,
          amount: item.pricePoints,
          source: 'Store: ${item.title}',
          storeItemId: item.id,
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        // Refetch store catalog so stock counts reflect the redemption.
        ref.invalidate(storeItemsProvider);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => _RedeemSuccessDialog(item: item),
        );
      case Err(:final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointsAsync = ref.watch(rewardTotalProvider);
    final points = pointsAsync.value ?? 0;
    final redeemed = ref.watch(redeemedItemIdsProvider).value ?? const <String>{};
    final storeAsync = ref.watch(storeItemsProvider);
    final allItems = storeAsync.value ?? const <StoreItem>[];
    final items = allItems
        .where(
          (i) =>
              _query.isEmpty ||
              i.title.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final topInset = MediaQuery.viewPaddingOf(context).top.clamp(36.0, 48.0);

    return RefreshIndicator(
      onRefresh: () => ref.read(syncEngineProvider).syncNow(),
      color: KvlColors.primary,
      child: ListView(
      padding: EdgeInsets.fromLTRB(
        KvlSpacing.lg,
        topInset + 88,
        KvlSpacing.lg,
        bottomInset + 104,
      ),
      children: [
        _PromoBanner(),
        const SizedBox(height: KvlSpacing.md),
        const _EarnGuide(),
        const SizedBox(height: KvlSpacing.md),
        KvlInput(
          hint: context.l10n.searchRewards,
          prefix: const Icon(
            Icons.search_rounded,
            size: 18,
            color: KvlColors.muted,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: KvlSpacing.md),
        if (storeAsync.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (storeAsync.hasError)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load store items.',
                    style: KvlText.muted(13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.invalidate(storeItemsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'No items in the store yet.',
                style: KvlText.muted(13),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          GridView.count(
            shrinkWrap: true,
            primary: false,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.62,
            children: [
              for (final i in items)
                _StoreCard(
                  item: i,
                  points: points,
                  isRedeemed: redeemed.contains(i.id),
                  onRedeem: () => _redeem(i),
                ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(KvlSpacing.lg),
              child: Center(
                child: Text(
                  context.l10n.noRewardsMatch,
                  style: KvlText.muted(12),
                ),
              ),
            ),
        ],
      ],
    ),  // ListView
    );  // RefreshIndicator
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// How to earn points — collapsible guide (mirrors profile screen's version)
// ─────────────────────────────────────────────────────────────────────────────

class _EarnGuide extends ConsumerStatefulWidget {
  const _EarnGuide();

  @override
  ConsumerState<_EarnGuide> createState() => _EarnGuideState();
}

class _EarnGuideState extends ConsumerState<_EarnGuide>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _sizeFactor;
  late final Animation<double> _iconTurn;

  static const _rules = [
    (icon: Icons.celebration_rounded,           label: 'Joining bonus',              pts: 100, note: 'One-time, on sign-up',   earnedKey: 'joining'),
    (icon: Icons.person_rounded,                label: 'Complete your profile',       pts: 50,  note: 'One-time bonus',         earnedKey: ''),
    (icon: Icons.auto_awesome_rounded,          label: 'Every 11 chants or writings', pts: 1,   note: 'Per 11 count batch',     earnedKey: ''),
    (icon: Icons.local_fire_department_rounded, label: '7-day continuous streak',     pts: 50,  note: 'Per week milestone',     earnedKey: ''),
    (icon: Icons.group_add_rounded,             label: 'Invite a friend',             pts: 50,  note: 'When they join',         earnedKey: ''),
    (icon: Icons.card_giftcard_rounded,         label: 'Join via referral link',      pts: 50,  note: 'Extra on sign-up',       earnedKey: ''),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _sizeFactor = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _iconTurn = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: KvlRadius.brLG,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KvlSpacing.md,
                vertical: KvlSpacing.md,
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard_rounded,
                      color: KvlColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'How to earn points',
                      style: KvlText.caption(12).copyWith(
                        fontWeight: FontWeight.w800,
                        color: KvlColors.inkSoft,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _iconTurn,
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: KvlColors.muted),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _sizeFactor,
            child: Column(
              children: [
                const Divider(height: 1, thickness: 0.5),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    KvlSpacing.md, KvlSpacing.xs, KvlSpacing.md, KvlSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      for (final r in _rules) ...[
                        _EarnRuleRow(
                          icon: r.icon,
                          label: r.label,
                          pts: r.pts,
                          note: r.note,
                          earned: r.earnedKey == 'joining',
                        ),
                        if (r != _rules.last)
                          const Divider(height: 1, thickness: 0.5),
                      ],
                    ],
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

class _EarnRuleRow extends StatelessWidget {
  const _EarnRuleRow({
    required this.icon,
    required this.label,
    required this.pts,
    required this.note,
    this.earned = false,
  });
  final IconData icon;
  final String label;
  final int pts;
  final String note;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KvlSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: earned ? const Color(0xFFE8F5E9) : KvlColors.primaryGhost,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: earned ? const Color(0xFF388E3C) : KvlColors.primary),
          ),
          const SizedBox(width: KvlSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: KvlText.ui(12, FontWeight.w600)),
                Text(note,
                    style: KvlText.caption(10.5)
                        .copyWith(color: KvlColors.muted)),
              ],
            ),
          ),
          earned
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF81C784), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded, size: 11, color: Color(0xFF388E3C)),
                      const SizedBox(width: 3),
                      Text(
                        'earned',
                        style: KvlText.ui(11, FontWeight.w700)
                            .copyWith(color: const Color(0xFF388E3C)),
                      ),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: KvlColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: KvlColors.gold.withValues(alpha: 0.35), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 10, color: KvlColors.gold),
                      const SizedBox(width: 2),
                      Text(
                        '+$pts',
                        style: KvlText.ui(11, FontWeight.w700)
                            .copyWith(color: KvlColors.gold),
                      ),
                    ],
                  ),
                ),
        ],
      ),
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
                KvlChip(
                  label: context.l10n.specialOffer,
                  variant: KvlChipVariant.gold,
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.guidedMeditationSeries,
                  style: KvlText.title(15).copyWith(color: Colors.white),
                ),
                Text(
                  context.l10n.unlockPeaceSeries,
                  style: KvlText.caption(
                    10.5,
                  ).copyWith(color: Colors.white.withValues(alpha: .92)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemPlaceholder extends StatelessWidget {
  const _ItemPlaceholder({required this.item});
  final StoreItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.item,
    required this.points,
    required this.isRedeemed,
    required this.onRedeem,
  });
  final StoreItem item;
  final int points;
  final bool isRedeemed;
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
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => _ItemPlaceholder(item: item),
                    )
                  : _ItemPlaceholder(item: item),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(KvlSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.title,
                      style: KvlText.ui(12, FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '★ ${IndianNumberFormat.format(item.pricePoints)} Points',
                      style: KvlText.caption(10.5).copyWith(
                        color: KvlColors.gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    _RedeemButton(
                      canAfford: canAfford && !isRedeemed,
                      isRedeemed: isRedeemed,
                      label: isRedeemed
                          ? 'Redeemed ✓'
                          : context.l10n.redeemButton,
                      onRedeem: isRedeemed ? null : onRedeem,
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

class _RedeemButton extends StatelessWidget {
  const _RedeemButton({
    required this.canAfford,
    required this.isRedeemed,
    required this.label,
    required this.onRedeem,
  });
  final bool canAfford;
  final bool isRedeemed;
  final String label;
  final VoidCallback? onRedeem;

  @override
  Widget build(BuildContext context) {
    if (isRedeemed) {
      return SizedBox(
        width: double.infinity,
        height: 36,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: KvlRadius.brMD,
            border: Border.all(color: const Color(0xFF81C784)),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF388E3C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      );
    }
    return Opacity(
      opacity: canAfford ? 1.0 : 0.38,
      child: SizedBox(
        width: double.infinity,
        height: 36,
        child: Material(
          color: KvlColors.primary,
          borderRadius: KvlRadius.brMD,
          child: InkWell(
            borderRadius: KvlRadius.brMD,
            onTap: canAfford ? onRedeem : null,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RedeemConfirmDialog extends StatelessWidget {
  const _RedeemConfirmDialog({required this.item});
  final StoreItem item;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: KvlRadius.brLG),
      backgroundColor: KvlColors.surface,
      title: Text('Redeem ${item.title}?', style: KvlText.title(16)),
      content: Text(
        'This will spend ★ ${IndianNumberFormat.format(item.pricePoints)} points from your balance.',
        style: KvlText.caption(13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Redeem',
            style: TextStyle(color: KvlColors.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _RedeemSuccessDialog extends StatelessWidget {
  const _RedeemSuccessDialog({required this.item});
  final StoreItem item;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: KvlRadius.brLG),
      backgroundColor: KvlColors.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: KvlSpacing.sm),
          Text(item.glyph, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: KvlSpacing.md),
          Text(
            'You have redeemed',
            style: KvlText.caption(13).copyWith(color: KvlColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            item.title,
            style: KvlText.title(17),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KvlSpacing.sm),
          Text(
            '★ ${IndianNumberFormat.format(item.pricePoints)} points spent',
            style: KvlText.caption(11.5).copyWith(
              color: KvlColors.gold,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KvlSpacing.lg),
          KvlButton(
            label: 'Close',
            variant: KvlButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: KvlSpacing.sm),
        ],
      ),
    );
  }
}
