import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../enrolment/handwriting/domain/handwriting_asset.dart';
import '../../mantras/domain/mantra.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final bookAssetsProvider =
    FutureProvider.autoDispose.family<List<HandwritingAsset>, String>(
  (ref, mantraId) async {
    final profile = ref.watch(activeProfileProvider).value;
    if (profile == null) return const [];
    final all =
        await ref.read(handwritingRepositoryProvider).listForProfile(profile.id);
    return all
        .where((a) =>
            a.mantraId == mantraId &&
            a.mode == HandwritingMode.writeOnScreen &&
            a.filePath != null)
        .toList();
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point button
// ─────────────────────────────────────────────────────────────────────────────

class BookPreviewButton extends ConsumerWidget {
  const BookPreviewButton({
    super.key,
    required this.mantraId,
    required this.compact,
  });

  final String mantraId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(bookAssetsProvider(mantraId)).value?.length ?? 0;

    return GestureDetector(
      onTap: () => openSheet(context, mantraId),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 13,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: KvlColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: KvlColors.border, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: compact ? 14 : 16,
              color: KvlColors.primaryDeep,
            ),
            const SizedBox(width: 5),
            Text(
              'My Book',
              style: KvlText.ui(compact ? 11.5 : 12.5, FontWeight.w700)
                  .copyWith(color: KvlColors.primaryDeep),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: KvlColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  IndianNumberFormat.format(count),
                  style: KvlText.ui(compact ? 10 : 11, FontWeight.w800)
                      .copyWith(color: KvlColors.primaryDeep),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void openSheet(BuildContext context, String mantraId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookPreviewSheet(mantraId: mantraId),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BookPreviewSheet extends ConsumerWidget {
  const _BookPreviewSheet({required this.mantraId});
  final String mantraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(bookAssetsProvider(mantraId));
    final mantra = ref.watch(mantraByIdProvider(mantraId));
    final mh = MediaQuery.sizeOf(context).height;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFDF8F2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: KvlColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        color: KvlColors.primaryDeep, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Writing Book',
                            style: KvlText.title(17),
                          ),
                          if (mantra != null)
                            Text(
                              _mantraName(mantra),
                              style: KvlText.caption(12)
                                  .copyWith(color: KvlColors.inkSoft),
                            ),
                        ],
                      ),
                    ),
                    assets.when(
                      data: (list) => Text(
                        '${IndianNumberFormat.format(list.length)} writings',
                        style: KvlText.caption(12)
                            .copyWith(color: KvlColors.inkSoft),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Grid
              Expanded(
                child: assets.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: KvlColors.primary, strokeWidth: 2),
                  ),
                  error: (e, _) => Center(
                    child: Text('Could not load writings',
                        style: KvlText.body()
                            .copyWith(color: KvlColors.inkSoft)),
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return _EmptyBook(mh: mh);
                    }
                    return GridView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _WritingTile(
                        asset: list[i],
                        mantraId: mantraId,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _mantraName(Mantra m) => m.name.roman;
}

// ─────────────────────────────────────────────────────────────────────────────
// Single tile
// ─────────────────────────────────────────────────────────────────────────────

class _WritingTile extends ConsumerWidget {
  const _WritingTile({required this.asset, required this.mantraId});
  final HandwritingAsset asset;
  final String mantraId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showFull(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: KvlColors.primary.withValues(alpha: 0.18), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              File(asset.filePath!),
              fit: BoxFit.contain,
              errorBuilder: (_, err, _) => const Center(
                child: Icon(Icons.broken_image_outlined,
                    color: KvlColors.muted, size: 28),
              ),
            ),
          ),
        ),
        // Delete × button — top-right corner
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _confirmDelete(context, ref),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Writing?'),
        content: const Text(
          'This writing will be permanently removed from your book '
          'and the count will be reduced by 1.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Delete the handwriting asset (file + hive record)
    await ref.read(handwritingRepositoryProvider).delete(asset.id);

    // Decrement totalWritings on all programs for this mantra
    final profile = ref.read(activeProfileProvider).value;
    if (profile != null) {
      final programs = await ref
          .read(programRepositoryProvider)
          .listForProfile(profile.id);
      for (final p in programs.where((p) => p.mantraId == mantraId)) {
        await ref
            .read(programRepositoryProvider)
            .decrementWritings(p.id);
      }
    }

    // Refresh the book grid and any badge counts
    ref.invalidate(bookAssetsProvider(mantraId));
    ref.invalidate(programsForActiveProfileProvider);
  }

  void _showFull(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Image.file(
            File(asset.filePath!),
            fit: BoxFit.contain,
            errorBuilder: (_, err, _) => const SizedBox(
              height: 200,
              child: Center(
                child: Icon(Icons.broken_image_outlined,
                    color: KvlColors.muted, size: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyBook extends StatelessWidget {
  const _EmptyBook({required this.mh});
  final double mh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined,
                size: 56, color: KvlColors.muted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Your book is empty',
              style: KvlText.title(18)
                  .copyWith(color: KvlColors.inkSoft),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your accepted writings will appear here\nas a personal scripture collection.',
              style: KvlText.caption(13)
                  .copyWith(color: KvlColors.muted, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
