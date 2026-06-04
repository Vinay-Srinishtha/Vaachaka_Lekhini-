import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/navigation/back_navigation.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../../core/widgets/widgets.dart';

/// Mockup 4.1 — picks the *total writings* target.
/// Next step is Set Target — Days, reached via path + query param so the
/// chosen number survives the navigation transition.
class SetTargetWritingsScreen extends ConsumerStatefulWidget {
  const SetTargetWritingsScreen({super.key, required this.mantraId});
  final String mantraId;

  @override
  ConsumerState<SetTargetWritingsScreen> createState() => _SetTargetWritingsScreenState();
}

class _SetTargetWritingsScreenState extends ConsumerState<SetTargetWritingsScreen> {
  _Preset _preset = _Preset.crore;
  final _customWritings = TextEditingController(text: '500000');
  final _customDays = TextEditingController(text: '365');

  @override
  void initState() {
    super.initState();
    _customWritings.addListener(_onCustomChanged);
    _customDays.addListener(_onCustomChanged);
  }

  void _onCustomChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _customWritings.removeListener(_onCustomChanged);
    _customDays.removeListener(_onCustomChanged);
    _customWritings.dispose();
    _customDays.dispose();
    super.dispose();
  }

  int get _writings {
    if (_preset == _Preset.crore) return 10000000;
    if (_preset == _Preset.million) return 1000000;
    return int.tryParse(_customWritings.text) ?? 0;
  }

  int get _daysHint {
    if (_preset != _Preset.custom) return 0;
    return int.tryParse(_customDays.text) ?? 0;
  }

  String _pacing() {
    final w = _writings;
    final d = _daysHint;
    if (w <= 0 || d <= 0) return '';
    final perDay = (w / d).ceil();
    final minutesPerDay = perDay / 60.0;
    final pace = minutesPerDay >= 60
        ? '${(minutesPerDay / 60).toStringAsFixed(1)} hours/day'
        : '${minutesPerDay.toStringAsFixed(0)} minutes/day';
    return 'To complete this in $d days, it means ~${IndianNumberFormat.format(perDay)} writings/day ≈ $pace';
  }

  void _confirm() {
    if (_writings <= 0) return;
    final query = _daysHint > 0 ? '?days=$_daysHint' : '';
    context.push('${KvlRoute.setTargetDays}/${widget.mantraId}/$_writings$query');
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
            'Choose a target for your practice. You can select one of the popular targets or set your own custom one.',
            textAlign: TextAlign.center,
            style: KvlText.caption(11.5).copyWith(height: 1.5),
          ),
          const SizedBox(height: KvlSpacing.lg),
          _RadioCard(
            selected: _preset == _Preset.crore,
            onTap: () => setState(() => _preset = _Preset.crore),
            title: '1,00,00,000 writings',
            badge: 'Most Popular',
          ),
          const SizedBox(height: KvlSpacing.sm),
          _RadioCard(
            selected: _preset == _Preset.million,
            onTap: () => setState(() => _preset = _Preset.million),
            title: '1,000,000 writings',
          ),
          const SizedBox(height: KvlSpacing.sm),
          KvlCard(
            variant: _preset == _Preset.custom ? KvlCardVariant.soft : KvlCardVariant.plain,
            border: _preset == _Preset.custom ? Border.all(color: KvlColors.primary, width: 1.5) : null,
            onTap: () => setState(() => _preset = _Preset.custom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _RadioDot(selected: _preset == _Preset.custom),
                    const SizedBox(width: KvlSpacing.sm),
                    Text('Set a custom target', style: KvlText.ui(13, FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: KvlSpacing.md),
                KvlInput(
                  label: 'Total Writings',
                  hint: 'e.g., 500,000',
                  controller: _customWritings,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: KvlSpacing.sm),
                KvlInput(
                  label: 'Completion Time (in days)',
                  hint: 'e.g., 365',
                  controller: _customDays,
                  keyboardType: TextInputType.number,
                ),
                if (_preset == _Preset.custom && _pacing().isNotEmpty) ...[
                  const SizedBox(height: KvlSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(KvlSpacing.sm),
                    decoration: BoxDecoration(color: KvlColors.primaryGhost, borderRadius: KvlRadius.brSM),
                    child: Text(_pacing(), style: KvlText.caption(10.5).copyWith(height: 1.4)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: KvlSpacing.lg),
          KvlButton(label: 'Confirm Target', onPressed: _writings > 0 ? _confirm : null),
          const SizedBox(height: KvlSpacing.sm),
          Center(
            child: TextButton(
              onPressed: () =>
                  context.popOrGo('${KvlRoute.handwritingSubmit}/${widget.mantraId}'),
              child: Text(
                'Cancel',
                style: KvlText.caption(12).copyWith(color: KvlColors.primaryDeep, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Preset { crore, million, custom }

class _RadioCard extends StatelessWidget {
  const _RadioCard({required this.selected, required this.onTap, required this.title, this.badge});
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      variant: selected ? KvlCardVariant.soft : KvlCardVariant.plain,
      border: selected ? Border.all(color: KvlColors.primary, width: 1.5) : null,
      padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md, vertical: KvlSpacing.md),
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
                  Text(badge!,
                      style: KvlText.caption(10.5).copyWith(color: KvlColors.primaryDeep, fontWeight: FontWeight.w600)),
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
        border: Border.all(color: selected ? KvlColors.primary : KvlColors.border, width: 2),
      ),
      alignment: Alignment.center,
      child: selected ? const Icon(Icons.check_rounded, size: 11, color: Colors.white) : null,
    );
  }
}
