import 'package:flutter/material.dart';

import '../navigation/back_navigation.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Top bar matching the design language in `docs/MOCKUPS.html`:
/// back arrow (or null) on the left, centred title, optional trailing widget on the right.
class KvlTopBar extends StatelessWidget implements PreferredSizeWidget {
  const KvlTopBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onBack,
    this.showBack = true,
    this.topGapColor,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;
  final Color? topGapColor;

  @override
  Size get preferredSize => const Size.fromHeight(84);

  @override
  Widget build(BuildContext context) {
    final back =
        leading ??
        (!showBack
            ? const SizedBox(width: 36)
            : _CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack ?? () => context.popOrGo(Navigator.defaultRouteName),
              ));

    final topGap = MediaQuery.viewPaddingOf(context).top.clamp(36.0, 48.0);
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: topGap + 48,
        child: Column(
          children: [
            ColoredBox(
              color: topGapColor ?? Colors.transparent,
              child: SizedBox(height: topGap),
            ),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.lg),
              decoration: BoxDecoration(
                color: KvlColors.bg.withValues(alpha: .6),
                border: Border(
                  bottom: BorderSide(
                    color: KvlColors.rule.withValues(alpha: .55),
                  ),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Title — always screen-centred regardless of leading/trailing widths.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 52),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: KvlText.ui(17, FontWeight.w700),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: KvlText.caption(
                              10,
                            ).copyWith(color: KvlColors.primaryDeep),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Align(alignment: Alignment.centerLeft, child: back),
                  Align(
                    alignment: Alignment.centerRight,
                    child: trailing ?? const SizedBox(width: 36),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: KvlColors.surface,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: KvlColors.inkSoft),
      ),
    );
  }
}
