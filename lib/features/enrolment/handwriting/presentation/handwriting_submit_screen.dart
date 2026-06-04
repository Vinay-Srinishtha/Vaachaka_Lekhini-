import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../app/router.dart';
import '../../../../core/remote_config/remote_config.dart';
import '../../../../core/remote_config/remote_config_keys.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../domain/handwriting_asset.dart';

class HandwritingSubmitScreen extends ConsumerStatefulWidget {
  const HandwritingSubmitScreen({super.key, required this.mantraId});
  final String mantraId;

  @override
  ConsumerState<HandwritingSubmitScreen> createState() => _HandwritingSubmitScreenState();
}

class _HandwritingSubmitScreenState extends ConsumerState<HandwritingSubmitScreen> {
  HandwritingMode? _selected;

  Future<void> _confirm() async {
    final mode = _selected;
    if (mode == null) return;
    final route = switch (mode) {
      HandwritingMode.writeOnScreen => KvlRoute.handwritingWrite,
      HandwritingMode.captureCamera => KvlRoute.handwritingCapture,
      HandwritingMode.uploadGallery => KvlRoute.handwritingUpload,
      HandwritingMode.useDefaultFont => null,
    };
    if (route != null) {
      context.push('$route/${widget.mantraId}');
      return;
    }
    // Default font — just record the choice and proceed to home (target setup is Phase 3).
    final profile = ref.read(activeProfileProvider).value;
    if (profile != null) {
      await ref.read(handwritingRepositoryProvider).recordDefaultFontChoice(
            profileId: profile.id,
            mantraId: widget.mantraId,
          );
    }
    if (!mounted) return;
    context.go('${KvlRoute.setTargetWritings}/${widget.mantraId}');
  }

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: '',
      trailing: const SizedBox(width: 36),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: KvlSpacing.md),
          Text('Submit Your Handwriting', textAlign: TextAlign.center, style: KvlText.title(19)),
          const SizedBox(height: 6),
          Text(
            'Upload your handwriting for personalised PDF mantra recitations. Our AI will randomly select samples to feature.',
            textAlign: TextAlign.center,
            style: KvlText.caption(11.5).copyWith(height: 1.5),
          ),
          const SizedBox(height: KvlSpacing.lg),
          () {
            final cfg = ref.watch(remoteConfigProvider).value ?? RemoteConfig.empty;
            final cameraEnabled = cfg.boolFlag(RemoteConfigKeys.handwritingCamera, fallback: true);
            final galleryEnabled = cfg.boolFlag(RemoteConfigKeys.handwritingGallery, fallback: true);
            final modes = [
              for (final m in HandwritingMode.values)
                if ((m != HandwritingMode.captureCamera || cameraEnabled) &&
                    (m != HandwritingMode.uploadGallery || galleryEnabled))
                  m,
            ];
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: KvlSpacing.sm,
              mainAxisSpacing: KvlSpacing.sm,
              childAspectRatio: 1.05,
              children: [
                for (final mode in modes)
                  _ModeCard(
                    mode: mode,
                    selected: _selected == mode,
                    onTap: () => setState(() => _selected = mode),
                  ),
              ],
            );
          }(),
          const SizedBox(height: KvlSpacing.lg),
          KvlButton(label: 'Confirm selection', onPressed: _selected == null ? null : _confirm),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.selected, required this.onTap});
  final HandwritingMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, sub) = switch (mode) {
      HandwritingMode.writeOnScreen => (Icons.draw_rounded, 'Draw directly on your device'),
      HandwritingMode.captureCamera => (Icons.camera_alt_rounded, 'Take a photo of your writing'),
      HandwritingMode.uploadGallery => (Icons.image_rounded, 'Select an existing image'),
      HandwritingMode.useDefaultFont => (Icons.text_fields_rounded, "Use the app's standard font"),
    };
    return KvlCard(
      variant: selected ? KvlCardVariant.soft : KvlCardVariant.plain,
      border: selected ? Border.all(color: KvlColors.primary, width: 1.5) : null,
      padding: const EdgeInsets.all(KvlSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: KvlColors.primaryGhost,
              borderRadius: KvlRadius.brSM,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: KvlColors.primaryDeep, size: 18),
          ),
          const SizedBox(height: 8),
          Text(mode.label, textAlign: TextAlign.center, style: KvlText.ui(12, FontWeight.w600)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(sub, textAlign: TextAlign.center, style: KvlText.caption(10).copyWith(height: 1.3)),
          ),
        ],
      ),
    );
  }
}
