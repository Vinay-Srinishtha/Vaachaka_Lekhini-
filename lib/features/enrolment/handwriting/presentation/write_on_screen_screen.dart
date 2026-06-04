import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';

import '../../../../app/providers.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../domain/handwriting_asset.dart';

class WriteOnScreenScreen extends ConsumerStatefulWidget {
  const WriteOnScreenScreen({super.key, required this.mantraId});
  final String mantraId;

  @override
  ConsumerState<WriteOnScreenScreen> createState() => _WriteOnScreenScreenState();
}

class _WriteOnScreenScreenState extends ConsumerState<WriteOnScreenScreen> {
  late final SignatureController _controller = SignatureController(
    penStrokeWidth: 4,
    penColor: KvlColors.ink,
    exportBackgroundColor: Colors.transparent,
  );

  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isEmpty) return;
    setState(() => _saving = true);
    final png = await _controller.toPngBytes();
    final profile = ref.read(activeProfileProvider).value;
    if (png == null || profile == null) {
      setState(() => _saving = false);
      return;
    }
    await ref.read(handwritingRepositoryProvider).savePng(
          profileId: profile.id,
          mode: HandwritingMode.writeOnScreen,
          bytes: png,
          mantraId: widget.mantraId,
        );
    if (!mounted) return;
    context.go('${KvlRoute.setTargetWritings}/${widget.mantraId}');
  }

  @override
  Widget build(BuildContext context) {
    final mantra = ref.watch(mantraByIdProvider(widget.mantraId));
    final guide = mantra?.name.devanagari ?? '';
    return KvlScaffold(
      title: 'Write Your Mantra Sample',
      trailing: TextButton(
        onPressed: _controller.isEmpty ? null : _controller.clear,
        child: Text('Clear', style: KvlText.ui(12, FontWeight.w600).copyWith(color: KvlColors.primaryDeep)),
      ),
      padding: const EdgeInsets.fromLTRB(KvlSpacing.lg, 0, KvlSpacing.lg, KvlSpacing.lg),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: KvlColors.surface,
                borderRadius: KvlRadius.brLG,
                border: Border.all(color: KvlColors.border, style: BorderStyle.solid),
              ),
              child: Stack(
                children: [
                  // Ghost-text guide
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        guide,
                        textAlign: TextAlign.center,
                        style: KvlText.mantraDevanagari(30).copyWith(color: KvlColors.border),
                      ),
                    ),
                  ),
                  Signature(
                    controller: _controller,
                    backgroundColor: Colors.transparent,
                    height: double.infinity,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KvlSpacing.sm),
          Row(
            children: [
              _ToolButton(icon: Icons.edit_rounded, onTap: () {}),
              const SizedBox(width: 8),
              _ToolButton(icon: Icons.palette_rounded, onTap: () {}),
              const SizedBox(width: 8),
              _ToolButton(icon: Icons.cleaning_services_rounded, onTap: _controller.clear),
              const Spacer(),
              _ToolButton(icon: Icons.undo_rounded, onTap: _controller.undo),
              const SizedBox(width: 8),
              _ToolButton(icon: Icons.redo_rounded, onTap: _controller.redo),
            ],
          ),
          const SizedBox(height: KvlSpacing.sm),
          KvlButton(
            label: _saving ? 'Saving…' : 'Save Handwriting',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: KvlColors.surface,
          border: Border.all(color: KvlColors.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 15, color: KvlColors.inkSoft),
      ),
    );
  }
}
