import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

enum KvlChipVariant { primary, teal, green, gold, neutral }

class KvlChip extends StatelessWidget {
  const KvlChip({super.key, required this.label, this.variant = KvlChipVariant.primary, this.selected = false, this.onTap});

  final String label;
  final KvlChipVariant variant;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch ((variant, selected)) {
      (KvlChipVariant.primary, true) => (KvlColors.primary, Colors.white),
      (KvlChipVariant.primary, false) => (KvlColors.primarySoft, KvlColors.primaryDeep),
      (KvlChipVariant.teal, _) => (KvlColors.accentSoft, KvlColors.accent),
      (KvlChipVariant.green, _) => (KvlColors.successSoft, KvlColors.success),
      (KvlChipVariant.gold, _) => (const Color(0xFFFBE9A8), const Color(0xFF8A6900)),
      (KvlChipVariant.neutral, _) => (KvlColors.surface, KvlColors.inkSoft),
    };

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: KvlRadius.brPill,
        border: variant == KvlChipVariant.neutral ? Border.all(color: KvlColors.border) : null,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg),
      ),
    );

    if (onTap == null) return chip;
    return InkWell(onTap: onTap, borderRadius: KvlRadius.brPill, child: chip);
  }
}
