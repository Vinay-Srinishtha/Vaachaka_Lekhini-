import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/theme.dart';
import '../domain/tnc.dart';

/// Shows the T&C bottom sheet and resolves to true when the user accepts.
/// Resolves to false if they dismiss without accepting.
Future<bool> showTncSheet(BuildContext context, TermsAndConditions tnc) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TncSheet(tnc: tnc),
  );
  return result ?? false;
}

class _TncSheet extends ConsumerStatefulWidget {
  const _TncSheet({required this.tnc});
  final TermsAndConditions tnc;

  @override
  ConsumerState<_TncSheet> createState() => _TncSheetState();
}

class _TncSheetState extends ConsumerState<_TncSheet> {
  final _scrollController = ScrollController();
  bool _scrolledToBottom = false;
  bool _accepted = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // If the content fits without scrolling, unlock immediately after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) {
        setState(() => _scrolledToBottom = true);
        return;
      }
      final max = _scrollController.position.maxScrollExtent;
      if (max <= 40) setState(() => _scrolledToBottom = true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrolledToBottom) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 40) {
      setState(() => _scrolledToBottom = true);
    }
  }

  Future<void> _submit() async {
    if (!_accepted || !_scrolledToBottom) return;
    setState(() { _submitting = true; _error = null; });
    try {
      await ref.read(tncRepositoryProvider).accept(widget.tnc.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _submitting = false;
        _error = 'Could not record acceptance. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 10),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: KvlColors.inkSoft.withValues(alpha: .4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.tnc.title,
                    style: KvlText.title(17)),
                const SizedBox(height: 4),
                Text('Version ${widget.tnc.version}',
                    style: KvlText.caption(11.5)
                        .copyWith(color: KvlColors.inkSoft)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: KvlColors.inkSoft.withValues(alpha: .15)),

          // Scroll hint
          if (!_scrolledToBottom)
            Container(
              width: double.infinity,
              color: KvlColors.primaryDeep.withValues(alpha: .06),
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
              child: Row(children: [
                Icon(Icons.swipe_up_rounded, size: 14, color: KvlColors.primaryDeep),
                const SizedBox(width: 6),
                Text('Please scroll to the bottom to continue',
                    style: KvlText.caption(11.5)
                        .copyWith(color: KvlColors.primaryDeep)),
              ]),
            ),

          // Content
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Text(widget.tnc.content,
                    style: KvlText.body(13.5)
                        .copyWith(height: 1.65, color: KvlColors.ink)),
              ),
            ),
          ),

          Divider(height: 1, color: KvlColors.inkSoft.withValues(alpha: .15)),

          // Bottom: checkbox + button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  if (!_scrolledToBottom)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Read the full terms above before accepting.',
                        style: KvlText.caption(11).copyWith(color: KvlColors.inkSoft),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  GestureDetector(
                    onTap: _scrolledToBottom
                        ? () => setState(() => _accepted = !_accepted)
                        : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _accepted,
                          onChanged: _scrolledToBottom
                              ? (v) => setState(() => _accepted = v ?? false)
                              : null,
                          activeColor: KvlColors.primaryDeep,
                          side: BorderSide(
                            color: _scrolledToBottom
                                ? KvlColors.primaryDeep
                                : KvlColors.inkSoft.withValues(alpha: .4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'I have read and agree to the Terms & Conditions.',
                            style: KvlText.body(13).copyWith(
                              color: _scrolledToBottom
                                  ? KvlColors.ink
                                  : KvlColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Text(_error!,
                        style: KvlText.caption(12)
                            .copyWith(color: KvlColors.danger)),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_scrolledToBottom && _accepted && !_submitting)
                          ? _submit
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: KvlColors.primaryDeep,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: KvlRadius.brMD),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Accept & Continue',
                              style: KvlText.ui(14, FontWeight.w700)
                                  .copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
