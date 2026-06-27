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
  bool _starting = false;
  bool _autoTriggered = false; // ensures single-mantra auto-start fires exactly once

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(mantraRepositoryProvider).refresh());
  }

  Future<void> _start() async {
    final mantraId = _selectedId;
    if (mantraId == null || _starting) return;
    setState(() => _starting = true);
    try {
      final profile = ref.read(activeProfileProvider).value;
      if (profile == null || !mounted) return;

      final repo = ref.read(programRepositoryProvider);
      final existing = await repo.findActiveForMantra(
        memberId: profile.id,
        mantraId: mantraId,
      );
      final program = existing ??
          await repo.createOpen(memberId: profile.id, mantraId: mantraId);
      if (!mounted) return;
      context.go('${KvlRoute.practice}/${program.id}');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(mantraCatalogProvider).value ?? const [];

    if (_selectedId != null && !catalog.any((m) => m.id == _selectedId)) {
      _selectedId = catalog.isNotEmpty ? catalog.first.id : null;
    }
    _selectedId ??= catalog.isNotEmpty ? catalog.first.id : null;

    // Single mantra — kick off immediately without showing the list UI.
    // _autoTriggered ensures only one callback is ever queued regardless of rebuilds.
    if (catalog.length == 1 && _selectedId != null && !_autoTriggered) {
      _autoTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _start();
      });
      return const Scaffold(backgroundColor: Color(0xFFFDF8F2), body: SizedBox.shrink());
    }

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
            label: _starting ? 'Starting…' : context.l10n.confirmSelection,
            onPressed: (_selectedId == null || _starting) ? null : _start,
          ),
        ],
      ),
    );
  }
}
