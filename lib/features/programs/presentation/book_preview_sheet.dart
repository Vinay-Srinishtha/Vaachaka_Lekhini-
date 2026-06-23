import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../app/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../enrolment/handwriting/domain/handwriting_asset.dart';
import '../../mantras/domain/mantra.dart';
import '../../profiles/domain/profile.dart';
import '../domain/program.dart';

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
// Lekhana Sheet PDF constants
// ─────────────────────────────────────────────────────────────────────────────

const _orange = PdfColor.fromInt(0xFFD35400);
const _orangeLight = PdfColor.fromInt(0xFFF0A070);
const _a4W = 595.28;
const _a4H = 841.89;
const _margin = 28.0;
const _contentW = _a4W - _margin * 2;
const _contentH = _a4H - _margin * 2;
const _headerH = 68.0;
const _footerH = 20.0;
const _boxGap = 8.0;
const _boxW = (_contentW - _boxGap) / 2;
const _boxH = (_contentH - _headerH - _footerH - _boxGap - 12) / 2;
const _labelH = 16.0;
const _gridH = _boxH - _labelH;
const _cellW = _boxW / 12;
const _cellH = _gridH / 9;

// ─────────────────────────────────────────────────────────────────────────────
// PDF generator
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _openLekhanaSheet({
  required BuildContext context,
  required Profile? profile,
  required Program? program,
  required Mantra? mantra,
  required List<HandwritingAsset> assets,
}) async {
  await Printing.layoutPdf(
    name: 'Lekhana_Sheet.pdf',
    onLayout: (_) => _buildLekhanaSheetPdf(
      profile: profile,
      program: program,
      mantra: mantra,
      assets: assets,
    ),
  );
}

