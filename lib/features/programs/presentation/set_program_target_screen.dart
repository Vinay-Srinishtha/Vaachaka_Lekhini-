import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/navigation/back_navigation.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../enrolment/voice/domain/voice_enrolment.dart';

class SetProgramTargetScreen extends ConsumerStatefulWidget {
  const SetProgramTargetScreen({super.key, required this.mantraId});
  final String mantraId;

  @override
  ConsumerState<SetProgramTargetScreen> createState() =>
      _SetProgramTargetScreenState();
}

class _SetProgramTargetScreenState
    extends ConsumerState<SetProgramTargetScreen> {
  // ── Writings ────────────────────────────────────────────────────────────────
  _WritingsPreset _writingsPreset = _WritingsPreset.crore;
  final _customWritingsCtrl = TextEditingController(text: '500000');

  // ── Days ────────────────────────────────────────────────────────────────────
  static const _minDays = 1;
  static const _maxSliderDays = 2000;
      (100, 'Fastest', KvlChipVariant.primary),
      (180, 'Balanced', KvlChipVariant.primary),
      (365, 'Gentle', KvlChipVariant.teal),
      (500, 'Sustainable', KvlChipVariant.green),
    ];

  int _days = 180;
  bool _busy = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _customWritingsCtrl.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([]);
    _customWritingsCtrl.removeListener(_rebuild);
    _customWritingsCtrl.dispose();
    super.dispose();
  }

  // ── Computed ─────────────────────────────────────────────────────────────────
  int get _writings {
    switch (_writingsPreset) {
      case _WritingsPreset.crore:
        return 10000000;
      case _WritingsPreset.million:
        return 1000000;
      case _WritingsPreset.custom:
        return int.tryParse(_customWritingsCtrl.text) ?? 0;
    }
  }

  String _pace(int days) {
    final w = _writings;
    if (w <= 0 || days <= 0) return '';
    final perDay = (w / days).ceil();
    final minutes = perDay / 60.0;
    final timeStr = minutes >= 60
        ? '≈ ${(minutes / 60).toStringAsFixed(1)} hrs/day'
        : '≈ ${minutes.toStringAsFixed(0)} min/day';
    return '~${IndianNumberFormat.format(perDay)} chants/day · $timeStr';
  }


  // ── Actions ───────────────────────────────────────────────────────────────────
  Future<void> _confirm() async {
    if (_writings <= 0 || _days <= 0 || _busy) return;
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null) return;

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
            'Complete voice training '
            '(${VoiceEnrolment.requiredSamples}/${VoiceEnrolment.requiredSamples}) '
            'before creating a voice program.',
            style: KvlText.caption(12).copyWith(color: Colors.white),
          ),
        ),
      );
      context.push('${KvlRoute.voiceTraining}/${widget.mantraId}');
      return;
    }

    setState(() => _busy = true);
    await ref.read(programRepositoryProvider).create(
          memberId: profile.id,
          mantraId: widget.mantraId,
          targetWritings: _writings,
          targetDays: _days,
        );
    if (!mounted) return;
    context.go(KvlRoute.programs);
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sliderMax =
        _days > _maxSliderDays ? _days.toDouble() : _maxSliderDays.toDouble();
    final pace = _pace(_days);
    final canConfirm = _writings > 0 && _days > 0 && !_busy;

    return KvlScaffold(
      title: context.l10n.setYourPracticeTarget,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.sm),

          // ── Section: Writings target ────────────────────────────────────────
          _SectionHeader(label: 'Total writings goal'),
          const SizedBox(height: KvlSpacing.sm),
          _WritingsCard(
            selected: _writingsPreset == _WritingsPreset.crore,
            onTap: () => setState(() => _writingsPreset = _WritingsPreset.crore),
            title: context.l10n.writingsTargetCrore,
            badge: context.l10n.mostPopularBadge,
          ),
          const SizedBox(height: KvlSpacing.xs),
          _WritingsCard(
            selected: _writingsPreset == _WritingsPreset.million,
            onTap: () =>
                setState(() => _writingsPreset = _WritingsPreset.million),
            title: context.l10n.writingsTargetMillion,
          ),
          const SizedBox(height: KvlSpacing.xs),
          // Custom writings input
          KvlCard(
            variant: _writingsPreset == _WritingsPreset.custom
                ? KvlCardVariant.soft
                : KvlCardVariant.plain,
            border: _writingsPreset == _WritingsPreset.custom
                ? Border.all(color: KvlColors.primary, width: 1.5)
                : null,
            onTap: () =>
                setState(() => _writingsPreset = _WritingsPreset.custom),
            child: Row(
              children: [
                _RadioDot(selected: _writingsPreset == _WritingsPreset.custom),
                const SizedBox(width: KvlSpacing.sm),
                Expanded(
                  child: _writingsPreset == _WritingsPreset.custom
                      ? KvlInput(
                          label: context.l10n.totalWritingsLabel,
                          hint: context.l10n.totalWritingsHint,
                          controller: _customWritingsCtrl,
                          keyboardType: TextInputType.number,
                        )
                      : Text(
                          context.l10n.setCustomTarget,
                          style: KvlText.ui(13, FontWeight.w600),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: KvlSpacing.lg),

          // ── Section: Duration ───────────────────────────────────────────────
          _SectionHeader(label: 'Spread over how many days?'),
          const SizedBox(height: KvlSpacing.sm),

          // Day preset chips
          Wrap(
            spacing: KvlSpacing.xs,
            runSpacing: KvlSpacing.xs,
            children: [
                GestureDetector(
                  onTap: () => setState(() => _days = days),
                  child: KvlChip(
                    label: '$days days · $label',
                    variant: _days == days
                        ? KvlChipVariant.gold
                        : chipVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: KvlSpacing.md),

          // Slider
          KvlCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Duration',
                        style: KvlText.caption(11.5),
                      ),
                    ),
                    Text(
                      context.l10n.daysValue(_days),
                      style: KvlText.ui(14, FontWeight.w700).copyWith(
                        color: KvlColors.primaryDeep,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _days
                      .clamp(_minDays, sliderMax.toInt())
                      .toDouble(),
                  min: _minDays.toDouble(),
                  max: sliderMax,
                  activeColor: KvlColors.primary,
                  inactiveColor: KvlColors.primarySoft,
                  onChanged: (v) => setState(
                    () => _days = v.round().clamp(_minDays, sliderMax.toInt()),
                  ),
                ),
              ],
            ),
          ),

          // ── Live pacing summary ─────────────────────────────────────────────
          if (pace.isNotEmpty) ...[
            const SizedBox(height: KvlSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KvlSpacing.md,
                vertical: KvlSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: KvlColors.primaryGhost,
                borderRadius: KvlRadius.brMD,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: KvlColors.primaryDeep,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      pace,
                      textAlign: TextAlign.center,
                      style: KvlText.caption(11.5).copyWith(
                        color: KvlColors.primaryDeep,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: KvlSpacing.lg),

          KvlButton(
            label: _busy
                ? context.l10n.creatingButton
                : context.l10n.confirmAndBegin,
            onPressed: canConfirm ? _confirm : null,
          ),
          const SizedBox(height: KvlSpacing.sm),
          Center(
            child: TextButton(
              onPressed: () => context
                  .popOrGo('${KvlRoute.handwritingSubmit}/${widget.mantraId}'),
              child: Text(
                context.l10n.cancelButton,
                style: KvlText.caption(12).copyWith(
                  color: KvlColors.primaryDeep,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Enums & helpers ────────────────────────────────────────────────────────────

enum _WritingsPreset { crore, million, custom }

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: KvlText.title(13));
  }
}

class _WritingsCard extends StatelessWidget {
  const _WritingsCard({
    required this.selected,
    required this.onTap,
    required this.title,
    this.badge,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      variant: selected ? KvlCardVariant.soft : KvlCardVariant.plain,
      border: selected ? Border.all(color: KvlColors.primary, width: 1.5) : null,
      padding: const EdgeInsets.symmetric(
        horizontal: KvlSpacing.md,
        vertical: KvlSpacing.md,
      ),
      onTap: onTap,
      child: Row(
        children: [
          _RadioDot(selected: selected),
          const SizedBox(width: KvlSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KvlText.ui(13, FontWeight.w600)),
                if (badge != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    badge!,
                    style: KvlText.caption(10.5).copyWith(
                      color: KvlColors.primaryDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? KvlColors.primary : Colors.transparent,
        border: Border.all(
          color: selected ? KvlColors.primary : KvlColors.border,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
          : null,
    );
  }
}
