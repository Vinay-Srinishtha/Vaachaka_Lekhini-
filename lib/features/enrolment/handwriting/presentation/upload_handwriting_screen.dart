import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/providers.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../l10n/l10n.dart';
import '../domain/handwriting_asset.dart';

class UploadHandwritingScreen extends ConsumerStatefulWidget {
  const UploadHandwritingScreen({super.key, required this.mantraId});
  final String mantraId;

  @override
  ConsumerState<UploadHandwritingScreen> createState() => _UploadHandwritingScreenState();
}

class _UploadHandwritingScreenState extends ConsumerState<UploadHandwritingScreen> {
  final _picker = ImagePicker();
  final List<XFile> _picked = [];
  final Set<String> _selected = {};
  bool _busy = false;

  Future<void> _pickFromGallery() async {
    setState(() => _busy = true);
    final files = await _picker.pickMultiImage(imageQuality: 90);
    setState(() {
      _picked.addAll(files);
      _selected.addAll(files.map((f) => f.path));
      _busy = false;
    });
  }

  Future<void> _upload() async {
    if (_selected.isEmpty) return;
    setState(() => _busy = true);
    final profile = ref.read(activeProfileProvider).value;
    if (profile == null) {
      setState(() => _busy = false);
      return;
    }
    final repo = ref.read(handwritingRepositoryProvider);
    for (final path in _selected) {
      await repo.registerExisting(
        profileId: profile.id,
        mode: HandwritingMode.uploadGallery,
        filePath: path,
        mantraId: widget.mantraId,
      );
    }
    if (!mounted) return;
    context.go('${KvlRoute.setTargetWritings}/${widget.mantraId}');
  }

  @override
  Widget build(BuildContext context) {
    return KvlScaffold(
      title: context.l10n.uploadHandwritingTitle,
      trailing: IconButton(
        onPressed: _picked.isEmpty
            ? null
            : () => setState(_selected.clear),
        icon: Text(
          context.l10n.deselectAll,
          style: KvlText.caption(11).copyWith(
            color: _picked.isEmpty ? KvlColors.muted : KvlColors.primaryDeep,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_picked.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: KvlSpacing.sm),
              child: Text(
                context.l10n.selectImageHint,
                style: KvlText.caption(11.5),
              ),
            ),
          Expanded(
            child: _picked.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.image_search_outlined, color: KvlColors.muted, size: 48),
                        const SizedBox(height: 8),
                        Text(context.l10n.noImagesYet, style: KvlText.muted(13)),
                        const SizedBox(height: 16),
                        KvlButton(
                          variant: KvlButtonVariant.secondary,
                          label: _busy ? context.l10n.openingButton : context.l10n.pickFromGallery,
                          onPressed: _busy ? null : _pickFromGallery,
                          expand: false,
                        ),
                      ],
                    ),
                  )
                : GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    children: [
                      for (final f in _picked) _Tile(file: f, selected: _selected.contains(f.path), onTap: () {
                        setState(() {
                          if (_selected.contains(f.path)) {
                            _selected.remove(f.path);
                          } else {
                            _selected.add(f.path);
                          }
                        });
                      }),
                    ],
                  ),
          ),
          if (_picked.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: KvlSpacing.sm),
              child: KvlButton(
                variant: KvlButtonVariant.secondary,
                label: context.l10n.pickMore,
                onPressed: _busy ? null : _pickFromGallery,
              ),
            ),
          KvlButton(
            label: context.l10n.uploadSelected(_selected.length),
            onPressed: _selected.isEmpty || _busy ? null : _upload,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.file, required this.selected, required this.onTap});
  final XFile file;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: KvlRadius.brMD,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: KvlRadius.brMD,
            child: Image.file(File(file.path), fit: BoxFit.cover),
          ),
          if (selected)
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: KvlRadius.brMD,
                border: Border.all(color: KvlColors.primary, width: 2.5),
              ),
            ),
          if (selected)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: KvlColors.primary, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}