Future<Uint8List> _buildLekhanaSheetPdf({
  required Profile? profile,
  required Program? program,
  required Mantra? mantra,
  required List<HandwritingAsset> assets,
}) async {
  // ── Fonts ──────────────────────────────────────────────────────────────────
  final surData = await rootBundle.load('assets/fonts/Suravaram-Regular.ttf');
  final surFont = pw.Font.ttf(surData);

  // ── Images ─────────────────────────────────────────────────────────────────
  final logoBytes =
      (await rootBundle.load('assets/app_icon.png')).buffer.asUint8List();
  final logoImage = pw.MemoryImage(logoBytes);

  final wmBytes =
      (await rootBundle.load('assets/mantras/rama_quote_banner.png'))
          .buffer
          .asUint8List();
  final wmImage = pw.MemoryImage(wmBytes);

  // ── Writing images ─────────────────────────────────────────────────────────
  final sortedAssets = [...assets]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final writingImages = <pw.MemoryImage?>[];
  for (final a in sortedAssets) {
    if (a.filePath != null) {
      try {
        final bytes = await File(a.filePath!).readAsBytes();
        writingImages.add(pw.MemoryImage(bytes));
      } catch (_) {
        writingImages.add(null);
      }
    } else {
      writingImages.add(null);
    }
  }

  // ── Profile data ───────────────────────────────────────────────────────────
  final name = profile?.name ?? '';
  final gothra = profile?.gothra ?? '';
  final address = profile?.location ?? '';
  final totalProgress = program?.totalProgress ?? 0;
  final totalForPdf = math.max(totalProgress, 1);

  // ── Mantra text ────────────────────────────────────────────────────────────
  final mantraText = (mantra?.name.telugu?.isNotEmpty == true)
      ? mantra!.name.telugu!
      : (mantra?.name.devanagari ?? 'ॐ');

  // ── Box timestamps ─────────────────────────────────────────────────────────
  final dateFmt = DateFormat('dd-MM-yyyy , h:mma');
  String boxTimestamp(int boxIdx) {
    if (sortedAssets.isEmpty) return '--';
    final assetIdx =
        math.min((boxIdx + 1) * 108 - 1, sortedAssets.length - 1);
    return dateFmt.format(sortedAssets[assetIdx].createdAt).toLowerCase();
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  final totalBoxes = (totalForPdf / 108).ceil();
  final totalPages = (totalBoxes / 4).ceil();

  // ── Build PDF ──────────────────────────────────────────────────────────────
  final pdf = pw.Document();

  for (var pageIdx = 0; pageIdx < totalPages; pageIdx++) {
    final boxStartOnPage = pageIdx * 4;

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) {
        // Boxes for this page
        final boxes = List.generate(
          4,
          (slot) {
            final boxIdx = boxStartOnPage + slot;
            return _buildBox(
              boxIdx: boxIdx,
              totalProgress: totalForPdf,
              mantraText: mantraText,
              surFont: surFont,
              writingImages: writingImages,
              timestamp: boxIdx < totalBoxes ? boxTimestamp(boxIdx) : '--',
            );
          },
        );

        return pw.Stack(
          children: [
            // Watermark
            pw.Positioned.fill(
              child: pw.Opacity(
                opacity: 0.07,
                child: pw.Image(wmImage, fit: pw.BoxFit.cover),
              ),
            ),
            // Content
            pw.Padding(
              padding: const pw.EdgeInsets.all(_margin),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(
                    name: name,
                    gothra: gothra,
                    address: address,
                    totalProgress: totalProgress,
                    logoImage: logoImage,
                  ),
                  pw.SizedBox(height: 10),
                  // Boxes — 2 × 2
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      boxes[0],
                      pw.SizedBox(width: _boxGap),
                      boxes[1],
                    ],
                  ),
                  pw.SizedBox(height: _boxGap),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      boxes[2],
                      pw.SizedBox(width: _boxGap),
                      boxes[3],
                    ],
                  ),
                  pw.Spacer(),
                  // Footer
                  pw.Center(
                    child: pw.Text(
                      'page no : ${(pageIdx + 1).toString().padLeft(2, '0')}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ));
  }

  return pdf.save();
}

pw.Widget _buildHeader({
  required String name,
  required String gothra,
  required String address,
  required int totalProgress,
  required pw.ImageProvider logoImage,
}) {
  final nameGothra = [name, if (gothra.isNotEmpty) gothra]
      .where((s) => s.isNotEmpty)
      .join(', ');

  return pw.Container(
    height: _headerH,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Left: devotee info
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Devotee Name & Gothram : ',
                      style: pw.TextStyle(fontSize: 9, color: _orange),
                    ),
                    pw.TextSpan(
                      text: nameGothra.isEmpty ? '—' : nameGothra,
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _orange),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Address : ',
                      style: pw.TextStyle(fontSize: 9, color: _orange),
                    ),
                    pw.TextSpan(
                      text: address.isEmpty ? '—' : address,
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _orange),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Total Chants Completed : $totalProgress',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
              ),
            ],
          ),
        ),
        // Right: logo + app name
        pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'powered by',
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
            ),
            pw.SizedBox(height: 3),
            pw.Image(logoImage, width: 32, height: 32),
            pw.SizedBox(height: 3),
            pw.Text(
              'Vaachika Lekhini',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _orange,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildBox({
  required int boxIdx,
  required int totalProgress,
  required String mantraText,
  required pw.Font surFont,
  required List<pw.MemoryImage?> writingImages,
  required String timestamp,
}) {
  final boxStart = boxIdx * 108;
  final filledCells = (totalProgress - boxStart).clamp(0, 108);

  return pw.Container(
    width: _boxW,
    height: _boxH,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _orange, width: 1.5),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // Date & Time label row
        pw.Container(
          height: _labelH,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: _orange, width: 0.5),
            ),
          ),
          child: pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              'Date & Time : $timestamp',
              style: pw.TextStyle(fontSize: 7),
            ),
          ),
        ),
        // 12 × 9 cell grid
        pw.SizedBox(
          width: _boxW,
          height: _gridH,
          child: pw.Table(
            columnWidths: {
              for (var i = 0; i < 12; i++) i: const pw.FixedColumnWidth(_cellW),
            },
            border: pw.TableBorder.all(
              color: _orangeLight,
              width: 0.3,
            ),
            children: List.generate(9, (row) {
              return pw.TableRow(
                children: List.generate(12, (col) {
                  final cellIdx = row * 12 + col;
                  final globalIdx = boxStart + cellIdx;

                  if (cellIdx >= filledCells) {
                    return pw.SizedBox(
                      width: _cellW,
                      height: _cellH,
                    );
                  }

                  // Try writing image first
                  if (writingImages.isNotEmpty) {
                    final img =
                        writingImages[globalIdx % writingImages.length];
                    if (img != null) {
                      return pw.SizedBox(
                        width: _cellW,
                        height: _cellH,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.all(0.5),
                          child: pw.Image(img, fit: pw.BoxFit.contain),
                        ),
                      );
                    }
                  }

                  // Fallback: Suravaram text
                  return pw.SizedBox(
                    width: _cellW,
                    height: _cellH,
                    child: pw.Center(
                      child: pw.Text(
                        mantraText,
                        style: pw.TextStyle(
                          font: surFont,
                          fontSize: 7,
                          color: PdfColors.black,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ],
    ),
  );
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
    final profile = ref.watch(activeProfileProvider).value;
    final programs = ref.watch(programsForActiveProfileProvider).value ?? [];
    final program = programs.where((p) => p.mantraId == mantraId).firstOrNull;
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
                      data: (list) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${IndianNumberFormat.format(list.length)} writings',
                            style: KvlText.caption(12)
                                .copyWith(color: KvlColors.inkSoft),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => _openLekhanaSheet(
                              context: context,
                              profile: profile,
                              program: program,
                              mantra: mantra,
                              assets: list,
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded,
                                size: 16),
                            label: const Text('Preview Book'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KvlColors.primaryDeep,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              textStyle:
                                  KvlText.ui(13, FontWeight.w700),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
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

    await ref.read(handwritingRepositoryProvider).delete(asset.id);

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
