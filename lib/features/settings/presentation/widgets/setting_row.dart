import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: KvlColors.primaryGhost, borderRadius: KvlRadius.brSM),
              alignment: Alignment.center,
              child: Icon(icon, color: KvlColors.primaryDeep, size: 13),
            ),
            const SizedBox(width: KvlSpacing.sm),
            Expanded(child: Text(label, style: KvlText.ui(12))),
            if (value != null)
              Text(value!, style: KvlText.caption(11).copyWith(color: KvlColors.inkSoft)),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: KvlColors.muted, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: KvlSpacing.md, bottom: 4),
          child: Text(
            title,
            style: KvlText.muted(10).copyWith(fontWeight: FontWeight.w600, letterSpacing: .06 * 10),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: KvlColors.surface,
            borderRadius: KvlRadius.brLG,
            border: Border.all(color: KvlColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const Divider(height: 1, color: KvlColors.rule, indent: KvlSpacing.md, endIndent: KvlSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class KvlSwitch extends StatelessWidget {
  const KvlSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: KvlColors.primary,
    );
  }
}
