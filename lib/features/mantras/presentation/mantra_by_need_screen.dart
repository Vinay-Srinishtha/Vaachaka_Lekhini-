import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/mantra.dart';

class MantraByNeedScreen extends ConsumerStatefulWidget {
  const MantraByNeedScreen({super.key});

  @override
  ConsumerState<MantraByNeedScreen> createState() => _MantraByNeedScreenState();
}

class _MantraByNeedScreenState extends ConsumerState<MantraByNeedScreen> {
  MantraNeed? _need;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(mantraRepositoryProvider);
    final recommended = _need == null ? const <Mantra>[] : repo.recommendForNeed(_need!);
    final pick = recommended.isEmpty ? null : recommended.first;

    return KvlScaffold(
      title: 'Mantra for Your Needs',
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.md),
          Text('Select your need or problem',
              style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          _NeedDropdown(value: _need, onChanged: (v) => setState(() => _need = v)),
          const SizedBox(height: KvlSpacing.md),
          if (pick != null) _Recommendation(mantra: pick),
          const SizedBox(height: KvlSpacing.md),
          KvlButton(
            label: 'Start This Practice',
            onPressed: pick == null ? null : () => context.push('${KvlRoute.mantraDetails}/${pick.id}'),
          ),
        ],
      ),
    );
  }
}

class _NeedDropdown extends StatelessWidget {
  const _NeedDropdown({required this.value, required this.onChanged});
  final MantraNeed? value;
  final ValueChanged<MantraNeed?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KvlColors.surface,
        borderRadius: KvlRadius.brMD,
        border: Border.all(color: KvlColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: KvlSpacing.md),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MantraNeed>(
          value: value,
          isExpanded: true,
          hint: Text('Select…', style: KvlText.ui(13).copyWith(color: KvlColors.muted)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: KvlRadius.brMD,
          items: [
            for (final n in MantraNeed.values)
              DropdownMenuItem(value: n, child: Text(n.label, style: KvlText.ui(13))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Recommendation extends StatelessWidget {
  const _Recommendation({required this.mantra});
  final Mantra mantra;

  @override
  Widget build(BuildContext context) {
    return KvlCard(
      variant: KvlCardVariant.warm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MantraText(mantra.name.devanagari, size: 24, color: KvlColors.primaryDeep),
          const SizedBox(height: 6),
          Text(mantra.description,
              textAlign: TextAlign.center,
              style: KvlText.caption(11.5).copyWith(color: KvlColors.inkSoft, height: 1.5)),
          const Divider(color: KvlColors.rule, height: 24),
          if (mantra.recommendedCount != null)
            _Detail(icon: Icons.refresh_rounded, value: '${mantra.recommendedCount} times daily', sub: 'Recitations'),
          if (mantra.recommendedCount != null && mantra.recommendedDays != null)
            const SizedBox(height: KvlSpacing.sm),
          if (mantra.recommendedDays != null)
            _Detail(icon: Icons.calendar_today_rounded, value: 'For ${mantra.recommendedDays} days', sub: 'Duration'),
          const SizedBox(height: KvlSpacing.sm),
          Center(
            child: Text('Learn More',
                style: KvlText.caption(12).copyWith(color: KvlColors.primaryDeep, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.value, required this.sub});
  final IconData icon;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: KvlColors.primaryGhost,
            borderRadius: KvlRadius.brSM,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: KvlColors.primaryDeep),
        ),
        const SizedBox(width: KvlSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: KvlText.ui(12, FontWeight.w600)),
            Text(sub, style: KvlText.muted(10)),
          ],
        ),
      ],
    );
  }
}
