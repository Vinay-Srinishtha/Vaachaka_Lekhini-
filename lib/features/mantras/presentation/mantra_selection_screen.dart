import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
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
    final catalog = ref.watch(mantraCatalogProvider);
    _selectedId ??= catalog.isNotEmpty ? catalog.first.id : null;

    return KvlScaffold(
      title: 'Mantra Selection',
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
            label: 'Select mantra based on your need →',
            onPressed: () => context.push(KvlRoute.mantraByNeed),
          ),
          const SizedBox(height: KvlSpacing.sm),
          KvlButton(
            label: 'Confirm Selection',
            onPressed: _selectedId == null
                ? null
                : () => context.push('${KvlRoute.mantraDetails}/$_selectedId'),
          ),
        ],
      ),
    );
  }
}
