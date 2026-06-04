import 'package:flutter/material.dart';

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
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final back = !showBack
        ? const SizedBox(width: 36)
        : (leading ??
            _CircleIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ));

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(KvlSpacing.lg, KvlSpacing.sm, KvlSpacing.lg, KvlSpacing.sm),
        child: Row(
          children: [
            back,
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: KvlText.ui(15, FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: KvlText.caption(10).copyWith(color: KvlColors.primaryDeep),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            trailing ?? const SizedBox(width: 36),
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
        decoration: const BoxDecoration(color: KvlColors.surface, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: KvlColors.inkSoft),
      ),
    );
  }
}
