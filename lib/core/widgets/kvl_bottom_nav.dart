import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';
import '../theme/text.dart';

class KvlNavItem {
  const KvlNavItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

const kvlNavItems = <KvlNavItem>[
  KvlNavItem(label: 'Home', icon: Icons.home_outlined),
  KvlNavItem(label: 'My Sadhanas', icon: Icons.dashboard_outlined),
  KvlNavItem(label: 'Practice', icon: Icons.edit_note_rounded),
  KvlNavItem(label: 'Community', icon: Icons.groups_outlined),
  KvlNavItem(label: 'Store', icon: Icons.shopping_bag_outlined),
];

const _practiceIndex = 2;
const _storeIndex = 4;

class KvlBottomNav extends ConsumerWidget {
  const KvlBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.hiddenIndices = const {},
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Indices in [kvlNavItems] that should not render a button. The routes
  /// themselves stay registered so deep links don't break — only the
  /// visible tab disappears (driven by remote config feature flags).
  final Set<int> hiddenIndices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final practiceHidden = hiddenIndices.contains(_practiceIndex);
    final pts = ref.watch(rewardTotalProvider).value ?? 0;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 2),
        child: SizedBox(
          height: practiceHidden ? 58 : 68,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(
                top: practiceHidden ? 0 : 9,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: KvlColors.surface,
                    border: Border(
                      top: BorderSide(color: KvlColors.rule, width: 1),
                    ),
                    boxShadow: KvlShadows.elevated,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      KvlSpacing.xs,
                      practiceHidden ? 2 : KvlSpacing.sm,
                      KvlSpacing.xs,
                      2,
                    ),
                    child: Row(
                      children: [
                        for (int i = 0; i < kvlNavItems.length; i++)
                          if (!hiddenIndices.contains(i))
                            Expanded(
                              child: i == _practiceIndex
                                  ? const SizedBox.shrink()
                                  : _Tab(
                                      item: kvlNavItems[i],
                                      active: i == currentIndex,
                                      onTap: () => onTap(i),
                                      pts: i == _storeIndex ? pts : null,
                                    ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!practiceHidden)
                Positioned(
                  top: 0,
                  child: _PracticeTab(
                    item: kvlNavItems[_practiceIndex],
                    active: currentIndex == _practiceIndex,
                    onTap: () => onTap(_practiceIndex),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeTab extends StatefulWidget {
  const _PracticeTab({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final KvlNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<_PracticeTab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? .94 : 1.0;
    final labelColor = widget.active
        ? KvlColors.primaryDeep
        : KvlColors.inkSoft;

    return Semantics(
      button: true,
      selected: widget.active,
      label: widget.item.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: KvlColors.primaryGradient,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .75),
                    width: 2,
                  ),
                  boxShadow: [
                    ...KvlShadows.primaryGlow,
                    BoxShadow(
                      color: KvlColors.primaryDeep.withValues(alpha: .25),
                      blurRadius: widget.active ? 12 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .22),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9,
                    color: labelColor,
                    fontWeight: widget.active
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap, this.pts});
  final KvlNavItem item;
  final bool active;
  final VoidCallback onTap;
  final int? pts;

  @override
  Widget build(BuildContext context) {
    final color = active ? KvlColors.primary : KvlColors.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: KvlRadius.brSM,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(item.icon, size: 18, color: color),
                if (pts != null)
                  Positioned(
                    top: -6,
                    right: -14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: KvlColors.gold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 8, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            '$pts',
                            style: KvlText.ui(8, FontWeight.w700).copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 9.2,
                  color: color,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
