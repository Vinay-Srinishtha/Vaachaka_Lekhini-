import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

class KvlNavItem {
  const KvlNavItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

const kvlNavItems = <KvlNavItem>[
  KvlNavItem(label: 'Home', icon: Icons.home_outlined),
  KvlNavItem(label: 'Programs', icon: Icons.dashboard_outlined),
  KvlNavItem(label: 'Practice', icon: Icons.edit_outlined),
  KvlNavItem(label: 'Community', icon: Icons.groups_outlined),
  KvlNavItem(label: 'Store', icon: Icons.shopping_bag_outlined),
];

class KvlBottomNav extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Material(
      color: KvlColors.surface,
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: KvlColors.rule, width: 1)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                for (int i = 0; i < kvlNavItems.length; i++)
                  if (!hiddenIndices.contains(i))
                    Expanded(child: _Tab(item: kvlNavItems[i], active: i == currentIndex, onTap: () => onTap(i))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap});
  final KvlNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? KvlColors.primary : KvlColors.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: KvlRadius.brSM,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(item.label, style: TextStyle(fontSize: 10.5, color: color, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
