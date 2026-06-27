import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Animated expandable settings section with a tappable header.
class ExpandableSettingsSection extends StatefulWidget {
  const ExpandableSettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<ExpandableSettingsSection> createState() =>
      _ExpandableSettingsSectionState();
}

class _ExpandableSettingsSectionState extends State<ExpandableSettingsSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _ctrl;
  late final Animation<double> _rotate;
  late final Animation<double> _expand;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: _expanded ? 1.0 : 0.0,
    );
    _rotate = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _expand = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header — tappable, always visible
        GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(top: KvlSpacing.md, bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: KvlText.muted(10).copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: .06 * 10,
                    ),
                  ),
                ),
                RotationTransition(
                  turns: _rotate,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: KvlColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Animated body
        SizeTransition(
          sizeFactor: _expand,
          axisAlignment: -1,
          child: Container(
            decoration: BoxDecoration(
              color: KvlColors.surface,
              borderRadius: KvlRadius.brLG,
              border: Border.all(color: KvlColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < widget.children.length; i++) ...[
                  widget.children[i],
                  if (i != widget.children.length - 1)
                    const Divider(
                      height: 1,
                      color: KvlColors.rule,
                      indent: KvlSpacing.md,
                      endIndent: KvlSpacing.md,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final iconColor = disabled ? KvlColors.muted : KvlColors.primaryDeep;
    final iconBg = disabled ? KvlColors.border : KvlColors.primaryGhost;
    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: iconBg, borderRadius: KvlRadius.brSM),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 13),
              ),
              const SizedBox(width: KvlSpacing.sm),
              Expanded(child: Text(label, style: KvlText.ui(12))),
              if (value != null)
                Text(value!, style: KvlText.caption(11).copyWith(color: KvlColors.inkSoft)),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
              if (onTap != null && !disabled) ...[
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: KvlColors.muted, size: 18),
              ],
            ],
          ),
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
