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
    final allPrograms = ref.watch(programsForActiveProfileProvider).value ?? [];
    final mantraPrograms = allPrograms.where((p) => p.mantraId == mantraId).toList();
    final totalProgress = ref.watch(bookTotalForMantraProvider(mantraId));
    final completedPrograms = mantraPrograms.where((p) => p.isCompleted).length;
    final activePrograms = mantraPrograms.where((p) => !p.isCompleted).length;
    final mh = MediaQuery.sizeOf(context).height;

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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                              _mantraName(mantra),
                              style: KvlText.caption(12)
                                  .copyWith(color: KvlColors.inkSoft),
                            ),
                        ],
                      ),
                    ),
                    // Share / PDF button — always visible
                    assets.when(
                      data: (list) => IconButton(
                        onPressed: totalProgress == 0
                            ? null
                            : () => _openLekhanaSheet(
                                  context: context,
                                  profile: profile,
                                  totalProgress: totalProgress,
                                  mantra: mantra,
                                  assets: list,
                                ),
                        icon: const Icon(Icons.share_rounded),
                        color: KvlColors.primaryDeep,
                        tooltip: 'Share / Save PDF',
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // ── Complete Book Score card ───────────────────────────────────
              if (mantraPrograms.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
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
                        // Big count
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
                        // Program stats
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _ScoreStat(
                              label: 'Programs',
                              value: '${mantraPrograms.length}',
                            ),
                            const SizedBox(height: 6),
                            _ScoreStat(
                              label: 'Completed',
                              value: '$completedPrograms',
                            ),
                            const SizedBox(height: 6),
                            _ScoreStat(
                              label: 'Active',
                              value: '$activePrograms',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // ── PDF button ─────────────────────────────────────────────────
              if (totalProgress > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: assets.when(
                    data: (list) => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openLekhanaSheet(
                          context: context,
                          profile: profile,
                          totalProgress: totalProgress,
                          mantra: mantra,
                          assets: list,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                        label: const Text('Preview & Share Book PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KvlColors.primaryDeep,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          textStyle: KvlText.ui(14, FontWeight.w700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

              const Divider(height: 1),

              // ── Writing samples grid ───────────────────────────────────────
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
