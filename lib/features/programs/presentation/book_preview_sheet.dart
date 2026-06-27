import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/utils/indian_number_format.dart';
import '../../enrolment/handwriting/domain/handwriting_asset.dart';
import '../../home/domain/quote.dart';
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
          borderRadius: BorderRadius.circular(10),
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
    // Go directly to the book preview. Edit button inside opens the samples manager.
    Navigator.push(
      context,
      _BookDiveRoute(
        builder: (_) => _BookPreviewPage(mantraId: mantraId),
      ),
    );
  }

  /// Same as openSheet — kept for callers that pass a WidgetRef.
  static void openPage(BuildContext context, WidgetRef ref, String mantraId) =>
      openSheet(context, mantraId);
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



/// Load script pw.Font directly (preferred path — avoids ByteData roundtrip).
Future<pw.Font?> _loadScriptPwFont({
  required bool isTelugu,
  required bool isKannada,
}) async {
  try {
    if (isTelugu) {
      final data = await rootBundle.load('assets/fonts/Suravaram-Regular.ttf');
      return pw.Font.ttf(data);
    } else if (isKannada) {
      return await PdfGoogleFonts.tiroKannadaRegular();
    } else {
      return await PdfGoogleFonts.notoSansDevanagariRegular();
    }
  } catch (_) {
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permanent archive — writing PNGs stored immediately on accept
// ─────────────────────────────────────────────────────────────────────────────

Future<Directory> _archiveDir(String profileId, String mantraId) async {
  final base = await getApplicationDocumentsDirectory();
  final safe = (String s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  final dir = Directory(
      '${base.path}/pdf_archive/${safe(profileId)}/${safe(mantraId)}');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  return dir;
}

/// Call fire-and-forget from write_on_screen_screen after savePngCapped.
Future<void> archiveWritingSample({
  required String profileId,
  required String mantraId,
  required Uint8List bytes,
}) async {
  try {
    final dir = await _archiveDir(profileId, mantraId);
    final ts = DateTime.now().microsecondsSinceEpoch;
    await File('${dir.path}/$ts.png').writeAsBytes(bytes, flush: true);
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF generation
// ─────────────────────────────────────────────────────────────────────────────

Future<Uint8List> _buildLekhanaSheetPdf({
  required Profile? profile,
  required int totalProgress,
  required Mantra? mantra,
  required List<HandwritingAsset> assets,
  String? programName,
  Quote? quote,
  bool useWritingImages = true,
}) async {
  // ── Determine mantra script and display text ───────────────────────────────
  final bool isTelugu = mantra?.name.telugu?.isNotEmpty == true;
  final bool isKannada = !isTelugu && (mantra?.name.kannada?.isNotEmpty == true);
  final String mantraText = isTelugu
      ? mantra!.name.telugu!
      : isKannada
          ? mantra!.name.kannada!
          : (mantra?.name.devanagari ?? 'ॐ');

  // ── Load archive writing images (sorted by filename timestamp) ───────────
  // Voice chants + writing chants share the same total bucket; images are
  // scattered at seeded-random positions across ALL totalProgress cells.
  List<pw.MemoryImage> archiveImages = [];
  if (useWritingImages && profile != null && mantra != null) {
    try {
      final dir = await _archiveDir(profile.id, mantra.id);
      final pngFiles = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'))
          .toList()
        ..sort((a, b) {
          final ta = int.tryParse(a.uri.pathSegments.last.replaceAll('.png', '')) ?? 0;
          final tb = int.tryParse(b.uri.pathSegments.last.replaceAll('.png', '')) ?? 0;
          return ta.compareTo(tb);
        });
      for (final f in pngFiles) {
        try {
          archiveImages.add(pw.MemoryImage(await f.readAsBytes()));
        } catch (_) {}
      }
    } catch (_) {}
  }

  // ── Seeded-random cell map (stable across rebuilds) ───────────────────────
  // Pick imageCount random positions from totalForPdf cells using a seed that
  // is stable for this profile+mantra pair — so the layout never changes.
  final imageCount = archiveImages.length;
  final totalForPdf = math.max(totalProgress, 1);
  Map<int, pw.MemoryImage> cellImageMap = {};
  if (imageCount > 0) {
    final rng = math.Random(
      (profile?.id ?? '').hashCode ^ (mantra?.id ?? '').hashCode,
    );
    final allPositions = List<int>.generate(totalForPdf, (i) => i)
      ..shuffle(rng);
    final picked = allPositions.take(imageCount).toList()..sort();
    cellImageMap = {
      for (var i = 0; i < picked.length; i++) picked[i]: archiveImages[i]
    };
  }

  // ── Load bundle assets + script font in parallel ──────────────────────────
  final results = await Future.wait([
    rootBundle.load('assets/fonts/Suravaram-Regular.ttf'),       // [0]
    rootBundle.load('assets/app_icon.png'),                       // [1]
    rootBundle.load('assets/mantras/rama_quote_banner.png'),      // [2]
    _loadScriptPwFont(isTelugu: isTelugu, isKannada: isKannada), // [3]
  ]);

  final surFont = pw.Font.ttf(results[0] as ByteData);
  final logoImage = pw.MemoryImage((results[1] as ByteData).buffer.asUint8List());
  final wmImage = pw.MemoryImage((results[2] as ByteData).buffer.asUint8List());

  // Use the app-matching script font; fall back to Suravaram if unavailable.
  final scriptFont = (results[3] as pw.Font?) ?? surFont;

  // ── Profile data ───────────────────────────────────────────────────────────
  final name = profile?.name ?? '';
  final gothra = profile?.gothra ?? '';
  final address = () {
    final loc = profile?.location ?? '';
    if (loc.isNotEmpty) return loc;
    final addr = profile?.addresses.isNotEmpty == true ? profile!.addresses.first : null;
    if (addr == null) return '';
    if (addr.line1.trim().isNotEmpty) return addr.summary;
    return addr.state;
  }();

  // ── Box timestamps — derived from archive filenames (microsecond epoch) ──
  final dateFmt = DateFormat("dd-MM-yyyy , h:mma");
  String boxTimestamp(int boxIdx) {
    if (archiveImages.isEmpty) return '—';
    // Use the archive filename timestamps; cellImageMap tells us which image
    // landed in which cell, but a simpler heuristic is fine for the label.
    return dateFmt.format(DateTime.now()).toLowerCase();
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
                    programName: programName,
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
                          surFont: scriptFont,
                          cellImageMap: cellImageMap,
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
  String? programName,
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
              // Program name (if provided)
              if (programName != null && programName.isNotEmpty) ...[
                pw.RichText(
                  text: pw.TextSpan(children: [
                    pw.TextSpan(
                      text: 'Program : ',
                      style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                    ),
                    pw.TextSpan(
                      text: programName,
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _orange,
                      ),
                    ),
                  ]),
                ),
                pw.SizedBox(height: 3),
              ],
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
  required Map<int, pw.MemoryImage> cellImageMap,
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

            // Writing image at this exact cell position (seeded-random map)
            final img = cellImageMap[globalIdx];
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
  late final GoRouter _router;
  String? _openedOnLocation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router = GoRouter.of(context);
    _openedOnLocation ??= _router.state.uri.toString();
    _router.routerDelegate.addListener(_onRouteChange);
  }

  void _onRouteChange() {
    if (!mounted) return;
    final current = _router.state.uri.toString();
    if (current != _openedOnLocation) {
      Navigator.of(context, rootNavigator: false).maybePop();
    }
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_onRouteChange);
    super.dispose();
  }

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
                            _BookDiveRoute(
                              builder: (_) => _BookPreviewPage(mantraId: widget.mantraId),
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

class _BookPreviewPage extends ConsumerStatefulWidget {
  const _BookPreviewPage({required this.mantraId});
  final String mantraId;

  @override
  ConsumerState<_BookPreviewPage> createState() => _BookPreviewPageState();
}

class _BookPreviewPageState extends ConsumerState<_BookPreviewPage> {
  final _scoreCardKey = GlobalKey();
  bool _showHandwriting = true;

  // Regenerated whenever assets change.
  Future<Uint8List>? _pdfWritingFuture;
  Future<Uint8List>? _pdfDefaultFuture;
  List<HandwritingAsset> _knownAssets = [];

  String get mantraId => widget.mantraId;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _regeneratePdfs({
    required List<HandwritingAsset> assets,
    required int totalProgress,
    required Mantra? mantra,
    required Profile? profile,
  }) {
    _knownAssets = assets;
    _pdfWritingFuture = _buildLekhanaSheetPdf(
      profile: profile,
      totalProgress: totalProgress,
      mantra: mantra,
      assets: assets,
      programName: mantra?.name.roman,
      useWritingImages: true,
    );
    _pdfDefaultFuture = _buildLekhanaSheetPdf(
      profile: profile,
      totalProgress: totalProgress,
      mantra: mantra,
      assets: assets,
      programName: mantra?.name.roman,
      useWritingImages: false,
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _shareBook(BuildContext context, {
    required Mantra? mantra,
    required Profile? profile,
    required int totalProgress,
  }) async {
    final bytes = await _pdfWritingFuture;
    if (bytes == null) return;
    final mantraLabel = mantra?.name.roman ?? 'mantra';
    final name = profile?.name.trim();
    final greeting = (name != null && name.isNotEmpty) ? '$name has ' : 'I have ';
    final appLink = ref.read(appSettingsProvider).value?.effectiveAppLink ?? '';
    final message =
        '🙏 ${greeting}completed $totalProgress $mantraLabel chants & writings!\n\n'
        'Here is my Lekhana Book — a record of every chant written by hand.\n'
        'Jai Sri Rama! 🕉\n\n'
        '${appLink.isNotEmpty ? appLink : 'https://vaachakalekhini.com'}';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Lekhana_Sheet.pdf');
    await file.writeAsBytes(bytes);
    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        fileNameOverrides: ['Lekhana_Sheet.pdf'],
        text: message,
      ),
    );
  }

  void _openEditSamples(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSamplesSheet(mantraId: mantraId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mantra = ref.watch(mantraByIdProvider(mantraId));
    final profile = ref.watch(activeProfileProvider).value;
    final totalProgress = ref.watch(bookTotalForMantraProvider(mantraId));
    final assetsAsync = ref.watch(bookAssetsProvider(mantraId));
    final assets = assetsAsync.value ?? _knownAssets;

    // Regenerate PDFs whenever assets change.
    ref.listen(bookAssetsProvider(mantraId), (_, next) {
      if (next.hasValue && next.value != _knownAssets) {
        setState(() => _regeneratePdfs(
          assets: next.value!,
          totalProgress: totalProgress,
          mantra: mantra,
          profile: profile,
        ));
      }
    });

    // Initial PDF generation on first build once assets are available.
    if (_pdfWritingFuture == null) {
      _regeneratePdfs(
        assets: assets,
        totalProgress: totalProgress,
        mantra: mantra,
        profile: profile,
      );
    }

    final allPrograms = ref.watch(programsForActiveProfileProvider).value ?? [];
    final mantraPrograms = allPrograms.where((p) => p.mantraId == mantraId).toList();
    final completedPrograms = mantraPrograms.where((p) => p.isCompleted).length;
    final activePrograms = mantraPrograms.where((p) => !p.isCompleted).length;

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
                style: KvlText.title(16).copyWith(color: KvlColors.primaryDeep)),
            if (mantra != null)
              Text(mantra.name.roman,
                  style: KvlText.caption(11).copyWith(color: KvlColors.inkSoft)),
          ],
        ),
        actions: [
          // Edit samples button
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: KvlColors.primaryDeep, size: 20),
            tooltip: 'Edit samples',
            onPressed: () => _openEditSamples(context),
          ),
          // Toggle: original handwriting vs default font
          GestureDetector(
            onTap: () => setState(() => _showHandwriting = !_showHandwriting),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _showHandwriting
                    ? KvlColors.primaryDeep.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _showHandwriting
                      ? KvlColors.primaryDeep.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showHandwriting ? Icons.draw_rounded : Icons.text_fields_rounded,
                    size: 14,
                    color: _showHandwriting ? KvlColors.primaryDeep : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showHandwriting ? 'Original' : 'Default',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _showHandwriting ? KvlColors.primaryDeep : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Share
          IconButton(
            icon: const Icon(Icons.share_rounded, color: KvlColors.primaryDeep),
            tooltip: 'Share',
            onPressed: totalProgress == 0
                ? null
                : () => _shareBook(context, mantra: mantra, profile: profile, totalProgress: totalProgress),
          ),
        ],
      ),
      body: totalProgress == 0
          ? const _EmptyBook(mh: 600)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (mantraPrograms.isNotEmpty) ...[
                  RepaintBoundary(
                    key: _scoreCardKey,
                    child: _ScoreCard(
                      totalProgress: totalProgress,
                      programCount: mantraPrograms.length,
                      completed: completedPrograms,
                      active: activePrograms,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ...List.generate(
                  (totalProgress / 108).ceil(),
                  (boxIdx) {
                    final bool isTelugu = mantra?.name.telugu?.isNotEmpty == true;
                    final bool isKannada = !isTelugu && (mantra?.name.kannada?.isNotEmpty == true);
                    final String mantraText = isTelugu
                        ? mantra!.name.telugu!
                        : isKannada
                            ? mantra!.name.kannada!
                            : (mantra?.name.devanagari ?? 'ॐ');
                    return _BookPageBox(
                      boxIdx: boxIdx,
                      totalProgress: totalProgress,
                      assets: assets,
                      mantraId: mantraId,
                      mantraText: mantraText,
                      showHandwriting: _showHandwriting,
                    );
                  },
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Samples Sheet — manage / delete writing samples; book auto-updates
// ─────────────────────────────────────────────────────────────────────────────

class _EditSamplesSheet extends ConsumerWidget {
  const _EditSamplesSheet({required this.mantraId});
  final String mantraId;

  Future<void> _delete(BuildContext context, WidgetRef ref, HandwritingAsset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove writing?'),
        content: const Text('This sample will be removed from your book.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(handwritingRepositoryProvider).delete(asset.id);
    if (asset.filePath != null) {
      try { await File(asset.filePath!).delete(); } catch (_) {}
    }
    ref.invalidate(bookAssetsProvider(mantraId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(bookAssetsProvider(mantraId));
    final mantra = ref.watch(mantraByIdProvider(mantraId));

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
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: KvlColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, color: KvlColors.primaryDeep, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit Samples', style: KvlText.title(17)),
                          if (mantra != null)
                            Text(mantra.name.roman,
                                style: KvlText.caption(12).copyWith(color: KvlColors.inkSoft)),
                        ],
                      ),
                    ),
                    assets.when(
                      data: (list) => Text('${list.length} samples',
                          style: KvlText.caption(12).copyWith(color: KvlColors.inkSoft)),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: KvlColors.rule),
              Expanded(
                child: assets.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (list) {
                    if (list.isEmpty) {
                      return const Center(
                        child: Text('No writing samples yet.',
                            style: TextStyle(color: KvlColors.inkSoft)),
                      );
                    }
                    return GridView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final asset = list[i];
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: KvlColors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: .06),
                                    blurRadius: 6, offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: asset.filePath != null
                                          ? Image.file(File(asset.filePath!), fit: BoxFit.cover,
                                              width: double.infinity)
                                          : const Icon(Icons.broken_image_rounded,
                                              color: KvlColors.muted),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Text(
                                      DateFormat('dd/MM/yyyy').format(asset.createdAt),
                                      style: KvlText.caption(10).copyWith(color: KvlColors.inkSoft),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 6, right: 6,
                              child: GestureDetector(
                                onTap: () => _delete(context, ref, asset),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: .12),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.delete_rounded,
                                      color: Colors.red, size: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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
    required this.pdfWritingFuture,
    required this.pdfDefaultFuture,
    this.scoreCardKey,
    this.appLink,
  });

  final Profile? profile;
  final Mantra? mantra;
  final GlobalKey? scoreCardKey;
  final String? appLink;
  final List<HandwritingAsset> assets;
  final int totalProgress;
  final Future<Uint8List> pdfWritingFuture;
  final Future<Uint8List> pdfDefaultFuture;

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
            icon: Icons.draw_rounded,
            color: const Color(0xFF9B1C1C),
            title: 'Share with My Writing Style',
            subtitle: 'PDF with your handwritten samples in the grid',
            onTap: () {
              Navigator.pop(context);
              _shareBook(context, pdfWritingFuture);
            },
          ),
          const SizedBox(height: 12),
          _ShareOption(
            icon: Icons.auto_stories_rounded,
            color: const Color(0xFFD35400),
            title: 'Share with Default Font',
            subtitle: 'PDF with the mantra printed in script font',
            onTap: () {
              Navigator.pop(context);
              _shareBook(context, pdfDefaultFuture);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _shareBook(BuildContext context, Future<Uint8List> future) async {
    final bytes = await future;

    final mantraLabel = mantra?.name.roman ?? 'mantra';
    final name = profile?.name.trim();
    final greeting = (name != null && name.isNotEmpty) ? '$name has ' : 'I have ';
    final link = appLink?.isNotEmpty == true ? appLink! : 'https://vaachakalekhini.com';
    final message =
        '🙏 ${greeting}completed $totalProgress $mantraLabel chants & writings!\n\n'
        'Here is my Lekhana Book — a record of every chant written by hand.\n'
        'Jai Sri Rama! 🕉\n$link';

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Lekhana_Sheet.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        fileNameOverrides: ['Lekhana_Sheet.pdf'],
        text: message,
      ),
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
    required this.mantraText,
    this.showHandwriting = true,
  });

  final int boxIdx;
  final int totalProgress;
  final List<HandwritingAsset> assets;
  final String mantraId;
  final String mantraText;
  final bool showHandwriting;

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
                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Complete',
                      style: KvlText.caption(10).copyWith(
                        color: const Color(0xFF15803D),
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
                              mantraText: mantraText,
                              showHandwriting: showHandwriting,
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
    required String mantraText,
    required bool showHandwriting,
  }) {
    final cellIdx = row * _cols + col;
    final globalIdx = boxStart + cellIdx;

    if (cellIdx >= filledInBox) {
      return Positioned(
        left: col * cellW,
        top: row * cellH,
        width: cellW,
        height: cellH,
        child: const SizedBox.shrink(),
      );
    }

    // Filled — show writing image if available and toggle is on
    if (showHandwriting && assets.isNotEmpty) {
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
            errorBuilder: (_, __, ___) => _textCell(mantraText),
          ),
        );
      }
    }

    // No writing sample — show mantra script text
    return Positioned(
      left: col * cellW + 0.5,
      top: row * cellH + 0.5,
      width: cellW - 1,
      height: cellH - 1,
      child: _textCell(mantraText),
    );
  }

  Widget _textCell(String text) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: KvlColors.primaryDeep,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// "Dive inside the book" page transition
// ─────────────────────────────────────────────────────────────────────────────

class _BookDiveRoute<T> extends PageRouteBuilder<T> {
  _BookDiveRoute({required WidgetBuilder builder})
      : super(
          fullscreenDialog: true,
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scale = Tween<double>(begin: 0.06, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
            );
            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
              ),
            );
            final reverseFade = Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeOut,
              ),
            );
            return FadeTransition(
              opacity: reverseFade,
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(scale: scale, child: child),
              ),
            );
          },
        );
}
