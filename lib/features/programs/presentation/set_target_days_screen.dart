import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';

class SetTargetDaysScreen extends ConsumerStatefulWidget {
  const SetTargetDaysScreen({
    super.key,
    required this.mantraId,
    required this.writings,
    this.daysHint,
  });

  final String mantraId;
  final int writings;
  final int? daysHint;

  @override
  ConsumerState<SetTargetDaysScreen> createState() => _SetTargetDaysScreenState();
}

class _SetTargetDaysScreenState extends ConsumerState<SetTargetDaysScreen> {
  static const _presets = [
    (100, 'Fastest', KvlChipVariant.primary),
    (180, 'Balanced', KvlChipVariant.primary),
    (365, 'Gentle', KvlChipVariant.teal),
    (500, 'Sustainable', KvlChipVariant.green),
  ];

  late int _days = widget.daysHint ?? 180;
  bool _busy = false;

  String _pace(int days) {
    if (days <= 0) return '';
    final perDay = (widget.writings / days).ceil();
    final minutes = perDay / 60.0;
    final paceText = minutes >= 60
        ? '${(minutes / 60).toStringAsFixed(1)} hours/day'
        : '${minutes.toStringAsFixed(0)} minutes/day';
    return '~${IndianNumberFormat.format(perDay)} chants/day · ≈ $paceText';
  }

  Future<void> _confirm() async {
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null || _days <= 0 || widget.writings <= 0) return;
    setState(() => _busy = true);
    await ref.read(programRepositoryProvider).create(
          profileId: profile.id,
          mantraId: widget.mantraId,
          targetWritings: widget.writings,
          targetDays: _days,
        );
    if (!mounted) return;
    context.go(KvlRoute.programs);
  }

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: 'Set Your Practice Target',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.md),
          Text(
            'Choose how many days you want to spread ${IndianNumberFormat.format(widget.writings)} across.',
            textAlign: TextAlign.center,
            style: KvlText.caption(11.5).copyWith(height: 1.5),
          ),
          const SizedBox(height: KvlSpacing.lg),
          for (final (days, label, chipVariant) in _presets) ...[
            _DaysCard(
              days: days,
              label: label,
              chipVariant: chipVariant,
              selected: _days == days,
              subline: _pace(days),
              onTap: () => setState(() => _days = days),
            ),
            const SizedBox(height: KvlSpacing.sm),
          ],
          const SizedBox(height: KvlSpacing.sm),
          KvlCard(
            variant: _presets.any((p) => p.$1 == _days) ? KvlCardVariant.plain : KvlCardVariant.soft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Text('Set a Custom Duration', style: KvlText.ui(13, FontWeight.w600))),
                const SizedBox(height: KvlSpacing.sm),
                Row(
                  children: [
                    Expanded(child: Text('Duration', style: KvlText.caption(11.5))),
                    Text('$_days days', style: KvlText.ui(13, FontWeight.w600)),
                  ],
                ),
                Slider(
                  value: _days.clamp(30, 999).toDouble(),
                  min: 30,
                  max: 999,
                  divisions: 100,
                  activeColor: KvlColors.primary,
                  inactiveColor: KvlColors.primarySoft,
                  onChanged: (v) => setState(() => _days = v.round()),
                ),
                Container(
                  padding: const EdgeInsets.all(KvlSpacing.sm),
                  decoration: BoxDecoration(color: KvlColors.primaryGhost, borderRadius: KvlRadius.brSM),
                  child: Center(
                    child: Text(
                      'This means ${_pace(_days)}',
                      style: KvlText.caption(11).copyWith(color: KvlColors.primaryDeep, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KvlSpacing.lg),
          KvlButton(label: _busy ? 'Creating…' : 'Confirm & Begin', onPressed: _busy ? null : _confirm),
        ],
      ),
    );
  }
}

class _DaysCard extends StatelessWidget {
  const _DaysCard({
    required this.days,
    required this.label,
    required this.chipVariant,
    required this.selected,
    required this.subline,
    required this.onTap,
  });

  final int days;
  final String label;
  final KvlChipVariant chipVariant;
  final bool selected;
  final String subline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      variant: selected ? KvlCardVariant.soft : KvlCardVariant.plain,
      border: selected ? Border.all(color: KvlColors.primary, width: 1.5) : null,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$days Days', style: KvlText.ui(13, FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subline, style: KvlText.caption(10.5).copyWith(height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: KvlSpacing.sm),
          KvlChip(label: label, variant: chipVariant),
        ],
      ),
    );
  }
}
