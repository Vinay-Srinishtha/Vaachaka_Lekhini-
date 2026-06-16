import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';

class KvlNavItem {
  const KvlNavItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

/// Icons are stable; labels are resolved from l10n at build time.
const _navIcons = <IconData>[
  Icons.home_outlined,
  Icons.dashboard_outlined,
  Icons.edit_note_rounded,
  Icons.groups_outlined,
  Icons.shopping_bag_outlined,
];

const _practiceIndex = 2;

class KvlBottomNav extends StatelessWidget {
  const KvlBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.hiddenIndices = const {},
    this.storePoints,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Indices in [kvlNavItems] that should not render a button. The routes
  /// themselves stay registered so deep links don't break — only the
  /// visible tab disappears (driven by remote config feature flags).
  final Set<int> hiddenIndices;

  /// When provided, shown as a live ★ badge on the Store tab (index 4).
  final int? storePoints;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navItems = <KvlNavItem>[
      KvlNavItem(label: l10n.navHome, icon: _navIcons[0]),
      KvlNavItem(label: l10n.navPrograms, icon: _navIcons[1]),
      KvlNavItem(label: l10n.navPractice, icon: _navIcons[2]),
      KvlNavItem(label: l10n.navCommunity, icon: _navIcons[3]),
      KvlNavItem(label: l10n.navStore, icon: _navIcons[4]),
    ];
    final practiceHidden = hiddenIndices.contains(_practiceIndex);

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
                      practiceHidden ? 2 : 5,
                      KvlSpacing.xs,
                      1,
                    ),
                    child: Row(
                      children: [
                        for (int i = 0; i < navItems.length; i++)
                          if (!hiddenIndices.contains(i))
                            Expanded(
                              child: i == _practiceIndex
                                  ? const SizedBox.shrink()
                                  : _Tab(
                                      item: navItems[i],
                                      active: i == currentIndex,
                                      onTap: () => onTap(i),
                                      badge: i == 4 ? storePoints : null,
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
                    item: navItems[_practiceIndex],
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
  const _Tab({
    required this.item,
    required this.active,
    required this.onTap,
    this.badge,
  });
  final KvlNavItem item;
  final bool active;
  final VoidCallback onTap;

  /// When non-null, shows a live ★ N badge below the tab icon.
  final int? badge;

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
                if (badge != null && badge! > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6A817),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatBadge(badge!),
                        style: const TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
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
            if (badge != null && badge! > 0) ...[
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 8, color: Color(0xFFE6A817)),
                    const SizedBox(width: 1),
                    Text(
                      _formatBadge(badge!),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: Color(0xFFE6A817),
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatBadge(int n) {
    if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
