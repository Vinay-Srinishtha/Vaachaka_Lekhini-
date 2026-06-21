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
  ConsumerState<MantraSelectionScreen> createState() =>
      _MantraSelectionScreenState();
}

class _MantraSelectionScreenState extends ConsumerState<MantraSelectionScreen> {
  String? _selectedId;
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(mantraRepositoryProvider).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(mantraCatalogProvider).value ?? const [];

    // Only one mantra available — don't make the user "choose"; go straight
    // to that mantra's details/start flow.
    if (catalog.length == 1 && !_redirected) {
      _redirected = true;
      final onlyId = catalog.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushReplacement('${KvlRoute.mantraDetails}/$onlyId');
        }
      });
      return KvlScaffold(
        title: context.l10n.mantraSelectionTitle,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedId != null && !catalog.any((m) => m.id == _selectedId)) {
      _selectedId = catalog.isNotEmpty ? catalog.first.id : null;
    }
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
