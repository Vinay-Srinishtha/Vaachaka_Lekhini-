import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../enrolment/handwriting/domain/handwriting_asset.dart';

class WritingsPdfService {
  /// Returns path to the generated PDF.
  static Future<String> generate({
    required String profileId,
    required String mantraId,
    required String mantraName,
    required List<HandwritingAsset> assets,
  }) async {
    final doc = pw.Document();
    // 3 images per row, multiple pages
    const perPage = 9;
    for (var page = 0; page * perPage < assets.length; page++) {
      final slice = assets.skip(page * perPage).take(perPage).toList();
      // Build rows of 3
      final rows = <List<HandwritingAsset>>[];
      for (var i = 0; i < slice.length; i += 3) {
        rows.add(slice.skip(i).take(3).toList());
      }
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (page == 0) ...[
              pw.Text(
                'My Writing Book — $mantraName',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 12),
            ],
            ...rows.map((row) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Row(
                children: row.map((a) {
                  final bytes = File(a.filePath!).readAsBytesSync();
                  final img = pw.MemoryImage(bytes);
                  return pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                      child: pw.AspectRatio(
                        aspectRatio: 1,
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.orange200),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                          ),
                          child: pw.Image(img, fit: pw.BoxFit.contain),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )),
          ],
        ),
      ));
    }

    final docs = await getApplicationDocumentsDirectory();
    final path = p.join(docs.path, 'writing_book_${profileId}_$mantraId.pdf');
    final file = File(path);
    await file.writeAsBytes(await doc.save());
    return path;
  }

  static Future<String?> existingPath({
    required String profileId,
    required String mantraId,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final path = p.join(docs.path, 'writing_book_${profileId}_$mantraId.pdf');
    if (File(path).existsSync()) return path;
    return null;
  }
}
