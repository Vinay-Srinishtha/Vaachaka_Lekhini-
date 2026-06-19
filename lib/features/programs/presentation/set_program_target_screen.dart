import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
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
  MantraMilestone(count: 108, dayOptions: [1, 7, 21, 40]),
  MantraMilestone(count: 1008, dayOptions: [7, 21, 40, 108]),
  MantraMilestone(count: 5116, dayOptions: [21, 40, 108, 180]),
  MantraMilestone(count: 10116, dayOptions: [40, 108, 180, 365]),
];
const _dayOptionsFallback = [7, 21, 108, 365];

// Labels derived by position in the day-options list.
const _paceLabels = ['Fastest', 'Balanced', 'Gentle', 'Sustainable'];

// Pastel chip colours for day options (up to 4).
const _chipColors = [
  Color(0xFFE89880), // coral
  Color(0xFFD4C46E), // amber
  Color(0xFF6BBFB0), // teal
  Color(0xFF7AAE8A), // sage
];

class _SetProgramTargetScreenState
    extends ConsumerState<SetProgramTargetScreen> {
  int? _selectedCount = 108; // null means custom
  final _customWritingsCtrl = TextEditingController(text: '108');

  static const _maxSliderDays = 2000;
  static const _chantsPerDay24h = 1440;

  int _days = 1;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _customWritingsCtrl.addListener(_rebuild);
  }

  void _rebuild() {
    if (!mounted) return;
    setState(() {
      final min = _minDays;
      if (_days < min) _days = min;
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _customWritingsCtrl.removeListener(_rebuild);
    _customWritingsCtrl.dispose();
    super.dispose();
  }

  int get _writings {
    if (_selectedCount != null) return _selectedCount!;
    return int.tryParse(_customWritingsCtrl.text.replaceAll(',', '')) ?? 0;
  }

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

  Future<void> _confirm() async {
    if (_writings <= 0 || _days <= 0 || _busy) return;
    setState(() => _busy = true);

    try {
      final profile = ref.read(activeProfileProvider).value;
      if (profile == null) {
        setState(() => _busy = false);
        return;
      }

      final enrolment = await ref
          .read(voiceEnrolmentRepositoryProvider)
          .get(profile.id, widget.mantraId);
      if (!mounted) return;
      if (enrolment == null || !enrolment.isComplete) {
        setState(() => _busy = false);
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

      final program = await ref
          .read(programRepositoryProvider)
          .create(
            memberId: profile.id,
            mantraId: widget.mantraId,
            targetWritings: _writings,
            targetDays: _days,
          );
      if (!mounted) return;
      // Go directly to the practice counter for this program.
      context.go('${KvlRoute.practice}/${program.id}');
      return;
    } catch (e, st) {
      debugPrint('[SetProgramTarget] create failed: $e\n$st');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          backgroundColor: KvlColors.danger,
          content: Text(
            'Could not create this practice target. Please try again.',
            style: KvlText.caption(12).copyWith(color: Colors.white),
          ),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mantra = ref.watch(mantraByIdProvider(widget.mantraId));
    final milestones = (mantra?.milestones?.isNotEmpty == true)
        ? mantra!.milestones!
        : _defaultMilestones;

    final dayOptionsMap = {for (final m in milestones) m.count: m.dayOptions};
    final currentDayOptions =
        dayOptionsMap[_selectedCount] ?? _dayOptionsFallback;

    final minDays = _minDays;
    final sliderMax = _days > _maxSliderDays
        ? _days.toDouble()
        : _maxSliderDays.toDouble();
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

          // Full-width radio cards for each milestone count
          for (int i = 0; i < milestones.length; i++) ...[
            _CountCard(
              count: milestones[i].count,
              badge: i == 0 ? 'Most Popular' : null,
              selected: _selectedCount == milestones[i].count,
              onTap: () => setState(() {
                _selectedCount = milestones[i].count;
                _customWritingsCtrl.text = '${milestones[i].count}';
                _days =
                    milestones[i].dayOptions.firstOrNull ??
                    _dayOptionsFallback.first;
              }),
            ),
            const SizedBox(height: KvlSpacing.xs),
          ],

          // Custom writings card
          _CustomCountCard(
            selected: _selectedCount == null,
            controller: _customWritingsCtrl,
            onTap: () => setState(() => _selectedCount = null),
            totalWritingsLabel: context.l10n.totalWritingsLabel,
            totalWritingsHint: context.l10n.totalWritingsHint,
            setCustomTarget: context.l10n.setCustomTarget,
          ),

          const SizedBox(height: KvlSpacing.lg),

          // ── Section: Duration ───────────────────────────────────────────────
          _SectionHeader(label: 'Spread over how many days?'),
          const SizedBox(height: KvlSpacing.sm),

          // Colored pill chips with pace labels
          _DayChips(
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
                      child: Text('Duration', style: KvlText.caption(11.5)),
                    ),
                    Text(
                      context.l10n.daysValue(_days),
                      style: KvlText.ui(
                        14,
                        FontWeight.w700,
                      ).copyWith(color: KvlColors.primaryDeep),
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
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(KvlRoute.programs),
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

// ── Count cards ────────────────────────────────────────────────────────────────

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.count,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: KvlSpacing.md,
          vertical: KvlSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? KvlColors.primaryGhost : Colors.white,
          borderRadius: KvlRadius.brMD,
          border: Border.all(
            color: selected ? KvlColors.primary : KvlColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _RadioDot(selected: selected),
            const SizedBox(width: KvlSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${IndianNumberFormat.format(count)} writings',
                    style: KvlText.ui(14, FontWeight.w600).copyWith(
                      color: selected ? KvlColors.primaryDeep : KvlColors.ink,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      badge!,
                      style: KvlText.caption(11).copyWith(
                        color: KvlColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomCountCard extends StatelessWidget {
  const _CustomCountCard({
    required this.selected,
    required this.controller,
    required this.onTap,
    required this.totalWritingsLabel,
    required this.totalWritingsHint,
    required this.setCustomTarget,
  });

  final bool selected;
  final TextEditingController controller;
  final VoidCallback onTap;
  final String totalWritingsLabel;
  final String totalWritingsHint;
  final String setCustomTarget;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: KvlSpacing.md,
          vertical: KvlSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? KvlColors.primaryGhost : Colors.white,
          borderRadius: KvlRadius.brMD,
          border: Border.all(
            color: selected ? KvlColors.primary : KvlColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _RadioDot(selected: selected),
            const SizedBox(width: KvlSpacing.sm),
            Expanded(
              child: selected
                  ? KvlInput(
                      label: totalWritingsLabel,
                      hint: totalWritingsHint,
                      controller: controller,
                      keyboardType: TextInputType.number,
                    )
                  : Text(
                      setCustomTarget,
                      style: KvlText.ui(14, FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day chips ──────────────────────────────────────────────────────────────────

class _DayChips extends StatelessWidget {
  const _DayChips({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<int> options;
  final int selected;
  final ValueChanged<int> onSelect;

  static String _label(int index, int total) {
    if (total <= 1) return '';
    if (total == 2) return index == 0 ? 'Shorter' : 'Longer';
    if (total == 3) {
      return ['Faster', 'Balanced', 'Sustainable'][index.clamp(0, 2)];
    }
    return _paceLabels[index.clamp(0, _paceLabels.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Wrap(
        key: ValueKey(options),
        spacing: KvlSpacing.xs,
        runSpacing: KvlSpacing.xs,
        children: [
          for (int i = 0; i < options.length; i++)
            _DayChip(
              days: options[i],
              label: _label(i, options.length),
              color: _chipColors[i.clamp(0, _chipColors.length - 1)],
              selected: selected == options[i],
              onTap: () => onSelect(options[i]),
            ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.days,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final int days;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? color : color.withValues(alpha: 0.18);
    final fg = selected ? Colors.white : color.withValues(alpha: 0.9);
    final border = selected ? color : color.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Text(
          label.isNotEmpty ? '$days days · $label' : '$days days',
          style: KvlText.ui(12.5, FontWeight.w600).copyWith(color: fg),
        ),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: KvlText.title(13));
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 20,
      height: 20,
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
          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
          : null,
    );
  }
}
