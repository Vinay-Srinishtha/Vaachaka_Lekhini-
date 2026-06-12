import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../l10n/l10n.dart';
import '../../../app/router.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import 'widgets/mantra_row.dart';

class MantraSelectionScreen extends ConsumerStatefulWidget {
  const MantraSelectionScreen({super.key});

  @override
  ConsumerState<MantraSelectionScreen> createState() => _MantraSelectionScreenState();
}

class _MantraSelectionScreenState extends ConsumerState<MantraSelectionScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(mantraCatalogProvider).value ?? const [];
    _selectedId ??= catalog.isNotEmpty ? catalog.first.id : null;

    return KvlScaffold(
      title: context.l10n.mantraSelectionTitle,
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
          const SizedBox(height: KvlSpacing.sm),
          KvlButton(
            variant: KvlButtonVariant.ghost,
            label: context.l10n.selectMantraByNeed,
            onPressed: () => context.push(KvlRoute.mantraByNeed),
          ),
          const SizedBox(height: KvlSpacing.sm),
          KvlButton(
            label: context.l10n.confirmSelection,
            onPressed: _selectedId == null
                ? null
                : () => context.push('${KvlRoute.mantraDetails}/$_selectedId'),
          ),
        ],
      ),
    );
  }
}
