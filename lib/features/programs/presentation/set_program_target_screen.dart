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
import '../../mantras/domain/mantra.dart';

class SetProgramTargetScreen extends ConsumerStatefulWidget {
  const SetProgramTargetScreen({super.key, required this.mantraId});
  final String mantraId;

  @override
  ConsumerState<SetProgramTargetScreen> createState() =>
      _SetProgramTargetScreenState();
}

// Fallback milestones used when the mantra has none configured in the admin.
const _defaultMilestones = [
  MantraMilestone(count: 108,   dayOptions: [1,  7,  21,  40]),
  MantraMilestone(count: 1008,  dayOptions: [7,  21, 40,  108]),
  MantraMilestone(count: 5116,  dayOptions: [21, 40, 108, 180]),
  MantraMilestone(count: 10116, dayOptions: [40, 108, 180, 365]),
];
const _dayOptionsFallback = [7, 21, 108, 365];

class _SetProgramTargetScreenState
    extends ConsumerState<SetProgramTargetScreen> {
  int? _selectedCount = 108; // null means custom
  final _customWritingsCtrl = TextEditingController(text: '108');

  // ── Days ────────────────────────────────────────────────────────────────────
  static const _maxSliderDays = 2000;
  // 24 hrs/day × 60 chants/min = 1440 chants max per day
  static const _chantsPerDay24h = 1440;

  int _days = 1;
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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _customWritingsCtrl.removeListener(_rebuild);
    _customWritingsCtrl.dispose();
    super.dispose();
  }

  // ── Computed ─────────────────────────────────────────────────────────────────
  int get _writings {
    if (_selectedCount != null) return _selectedCount!;
    return int.tryParse(_customWritingsCtrl.text.replaceAll(',', '')) ?? 0;
  }

  // Minimum days so that chants/day never exceeds 24 h worth (1440 chants).
  int get _minDays {
    final w = _writings;
    if (w <= 0) return 1;
    return (w / _chantsPerDay24h).ceil().clamp(1, _maxSliderDays);
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
    // Derive milestones from the mantra catalog (seeds from cache, always fast).
    final mantra = ref.watch(mantraByIdProvider(widget.mantraId));
    final milestones = (mantra?.milestones?.isNotEmpty == true)
        ? mantra!.milestones!
        : _defaultMilestones;

    // Build a lookup: count → dayOptions
    final dayOptionsMap = {for (final m in milestones) m.count: m.dayOptions};
    final currentDayOptions =
        dayOptionsMap[_selectedCount] ?? _dayOptionsFallback;

    final minDays = _minDays;
    // If current _days is below the new minimum (e.g. count changed), snap it up.
    if (_days < minDays) _days = minDays;
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

          // Count preset chips
          Wrap(
            spacing: KvlSpacing.xs,
            runSpacing: KvlSpacing.xs,
            children: [
              for (final milestone in milestones)
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedCount = milestone.count;
                    _customWritingsCtrl.text = '${milestone.count}';
                    // Auto-select first day option for this count.
                    _days = milestone.dayOptions.firstOrNull ??
                        _dayOptionsFallback.first;
                  }),
                  child: KvlChip(
                    label: IndianNumberFormat.format(milestone.count),
                    variant: _selectedCount == milestone.count
                        ? KvlChipVariant.gold
                        : KvlChipVariant.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: KvlSpacing.sm),

          // Custom writings input
          KvlCard(
            variant: _selectedCount == null
                ? KvlCardVariant.soft
                : KvlCardVariant.plain,
            border: _selectedCount == null
                ? Border.all(color: KvlColors.primary, width: 1.5)
                : null,
            onTap: () => setState(() => _selectedCount = null),
            child: Row(
              children: [
                _RadioDot(selected: _selectedCount == null),
                const SizedBox(width: KvlSpacing.sm),
                Expanded(
                  child: _selectedCount == null
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

          // Day quick-pick — segmented style, updates with count selection
          _DaySegmented(
            options: currentDayOptions,
            selected: _days,
            onSelect: (d) => setState(() => _days = d),
          ),
          const SizedBox(height: KvlSpacing.sm),

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
                  value: _days.clamp(minDays, sliderMax.toInt()).toDouble(),
                  min: minDays.toDouble(),
                  max: sliderMax,
                  activeColor: KvlColors.primary,
                  inactiveColor: KvlColors.primarySoft,
                  onChanged: (v) => setState(
                    () => _days = v.round().clamp(minDays, sliderMax.toInt()),
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

// ── Helpers ────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: KvlText.title(13));
  }
}

/// Horizontal segmented control for day quick-picks.
/// Styled as flat outlined tiles — distinct from the rounded chip presets.
class _DaySegmented extends StatelessWidget {
  const _DaySegmented({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<int> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Row(
        key: ValueKey(options),
        children: [
          for (int i = 0; i < options.length; i++) ...[
            Expanded(child: _Tile(
              days: options[i],
              selected: selected == options[i],
              isFirst: i == 0,
              isLast: i == options.length - 1,
              onTap: () => onSelect(options[i]),
            )),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.days,
    required this.selected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final int days;
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.horizontal(
      left: isFirst ? const Radius.circular(12) : Radius.zero,
      right: isLast ? const Radius.circular(12) : Radius.zero,
    );
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? KvlColors.primary : Colors.white,
          borderRadius: radius,
          border: Border.all(
            color: selected ? KvlColors.primary : KvlColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$days',
              style: KvlText.ui(14, FontWeight.w700).copyWith(
                color: selected ? Colors.white : KvlColors.ink,
              ),
            ),
            Text(
              'days',
              style: KvlText.caption(9.5).copyWith(
                color: selected
                    ? Colors.white.withValues(alpha: .82)
                    : KvlColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
