import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../l10n/l10n.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../enrolment/voice/domain/voice_enrolment.dart';

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
  ConsumerState<SetTargetDaysScreen> createState() =>
      _SetTargetDaysScreenState();
}

class _SetTargetDaysScreenState extends ConsumerState<SetTargetDaysScreen> {
  static const _minDays = 1;
  static const _defaultDays = 180;
  static const _maxSliderDays = 2000;

  static const _presets = [
    (100, 'Fastest', KvlChipVariant.primary),
    (180, 'Balanced', KvlChipVariant.primary),
    (365, 'Gentle', KvlChipVariant.teal),
    (500, 'Sustainable', KvlChipVariant.green),
  ];

  late int _days = _normalizeDays(widget.daysHint);
  bool _busy = false;

  static int _normalizeDays(int? days) {
    final value = days ?? _defaultDays;
    return value < _minDays ? _minDays : value;
  }

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
    final enrolment = await ref
        .read(voiceEnrolmentRepositoryProvider)
        .get(profile.id, widget.mantraId);
    if (!mounted) return;
    if (enrolment == null || !enrolment.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          backgroundColor: KvlColors.primaryDeep,
          content: Text(
            'Complete voice training (${VoiceEnrolment.requiredSamples}/${VoiceEnrolment.requiredSamples}) before creating a voice program.',
            style: KvlText.caption(12).copyWith(color: Colors.white),
          ),
        ),
      );
      context.push('${KvlRoute.voiceTraining}/${widget.mantraId}');
      return;
    }
    setState(() => _busy = true);
    await ref
        .read(programRepositoryProvider)
        .create(
          memberId: profile.id,
          mantraId: widget.mantraId,
          targetWritings: widget.writings,
          targetDays: _days,
        );
    if (!mounted) return;
    context.go(KvlRoute.programs);
  }

  @override
  Widget build(BuildContext context) {
    final sliderMax = _days > _maxSliderDays
        ? _days.toDouble()
        : _maxSliderDays.toDouble();
    return KvlScaffold(
      title: context.l10n.setYourPracticeTarget,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.md),
          Text(
            context.l10n.chooseDaysSpread(
              IndianNumberFormat.format(widget.writings),
            ),
            textAlign: TextAlign.center,
            style: KvlText.caption(11.5).copyWith(height: 1.5),
          ),
          const SizedBox(height: KvlSpacing.lg),
          for (final (days, labelKey, chipVariant) in _presets) ...[
            _DaysCard(
              days: days,
              label: labelKey == 'Fastest'
                  ? context.l10n.presetFastest
                  : labelKey == 'Balanced'
                  ? context.l10n.presetBalanced
                  : labelKey == 'Gentle'
                  ? context.l10n.presetGentle
                  : context.l10n.presetSustainable,
              chipVariant: chipVariant,
              selected: _days == days,
              subline: _pace(days),
              onTap: () => setState(() => _days = days),
            ),
            const SizedBox(height: KvlSpacing.sm),
          ],
          const SizedBox(height: KvlSpacing.sm),
          KvlCard(
            variant: _presets.any((p) => p.$1 == _days)
                ? KvlCardVariant.plain
                : KvlCardVariant.soft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    context.l10n.setCustomDuration,
                    style: KvlText.ui(13, FontWeight.w600),
                  ),
                ),
                const SizedBox(height: KvlSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.durationLabel,
                        style: KvlText.caption(11.5),
                      ),
                    ),
                    Text(
                      context.l10n.daysValue(_days),
                      style: KvlText.ui(13, FontWeight.w600),
                    ),
                  ],
                ),
                Slider(
                  value: _days.clamp(_minDays, sliderMax.toInt()).toDouble(),
                  min: _minDays.toDouble(),
                  max: sliderMax,
                  activeColor: KvlColors.primary,
                  inactiveColor: KvlColors.primarySoft,
                  onChanged: (v) => setState(
                    () => _days = v.round().clamp(_minDays, sliderMax.toInt()),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(KvlSpacing.sm),
                  decoration: BoxDecoration(
                    color: KvlColors.primaryGhost,
                    borderRadius: KvlRadius.brSM,
                  ),
                  child: Center(
                    child: Text(
                      context.l10n.thisMeansPace(_pace(_days)),
                      style: KvlText.caption(11).copyWith(
                        color: KvlColors.primaryDeep,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KvlSpacing.lg),
          KvlButton(
            label: _busy
                ? context.l10n.creatingButton
                : context.l10n.confirmAndBegin,
            onPressed: _busy ? null : _confirm,
          ),
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
      border: selected
          ? Border.all(color: KvlColors.primary, width: 1.5)
          : null,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.daysValue(days),
                  style: KvlText.ui(13, FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subline,
                  style: KvlText.caption(10.5).copyWith(height: 1.3),
                ),
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
