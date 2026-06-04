import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/shadows.dart';
import '../theme/spacing.dart';

enum KvlButtonVariant { primary, secondary, ghost, teal, danger, outlineDanger }

enum KvlButtonSize { regular, tiny }

class KvlButton extends StatelessWidget {
  const KvlButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = KvlButtonVariant.primary,
    this.size = KvlButtonSize.regular,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final KvlButtonVariant variant;
  final KvlButtonSize size;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final palette = _palette(variant);
    final isTiny = size == KvlButtonSize.tiny;
    final fontSize = isTiny ? 12.0 : 13.5;
    final padV = isTiny ? 8.0 : 12.0;
    final padH = isTiny ? 14.0 : 16.0;
    final radius = isTiny ? KvlRadius.sm : KvlRadius.md;

    final child = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
          decoration: BoxDecoration(
            color: disabled ? palette.bg.withValues(alpha: .55) : palette.bg,
            gradient: disabled ? null : palette.gradient,
            borderRadius: BorderRadius.all(Radius.circular(radius)),
            border: palette.border == null ? null : Border.all(color: palette.border!, width: 1.5),
            boxShadow: palette.shadow,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: palette.fg, size: fontSize + 4),
                KvlSpacing.gapSM,
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.fg,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }

  _Palette _palette(KvlButtonVariant v) => switch (v) {
        KvlButtonVariant.primary => _Palette(
            bg: KvlColors.primary,
            fg: Colors.white,
            gradient: KvlColors.primaryGradient,
            shadow: KvlShadows.primaryGlow,
          ),
        KvlButtonVariant.secondary => _Palette(
            bg: Colors.transparent,
            fg: KvlColors.primaryDeep,
            border: KvlColors.primary,
          ),
        KvlButtonVariant.ghost => _Palette(
            bg: KvlColors.primaryGhost,
            fg: KvlColors.primaryDeep,
          ),
        KvlButtonVariant.teal => _Palette(
            bg: KvlColors.accent,
            fg: Colors.white,
            gradient: KvlColors.tealGradient,
            shadow: KvlShadows.tealGlow,
          ),
        KvlButtonVariant.danger => _Palette(bg: KvlColors.danger, fg: Colors.white),
        KvlButtonVariant.outlineDanger => _Palette(
            bg: Colors.transparent,
            fg: KvlColors.danger,
            border: KvlColors.danger,
          ),
      };
}

class _Palette {
  const _Palette({required this.bg, required this.fg, this.gradient, this.border, this.shadow});
  final Color bg;
  final Color fg;
  final Gradient? gradient;
  final Color? border;
  final List<BoxShadow>? shadow;
}
