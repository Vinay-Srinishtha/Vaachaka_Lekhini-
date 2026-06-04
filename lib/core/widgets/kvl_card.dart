import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';

enum KvlCardVariant { plain, warm, soft, flat }

class KvlCard extends StatelessWidget {
  const KvlCard({
    super.key,
    required this.child,
    this.variant = KvlCardVariant.plain,
    this.padding = KvlSpacing.cardInset,
    this.onTap,
    this.border,
    this.gradient,
  });

  final Widget child;
  final KvlCardVariant variant;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final base = switch (variant) {
      KvlCardVariant.plain => KvlColors.surface,
      KvlCardVariant.warm => KvlColors.surfaceWarm,
      KvlCardVariant.soft => KvlColors.primaryGhost,
      KvlCardVariant.flat => KvlColors.surface,
    };
    final defaultBorderColor = switch (variant) {
      KvlCardVariant.soft => KvlColors.primarySoft,
      _ => KvlColors.border,
    };
    final shadow = variant == KvlCardVariant.flat ? null : KvlShadows.card;

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: gradient == null ? base : null,
        gradient: gradient,
        borderRadius: KvlRadius.brLG,
        border: border ?? Border.all(color: defaultBorderColor, width: 1),
        boxShadow: shadow,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return container;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: KvlRadius.brLG,
        child: container,
      ),
    );
  }
}
