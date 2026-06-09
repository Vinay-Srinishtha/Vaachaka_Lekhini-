import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../l10n/l10n.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../domain/handwriting_asset.dart';

class CaptureHandwritingScreen extends ConsumerStatefulWidget {
  const CaptureHandwritingScreen({super.key, required this.mantraId});
  final String mantraId;

  @override
  ConsumerState<CaptureHandwritingScreen> createState() => _CaptureHandwritingScreenState();
}

class _CaptureHandwritingScreenState extends ConsumerState<CaptureHandwritingScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _error;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = context.l10n.noCameraAvailable);
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _controller = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await c.takePicture();
      final profile = ref.read(activeProfileProvider).value;
      if (profile != null) {
        await ref.read(handwritingRepositoryProvider).registerExisting(
              profileId: profile.id,
              mode: HandwritingMode.captureCamera,
              filePath: file.path,
              mantraId: widget.mantraId,
            );
      }
      if (!mounted) return;
      context.go('${KvlRoute.setTargetWritings}/${widget.mantraId}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _error = '$e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: context.l10n.captureHandwritingTitle,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      padding: const EdgeInsets.fromLTRB(KvlSpacing.lg, 0, KvlSpacing.lg, KvlSpacing.lg),
      body: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: KvlRadius.brLG,
              child: FutureBuilder(
                future: _initFuture,
                builder: (_, _) {
                  if (_error != null) {
                    return _ErrorBox(message: _error!);
                  }
                  final c = _controller;
                  if (c == null || !c.value.isInitialized) {
                    return const ColoredBox(
                      color: Color(0xFF111114),
                      child: Center(child: CircularProgressIndicator(color: Colors.white70)),
                    );
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(c),
                      Center(
                        child: Container(
                          width: 200,
                          height: 260,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: .7), width: 2),
                            borderRadius: KvlRadius.brMD,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: KvlSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () => context.go('${KvlRoute.handwritingUpload}/${widget.mantraId}'),
                icon: const Icon(Icons.image_outlined),
                iconSize: 28,
              ),
              GestureDetector(
                onTap: _capturing ? null : _capture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _capturing ? KvlColors.primarySoft : KvlColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: KvlColors.primary.withValues(alpha: .3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.circle_outlined, color: Colors.white, size: 48),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.cameraswitch_outlined),
                iconSize: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF111114),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(KvlSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 32),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: KvlText.body(12).copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
