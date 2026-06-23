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

// ─────────────────────────────────────────────────────────────────────────────
// Providers
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

/// Aggregate total chants + writings across ALL programs (active & completed)
/// for a given mantra. This is the canonical "book total" displayed everywhere.
final bookTotalForMantraProvider =
    Provider.autoDispose.family<int, String>((ref, mantraId) {
  final programs = ref.watch(programsForActiveProfileProvider).value ?? [];
  return programs
      .where((p) => p.mantraId == mantraId)
      .fold(0, (sum, p) => sum + p.totalProgress);
});

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
    final total = ref.watch(bookTotalForMantraProvider(mantraId));

    return GestureDetector(
      onTap: () => openSheet(context, mantraId),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 13 : 16,
          vertical: compact ? 7 : 9,
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
              size: compact ? 16 : 18,
              color: KvlColors.primaryDeep,
            ),
            const SizedBox(width: 5),
            Text(
              'My Book',
              style: KvlText.ui(compact ? 13 : 14, FontWeight.w700)
                  .copyWith(color: KvlColors.primaryDeep),
            ),
            if (total > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: KvlColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  IndianNumberFormat.format(total),
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
// Lekhana Sheet PDF — layout constants (A4 portrait, 4 boxes stacked)
// ─────────────────────────────────────────────────────────────────────────────

const _orange = PdfColor.fromInt(0xFFD35400);
const _a4W = 595.28;
const _a4H = 841.89;
const _mH = 22.0; // horizontal margin
const _mV = 18.0; // vertical margin
const _contentW = _a4W - _mH * 2;   // 551.28
const _contentH = _a4H - _mV * 2;   // 805.89
const _headerH = 58.0;
const _footerH = 16.0;
const _dateLabelH = 13.0;
const _boxGap = 4.0;
// 4 boxes + 3 gaps + 4 date labels; remaining height split equally
const _gridH = (_contentH - _headerH - _footerH - 4 * _dateLabelH - 3 * _boxGap - 8) / 4;
const _cellW = _contentW / 12;
const _cellH = _gridH / 9;

// ─────────────────────────────────────────────────────────────────────────────
// PDF generator
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _openLekhanaSheet({
  required BuildContext context,
  required Profile? profile,
  required int totalProgress,
  required Mantra? mantra,
  required List<HandwritingAsset> assets,
}) async {
  final bytes = await _buildLekhanaSheetPdf(
    profile: profile,
    totalProgress: totalProgress,
    mantra: mantra,
    assets: assets,
  );
  await Printing.sharePdf(bytes: bytes, filename: 'Lekhana_Sheet.pdf');
}

Future<Uint8List> _buildLekhanaSheetPdf({
  required Profile? profile,
  required int totalProgress,
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
  final totalForPdf = math.max(totalProgress, 1);

  // ── Mantra text ────────────────────────────────────────────────────────────
  final mantraText = (mantra?.name.telugu?.isNotEmpty == true)
      ? mantra!.name.telugu!
      : (mantra?.name.devanagari ?? 'ॐ');

  // ── Box timestamps ─────────────────────────────────────────────────────────
  final dateFmt = DateFormat("dd-MM-yyyy , h:mma");
  String boxTimestamp(int boxIdx) {
    if (sortedAssets.isEmpty) return '—';
    final assetIdx =
        math.min((boxIdx + 1) * 108 - 1, sortedAssets.length - 1);
    return dateFmt.format(sortedAssets[assetIdx].createdAt).toLowerCase();
  }

  // ── Pagination — 4 boxes per page ──────────────────────────────────────────
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
        return pw.Stack(
          children: [
            // ── Full-page watermark ──────────────────────────────────────
            pw.Positioned.fill(
              child: pw.Opacity(
                opacity: 0.07,
                child: pw.Image(wmImage, fit: pw.BoxFit.cover),
              ),
            ),

            // ── Page content ─────────────────────────────────────────────
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: _mH, vertical: _mV),
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
                  pw.SizedBox(height: 6),

                  // 4 boxes stacked vertically
                  ...List.generate(4, (slot) {
                    final boxIdx = boxStartOnPage + slot;
                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        if (slot > 0) pw.SizedBox(height: _boxGap),
                        // "Date & Time" label — above the box
                        pw.Text(
                          'Date & Time : ${boxIdx < totalBoxes ? boxTimestamp(boxIdx) : "—"}...',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 1),
                        // Grid box
                        _buildGrid(
                          boxIdx: boxIdx,
                          totalProgress: totalForPdf,
                          mantraText: mantraText,
                          surFont: surFont,
                          writingImages: writingImages,
                        ),
                      ],
                    );
                  }),

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

  return pw.SizedBox(
    height: _headerH,
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Left: devotee details ──────────────────────────────────────────
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              // Name & Gothram on one line
              pw.RichText(
                text: pw.TextSpan(children: [
                  pw.TextSpan(
                    text: 'Devotee Name & Gothram : ',
                    style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                  ),
                  pw.TextSpan(
                    text: nameGothra.isEmpty ? '—' : nameGothra,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _orange,
                    ),
                  ),
                ]),
              ),
              pw.SizedBox(height: 3),
              // Address — centered
              pw.Center(
                child: pw.RichText(
                  text: pw.TextSpan(children: [
                    pw.TextSpan(
                      text: 'Address : ',
                      style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                    ),
                    pw.TextSpan(
                      text: address.isEmpty ? '—' : address,
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _orange,
                      ),
                    ),
                  ]),
                ),
              ),
              pw.SizedBox(height: 3),
              // Total chants
              pw.RichText(
                text: pw.TextSpan(children: [
                  pw.TextSpan(
                    text: 'Total Chants Completed : ',
                    style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                  ),
                  pw.TextSpan(
                    text: '$totalProgress',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),

        // ── Right: powered by + logo + QR + Vaachika Lekhini ──────────────
        pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'powered by',
              style: pw.TextStyle(fontSize: 6.5, color: PdfColors.grey500),
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Circular logo
                pw.ClipOval(
                  child: pw.SizedBox(
                    width: 36,
                    height: 36,
                    child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                  ),
                ),
                pw.SizedBox(width: 4),
                // QR code
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: 'https://vaachikalekhini.srinishtha.com',
                  width: 36,
                  height: 36,
                  drawText: false,
                ),
              ],
            ),
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

pw.Widget _buildGrid({
  required int boxIdx,
  required int totalProgress,
  required String mantraText,
  required pw.Font surFont,
  required List<pw.MemoryImage?> writingImages,
}) {
  final boxStart = boxIdx * 108;
  final filledCells = (totalProgress - boxStart).clamp(0, 108);

  return pw.SizedBox(
    width: _contentW,
    height: _gridH,
    child: pw.Table(
      columnWidths: {
        for (var i = 0; i < 12; i++) i: const pw.FixedColumnWidth(_cellW),
      },
      border: pw.TableBorder(
        // Solid orange outer border
        top: const pw.BorderSide(color: _orange, width: 1.2),
        bottom: const pw.BorderSide(color: _orange, width: 1.2),
        left: const pw.BorderSide(color: _orange, width: 1.2),
        right: const pw.BorderSide(color: _orange, width: 1.2),
        // Solid thin horizontal inner lines
        horizontalInside: const pw.BorderSide(color: _orange, width: 0.35),
        // Dashed thin vertical inner lines
        verticalInside: const pw.BorderSide(
          color: _orange,
          width: 0.35,
          style: pw.BorderStyle.dashed,
        ),
      ),
      children: List.generate(9, (row) {
        return pw.TableRow(
          children: List.generate(12, (col) {
            final cellIdx = row * 12 + col;
            final globalIdx = boxStart + cellIdx;

            if (cellIdx >= filledCells) {
              return pw.SizedBox(width: _cellW, height: _cellH);
            }

            // Writing image — cycle through available samples
            if (writingImages.isNotEmpty) {
              final img = writingImages[globalIdx % writingImages.length];
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

            // Fallback: Suravaram Telugu text
            return pw.SizedBox(
              width: _cellW,
              height: _cellH,
              child: pw.Center(
                child: pw.Text(
                  mantraText,
                  style: pw.TextStyle(
                    font: surFont,
                    fontSize: 7.5,
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
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet — Samples only; "Preview Book" is a button
// ─────────────────────────────────────────────────────────────────────────────

class _BookPreviewSheet extends ConsumerStatefulWidget {
  const _BookPreviewSheet({required this.mantraId});
  final String mantraId;

  @override
  ConsumerState<_BookPreviewSheet> createState() => _BookPreviewSheetState();
}

class _BookPreviewSheetState extends ConsumerState<_BookPreviewSheet> {
  Future<void> _deleteAsset(HandwritingAsset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove writing?'),
        content: const Text(
            'This sample will be removed from your book. Your count remains unchanged.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(handwritingRepositoryProvider).delete(asset.id);
    if (asset.filePath != null) {
      try {
        await File(asset.filePath!).delete();
      } catch (_) {}
    }
    ref.invalidate(bookAssetsProvider(widget.mantraId));
  }

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(bookAssetsProvider(widget.mantraId));
    final mantra = ref.watch(mantraByIdProvider(widget.mantraId));
    final profile = ref.watch(activeProfileProvider).value;
    final totalProgress =
        ref.watch(bookTotalForMantraProvider(widget.mantraId));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
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
              // Header row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        color: KvlColors.primaryDeep, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Writing Book', style: KvlText.title(17)),
                          if (mantra != null)
                            Text(
                              mantra.name.roman,
                              style: KvlText.caption(12)
                                  .copyWith(color: KvlColors.inkSoft),
                            ),
                        ],
                      ),
                    ),
                    // Preview Book button
                    assets.when(
                      data: (list) => _PreviewBookButton(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              fullscreenDialog: true,
                              builder: (_) => _BookPreviewPage(
                                mantraId: widget.mantraId,
                                mantra: mantra,
                                profile: profile,
                                assets: list,
                                totalProgress: totalProgress,
                              ),
                            ),
                          );
                        },
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // Samples label row
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      assets.when(
                        data: (l) => 'Writing Samples (${l.length})',
                        loading: () => 'Writing Samples',
                        error: (_, __) => 'Writing Samples',
                      ),
                      style: KvlText.ui(13, FontWeight.w700)
                          .copyWith(color: KvlColors.primaryDeep),
                    ),
                  ],
                ),
              ),
              const Divider(height: 12),

              // Samples grid
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
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.draw_outlined,
                                  size: 52,
                                  color:
                                      KvlColors.muted.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text('No writing samples yet',
                                  style: KvlText.title(17)
                                      .copyWith(color: KvlColors.inkSoft)),
                              const SizedBox(height: 8),
                              Text(
                                'Write on screen to add samples\nto your book.',
                                style: KvlText.caption(13).copyWith(
                                    color: KvlColors.muted, height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final sorted = [...list]
                      ..sort(
                          (a, b) => b.createdAt.compareTo(a.createdAt));
                    return GridView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: sorted.length,
                      itemBuilder: (_, i) => _SampleTile(
                        asset: sorted[i],
                        onDelete: () => _deleteAsset(sorted[i]),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// "Preview Book" pill button shown in the sheet header
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewBookButton extends StatelessWidget {
  const _PreviewBookButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD35400), Color(0xFFE67E22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD35400).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_stories_rounded,
                size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              'Preview Book',
              style: KvlText.ui(12, FontWeight.w700)
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen Book Preview page
// ─────────────────────────────────────────────────────────────────────────────

class _BookPreviewPage extends ConsumerWidget {
  const _BookPreviewPage({
    required this.mantraId,
    required this.mantra,
    required this.profile,
    required this.assets,
    required this.totalProgress,
  });

  final String mantraId;
  final Mantra? mantra;
  final Profile? profile;
  final List<HandwritingAsset> assets;
  final int totalProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPrograms =
        ref.watch(programsForActiveProfileProvider).value ?? [];
    final mantraPrograms =
        allPrograms.where((p) => p.mantraId == mantraId).toList();
    final completedPrograms =
        mantraPrograms.where((p) => p.isCompleted).length;
    final activePrograms =
        mantraPrograms.where((p) => !p.isCompleted).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF8F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: KvlColors.primaryDeep),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Writing Book',
                style: KvlText.title(16)
                    .copyWith(color: KvlColors.primaryDeep)),
            if (mantra != null)
              Text(mantra!.name.roman,
                  style: KvlText.caption(11)
                      .copyWith(color: KvlColors.inkSoft)),
          ],
        ),
        actions: [
          // Share button → bottom sheet with 3 options
          IconButton(
            icon: const Icon(Icons.share_rounded,
                color: KvlColors.primaryDeep),
            tooltip: 'Share',
            onPressed: totalProgress == 0
                ? null
                : () => _showShareSheet(context),
          ),
        ],
      ),
      body: totalProgress == 0
          ? const _EmptyBook(mh: 600)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // Score card
                if (mantraPrograms.isNotEmpty) ...[
                  _ScoreCard(
                    totalProgress: totalProgress,
                    programCount: mantraPrograms.length,
                    completed: completedPrograms,
                    active: activePrograms,
                  ),
                  const SizedBox(height: 16),
                ],
                // Book pages (boxes of 108)
                ...List.generate(
                  (totalProgress / 108).ceil(),
                  (boxIdx) => _BookPageBox(
                    boxIdx: boxIdx,
                    totalProgress: totalProgress,
                    assets: assets,
                    mantraId: mantraId,
                  ),
                ),
              ],
            ),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareOptionsSheet(
        profile: profile,
        mantra: mantra,
        assets: assets,
        totalProgress: totalProgress,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score card (extracted from old Tab 1)
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.totalProgress,
    required this.programCount,
    required this.completed,
    required this.active,
  });

  final int totalProgress;
  final int programCount;
  final int completed;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KvlColors.primaryDeep,
            KvlColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: KvlColors.primaryDeep.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Book Score',
                  style: KvlText.caption(11).copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  IndianNumberFormat.format(totalProgress),
                  style: KvlText.ui(32, FontWeight.w900)
                      .copyWith(color: Colors.white),
                ),
                Text(
                  'total chants & writings',
                  style: KvlText.caption(11).copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _ScoreStat(label: 'Programs', value: '$programCount'),
              const SizedBox(height: 6),
              _ScoreStat(label: 'Completed', value: '$completed'),
              const SizedBox(height: 6),
              _ScoreStat(label: 'Active', value: '$active'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share options bottom sheet — Hyperlink / App format / Book PDF
// ─────────────────────────────────────────────────────────────────────────────

class _ShareOptionsSheet extends StatelessWidget {
  const _ShareOptionsSheet({
    required this.profile,
    required this.mantra,
    required this.assets,
    required this.totalProgress,
  });

  final Profile? profile;
  final Mantra? mantra;
  final List<HandwritingAsset> assets;
  final int totalProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFDF8F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: KvlColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Share your book', style: KvlText.title(16)),
          const SizedBox(height: 4),
          Text(
            'Choose how you want to share',
            style:
                KvlText.caption(12).copyWith(color: KvlColors.inkSoft),
          ),
          const SizedBox(height: 20),
          _ShareOption(
            icon: Icons.picture_as_pdf_rounded,
            color: const Color(0xFFD35400),
            title: 'Share as Book (PDF)',
            subtitle: 'Generate & share the Lekhana Sheet PDF',
            onTap: () {
              Navigator.pop(context);
              _shareBook(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _shareBook(BuildContext context) async {
    await _openLekhanaSheet(
      context: context,
      profile: profile,
      totalProgress: totalProgress,
      mantra: mantra,
      assets: assets,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score card stat chip
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreStat extends StatelessWidget {
  const _ScoreStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: KvlText.caption(11)
              .copyWith(color: Colors.white.withValues(alpha: 0.7)),
        ),
        Text(
          value,
          style: KvlText.ui(12, FontWeight.w800).copyWith(color: Colors.white),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Book page box — one box = 108 cells (12 cols × 9 rows), like the PDF
// ─────────────────────────────────────────────────────────────────────────────

class _BookPageBox extends StatelessWidget {
  const _BookPageBox({
    required this.boxIdx,
    required this.totalProgress,
    required this.assets,
    required this.mantraId,
  });

  final int boxIdx;
  final int totalProgress;
  final List<HandwritingAsset> assets;
  final String mantraId;

  static const int _cols = 12;
  static const int _rows = 9;
  static const int _cellsPerBox = _cols * _rows; // 108

  @override
  Widget build(BuildContext context) {
    final boxStart = boxIdx * _cellsPerBox;
    final filledInBox = (totalProgress - boxStart).clamp(0, _cellsPerBox);
    final isComplete = filledInBox == _cellsPerBox;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page label
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text(
                  'Page ${boxIdx + 1}',
                  style: KvlText.ui(12, FontWeight.w700)
                      .copyWith(color: KvlColors.primaryDeep),
                ),
                const SizedBox(width: 8),
                Text(
                  '${boxStart + 1}–${boxStart + _cellsPerBox}',
                  style: KvlText.caption(11)
                      .copyWith(color: KvlColors.inkSoft),
                ),
                const Spacer(),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: KvlColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Complete',
                      style: KvlText.caption(10).copyWith(
                        color: KvlColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  Text(
                    '$filledInBox / $_cellsPerBox',
                    style: KvlText.caption(11)
                        .copyWith(color: KvlColors.inkSoft),
                  ),
              ],
            ),
          ),
          // Grid
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: KvlColors.primary.withValues(alpha: 0.5),
                  width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: AspectRatio(
                aspectRatio: _cols / _rows,
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final cellW = constraints.maxWidth / _cols;
                    final cellH = constraints.maxHeight / _rows;
                    return Stack(
                      children: [
                        // Grid lines
                        CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _GridPainter(
                              cols: _cols, rows: _rows),
                        ),
                        // Cells
                        for (var row = 0; row < _rows; row++)
                          for (var col = 0; col < _cols; col++)
                            _buildCell(
                              row: row,
                              col: col,
                              cellW: cellW,
                              cellH: cellH,
                              boxStart: boxStart,
                              filledInBox: filledInBox,
                            ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell({
    required int row,
    required int col,
    required double cellW,
    required double cellH,
    required int boxStart,
    required int filledInBox,
  }) {
    final cellIdx = row * _cols + col;
    final globalIdx = boxStart + cellIdx;

    if (cellIdx >= filledInBox) {
      // Empty cell
      return Positioned(
        left: col * cellW,
        top: row * cellH,
        width: cellW,
        height: cellH,
        child: const SizedBox.shrink(),
      );
    }

    // Filled cell — show writing image if available
    if (assets.isNotEmpty) {
      final asset = assets[globalIdx % assets.length];
      if (asset.filePath != null) {
        return Positioned(
          left: col * cellW + 0.5,
          top: row * cellH + 0.5,
          width: cellW - 1,
          height: cellH - 1,
          child: Image.file(
            File(asset.filePath!),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _filledCell(cellW, cellH),
          ),
        );
      }
    }

    return Positioned(
      left: col * cellW + 0.5,
      top: row * cellH + 0.5,
      width: cellW - 1,
      height: cellH - 1,
      child: _filledCell(cellW, cellH),
    );
  }

  Widget _filledCell(double w, double h) => Container(
        color: KvlColors.primary.withValues(alpha: 0.18),
      );
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.cols, required this.rows});
  final int cols;
  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD35400).withValues(alpha: 0.35)
      ..strokeWidth = 0.4;

    final cellW = size.width / cols;
    final cellH = size.height / rows;

    for (var c = 1; c < cols; c++) {
      final x = c * cellW;
      // dashed vertical lines
      var y = 0.0;
      while (y < size.height) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 2), paint);
        y += 4;
      }
    }
    for (var r = 1; r < rows; r++) {
      final y = r * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sample tile — single writing image card with delete button
// ─────────────────────────────────────────────────────────────────────────────

class _SampleTile extends StatelessWidget {
  const _SampleTile({required this.asset, required this.onDelete});
  final HandwritingAsset asset;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: KvlColors.primary.withValues(alpha: 0.3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: asset.filePath != null
                ? Image.file(
                    File(asset.filePath!),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.grey, size: 32),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.grey, size: 32),
                  ),
          ),
          // Delete button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: Colors.red),
              ),
            ),
          ),
          // Date label
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(11)),
              ),
              child: Text(
                _fmt(asset.createdAt),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share option row
// ─────────────────────────────────────────────────────────────────────────────

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: color.withValues(alpha: 0.25), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: KvlText.ui(14, FontWeight.w700)
                          .copyWith(color: KvlColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: KvlText.caption(11)
                          .copyWith(color: KvlColors.inkSoft)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: KvlColors.muted.withValues(alpha: 0.6), size: 20),
          ],
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
