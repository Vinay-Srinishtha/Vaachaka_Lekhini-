import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../l10n/l10n.dart';
import '../../../../app/router.dart';
import '../../../../core/remote_config/remote_config.dart';
import '../../../../core/remote_config/remote_config_keys.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../domain/handwriting_asset.dart';

class HandwritingSubmitScreen extends ConsumerStatefulWidget {
  const HandwritingSubmitScreen({
    super.key,
    required this.mantraId,
    this.isRetrain = false,
  });
  final String mantraId;
  /// When true: skip program creation, just save the sample and pop back.
  final bool isRetrain;

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
      final suffix = widget.isRetrain ? '?retrain=1' : '';
      context.push('$route/${widget.mantraId}$suffix');
      return;
    }
    // Default font — just record the choice.
    final profile = ref.read(activeProfileProvider).value;
    if (profile != null) {
      await ref.read(handwritingRepositoryProvider).recordDefaultFontChoice(
            profileId: profile.id,
            mantraId: widget.mantraId,
          );
    }
    if (!mounted) return;
    if (widget.isRetrain) {
      context.pop();
    } else {
      context.push('${KvlRoute.setTargetWritings}/${widget.mantraId}');
    }
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
          Text(context.l10n.submitHandwritingTitle, textAlign: TextAlign.center, style: KvlText.title(19)),
          const SizedBox(height: 6),
          Text(
            context.l10n.submitHandwritingDescription,
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
                    (m != HandwritingMode.uploadGallery || galleryEnabled) &&
                    // In retrain mode the default-font option is irrelevant
                    (m != HandwritingMode.useDefaultFont || !widget.isRetrain))
                  m,
            ];
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: KvlSpacing.sm,
              mainAxisSpacing: KvlSpacing.sm,
              childAspectRatio: 0.88,
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
          KvlButton(label: context.l10n.confirmSelectionButton, onPressed: _selected == null ? null : _confirm),
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
          Text(
            switch (mode) {
              HandwritingMode.writeOnScreen => context.l10n.modeWriteOnScreenLabel,
              HandwritingMode.captureCamera => context.l10n.modeCaptureCameraLabel,
              HandwritingMode.uploadGallery => context.l10n.modeUploadGalleryLabel,
              HandwritingMode.useDefaultFont => context.l10n.modeDefaultFontLabel,
            },
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: KvlText.ui(12, FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              sub,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: KvlText.caption(10).copyWith(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
