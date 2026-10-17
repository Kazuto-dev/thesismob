import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/format.dart';
import '../data/project.dart';
import '../data/quotes.dart';
import '../data/revisions.dart';
import 'bid_documents.dart';

const _ink = PdfColor.fromInt(0xFF1C1917);
const _muted = PdfColor.fromInt(0xFF57534E);
const _line = PdfColor.fromInt(0xFFD6CFC5);
const _band = PdfColor.fromInt(0xFFF1EEE9);
const _amber = PdfColor.fromInt(0xFFF59E0B);

/// Plus Jakarta Sans has no ⅜ glyph.
String _pdfText(String text) => text.replaceAll('⅜', '3/8');

/// The bill of quantities for bidders as an A4 PDF: project details,
/// instructions, the work of [scope] with quantities and empty price
/// columns ruled for writing in, a total line and the bidder's signature
/// block.
Future<Uint8List> bidPdf(
  Project project, {
  String scope = wholeJob,
  DateTime? date,
}) async {
  Future<pw.Font> font(String weight) async => pw.Font.ttf(
    await rootBundle.load('assets/fonts/jakarta/PlusJakartaSans-$weight.ttf'),
  );
  final regular = await font('Regular');
  final bold = await font('Bold');
  final s = bidScope(scope);
  final doc = pw.Document(
    title: '${project.name} ${bidBoqTitle.toLowerCase()}',
    author: 'BuildQuantify',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  final today = formatDate(date ?? DateTime.now());
  final revision = revisionLabel(project);

  pw.Widget cell(
    String text, {
    bool right = false,
    bool strong = false,
    PdfColor color = _ink,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.fromLTRB(4, 5, 4, 5),
    child: pw.Text(
      _pdfText(text),
      textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: 8.5,
        color: color,
        fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  pw.Widget headerCell(String text, {bool right = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: pw.Text(
      text.toUpperCase(),
      textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: 7,
        color: _muted,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.4,
      ),
    ),
  );

  pw.Widget heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
    ),
  );

  const small = pw.TextStyle(fontSize: 9);

  final rows = bidBoqRows(project, scope: s.key);
  final table = pw.Table(
    columnWidths: const {
      0: pw.FixedColumnWidth(34),
      1: pw.FlexColumnWidth(),
      2: pw.FixedColumnWidth(52),
      3: pw.FixedColumnWidth(40),
      4: pw.FixedColumnWidth(74),
      5: pw.FixedColumnWidth(86),
    },
    border: pw.TableBorder.all(color: _line, width: 0.5),
    children: [
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: _band),
        children: [
          headerCell('Item'),
          headerCell('Description'),
          headerCell('Qty', right: true),
          headerCell('Unit'),
          headerCell('Unit price', right: true),
          headerCell('Amount', right: true),
        ],
      ),
      for (final r in rows)
        pw.TableRow(
          decoration: r.isSubtotal
              ? const pw.BoxDecoration(color: _band)
              : null,
          children: [
            cell(r.number, strong: r.isHeading),
            cell(r.description, strong: r.isHeading || r.isSubtotal),
            cell(
              r.quantity == null ? '' : formatNumber(r.quantity!),
              right: true,
            ),
            cell(r.unit),
            cell(''),
            cell(''),
          ],
        ),
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _band),
        children: [
          cell(''),
          cell('TOTAL BID PRICE (PHP)', strong: true),
          cell(''),
          cell(''),
          cell(''),
          cell(''),
        ],
      ),
    ],
  );

  final signature = pw.Table(
    columnWidths: const {0: pw.FixedColumnWidth(160), 1: pw.FlexColumnWidth()},
    children: [
      for (final label in bidderLines)
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 14, right: 8),
              child: pw.Text(label, style: small),
            ),
            pw.Container(
              height: 26,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: _muted, width: 0.5),
                ),
              ),
            ),
          ],
        ),
    ],
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                '${project.name} · ${bidBoqTitle.toLowerCase()} · '
                '${bidScopeTitle(s)}',
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Quantities from a BuildQuantify estimate. Bidders fill in the '
            'unit prices and amounts.',
            style: const pw.TextStyle(fontSize: 7, color: _muted),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: _muted),
          ),
        ],
      ),
      build: (context) => [
        pw.Container(height: 4, color: _amber),
        pw.SizedBox(height: 12),
        pw.Text(
          bidBoqTitle.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 9,
            color: _muted,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        pw.Text(
          project.name,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Wrap(
          spacing: 18,
          runSpacing: 2,
          children: [
            if (project.client.isNotEmpty)
              pw.Text('Client: ${project.client}', style: small),
            if (project.location.isNotEmpty)
              pw.Text('Location: ${project.location}', style: small),
            pw.Text('Scope: ${bidScopeTitle(s)}', style: small),
            if (revision != null) pw.Text('Revision: $revision', style: small),
            pw.Text('Date: $today', style: small),
          ],
        ),
        heading('Instructions to bidders'),
        for (final (i, text) in bidInstructions(s).indexed)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 14,
                  child: pw.Text('${i + 1}.', style: small),
                ),
                pw.Expanded(child: pw.Text(text, style: small)),
              ],
            ),
          ),
        heading('Bill of quantities'),
        table,
        // Kept on one page.
        pw.Container(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [heading('To be filled in by the bidder'), signature],
          ),
        ),
      ],
    ),
  );
  return doc.save();
}
