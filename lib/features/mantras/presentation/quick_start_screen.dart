import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import 'widgets/mantra_row.dart';

class QuickStartScreen extends ConsumerStatefulWidget {
  const QuickStartScreen({super.key});

  @override
  ConsumerState<QuickStartScreen> createState() => _QuickStartScreenState();
}

class _QuickStartScreenState extends ConsumerState<QuickStartScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(mantraCatalogProvider);
    // Auto-select first mantra so the CTA is never dead on first render.
    _selectedId ??= catalog.isNotEmpty ? catalog.first.id : null;

    return KvlScaffold(
      title: context.l10n.quickStartTitle,
      scrollable: false,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: KvlSpacing.sm),
              itemCount: catalog.length,
              itemBuilder: (_, i) {
                final m = catalog[i];
                return MantraRow(
                  mantra: m,
                  selected: m.id == _selectedId,
                  onTap: () => setState(() => _selectedId = m.id),
                );
              },
            ),
          ),
          KvlButton(
            label: context.l10n.quickStartButton,
            onPressed: _selectedId == null
                ? null
                : () => context.push('${KvlRoute.mantraDetails}/$_selectedId'),
          ),
        ],
      ),
    );
  }
}
