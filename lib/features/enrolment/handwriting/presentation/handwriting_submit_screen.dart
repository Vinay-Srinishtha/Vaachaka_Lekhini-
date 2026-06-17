import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../app/router.dart';
import '../domain/handwriting_asset.dart';

/// Transparent redirect — no UI shown.
/// Checks if a writeOnScreen sample already exists for this mantra:
///   • Has sample → goes to the writing screen in retrain mode (practice).
///   • No sample  → goes to the writing screen to collect the first sample.
class HandwritingSubmitScreen extends ConsumerStatefulWidget {
  const HandwritingSubmitScreen({
    super.key,
    required this.mantraId,
    this.isRetrain = false,
  });
  final String mantraId;
  final bool isRetrain;

  @override
  ConsumerState<HandwritingSubmitScreen> createState() => _HandwritingSubmitScreenState();
}

class _HandwritingSubmitScreenState extends ConsumerState<HandwritingSubmitScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  Future<void> _redirect() async {
    final profile = await ref.read(activeProfileProvider.future);
    if (!mounted) return;

    bool hasSample = false;
    if (profile != null) {
      final samples = await ref
          .read(handwritingRepositoryProvider)
          .listForProfile(profile.id);
      hasSample = samples.any((s) =>
          s.mode == HandwritingMode.writeOnScreen &&
          (s.mantraId == null || s.mantraId == widget.mantraId));
    }

    if (!mounted) return;
    // If sample exists → practice mode (retrain). If not → first-time sample collection.
    final retrain = hasSample || widget.isRetrain;
    final suffix = retrain ? '?retrain=1' : '';
    context.replace('${KvlRoute.handwritingWrite}/${widget.mantraId}$suffix');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
