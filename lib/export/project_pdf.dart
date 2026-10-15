import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/format.dart';
import '../data/project.dart';
import 'project_documents.dart';

const _ink = PdfColor.fromInt(0xFF1C1917);
const _muted = PdfColor.fromInt(0xFF57534E);
const _line = PdfColor.fromInt(0xFFE4DED6);
const _band = PdfColor.fromInt(0xFFF1EEE9);
const _amber = PdfColor.fromInt(0xFFF59E0B);

String _qty(double? q) => q == null ? '' : formatNumber(q);

/// Plus Jakarta Sans has no ⅜ glyph.
String _pdfText(String text) => text.replaceAll('⅜', '3/8');
String _money(double? v) => v == null ? '' : formatMoney(v).substring(1);

/// The project's bill of quantities, materials list and cost summary as an
/// A4 PDF, ready to print or send to a client or supplier.
Future<Uint8List> projectPdf(Project project, {DateTime? date}) async {
  Future<pw.Font> font(String weight) async => pw.Font.ttf(
    await rootBundle.load('assets/fonts/jakarta/PlusJakartaSans-$weight.ttf'),
  );
  final regular = await font('Regular');
  final bold = await font('Bold');
  final doc = pw.Document(
    title: '${project.name} bill of quantities',
    author: 'BuildQuantify',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  final today = formatDate(date ?? DateTime.now());

  pw.Widget cell(
    String text, {
    bool right = false,
    bool strong = false,
    double indent = 0,
    PdfColor color = _ink,
  }) => pw.Padding(
    padding: pw.EdgeInsets.fromLTRB(4 + indent, 3, 4, 3),
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

  pw.Widget headerRowCell(String text, {bool right = false}) => pw.Padding(
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

  const widths = {
    0: pw.FixedColumnWidth(34),
    1: pw.FlexColumnWidth(),
    2: pw.FixedColumnWidth(52),
    3: pw.FixedColumnWidth(42),
    4: pw.FixedColumnWidth(62),
    5: pw.FixedColumnWidth(72),
  };

  pw.TableRow header(String first) => pw.TableRow(
    decoration: const pw.BoxDecoration(color: _band),
    children: [
      headerRowCell(first),
      headerRowCell('Description'),
      headerRowCell('Qty', right: true),
      headerRowCell('Unit'),
      headerRowCell('Unit cost', right: true),
      headerRowCell('Amount', right: true),
    ],
  );

  final boq = pw.Table(
    columnWidths: widths,
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: _line, width: 0.5),
    ),
    children: [
      header('Item'),
      for (final r in workBoqRows(project))
        if (r.isHeading)
          pw.TableRow(
            children: [
              cell(r.number, strong: true),
              cell(r.description, strong: true),
              cell(''),
              cell(''),
              cell(''),
              cell(''),
            ],
          )
        else
          pw.TableRow(
            decoration: r.isSubtotal
                ? const pw.BoxDecoration(color: _band)
                : null,
            children: [
              cell(r.number),
              cell(
                r.description,
                strong: r.isSubtotal,
                indent: r.number.isEmpty && !r.isSubtotal ? 10 : 0,
                color: r.number.isEmpty && !r.isSubtotal ? _muted : _ink,
              ),
              cell(_qty(r.quantity), right: true),
              cell(r.unit),
              cell(_money(r.unitPrice), right: true),
              cell(_money(r.amount), right: true, strong: r.isSubtotal),
            ],
          ),
    ],
  );

  final dupa = pw.Table(
    columnWidths: widths,
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: _line, width: 0.5),
    ),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _band),
        children: [
          headerRowCell('Item'),
          headerRowCell('Description'),
          headerRowCell('Qty', right: true),
          headerRowCell('Unit'),
          headerRowCell('Rate', right: true),
          headerRowCell('Amount', right: true),
        ],
      ),
      for (final r in dupaRows(project))
        pw.TableRow(
          decoration: r.isHeading || r.isTotal
              ? const pw.BoxDecoration(color: _band)
              : null,
          children: [
            cell(r.number, strong: r.isHeading),
            cell(
              r.description.trimLeft(),
              strong: r.isHeading || r.isTotal,
              indent: r.description.startsWith('  ') ? 10 : 0,
              color: r.description.startsWith('  ') ? _muted : _ink,
            ),
            cell(_qty(r.quantity), right: true),
            cell(r.unit),
            cell(_money(r.rate), right: true),
            cell(_money(r.amount), right: true, strong: r.isTotal),
          ],
        ),
    ],
  );

  final materials = project.materials;
  final materialTable = pw.Table(
    columnWidths: widths,
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: _line, width: 0.5),
    ),
    children: [
      header('No.'),
      for (final (i, m) in materials.indexed)
        pw.TableRow(
          children: [
            cell('${i + 1}'),
            cell(m.label),
            cell(_qty(m.quantity), right: true),
            cell(m.unit),
            cell(_money(m.unitPrice), right: true),
            cell(_money(m.amount), right: true),
          ],
        ),
    ],
  );

  final summary = pw.Table(
    columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.FixedColumnWidth(110)},
    border: const pw.TableBorder(
      horizontalInside: pw.BorderSide(color: _line, width: 0.5),
    ),
    children: [
      for (final (label, amount, strong: strong) in costLines(project))
        pw.TableRow(
          decoration: strong ? const pw.BoxDecoration(color: _band) : null,
          children: [
            cell(label, strong: strong),
            cell(formatMoney(amount), right: true, strong: strong),
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
                '${project.name} · bill of quantities',
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Planning estimate made with BuildQuantify. Confirm quantities '
            'and prices before buying.',
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
          'BILL OF QUANTITIES',
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
          children: [
            if (project.client.isNotEmpty)
              pw.Text(
                'Client: ${project.client}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            if (project.location.isNotEmpty)
              pw.Text(
                'Location: ${project.location}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            pw.Text('Date: $today', style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        heading('Cost summary'),
        summary,
        heading('Bill of quantities'),
        pw.Text(
          'Unit costs are direct costs: materials, labour, tools and '
          'equipment. Markups and VAT are in the cost summary.',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
        pw.SizedBox(height: 4),
        boq,
        heading('Materials to buy'),
        materialTable,
        pw.NewPage(),
        heading('Unit price analysis'),
        pw.Text(
          'Each work item\'s materials, crew and equipment for its measured '
          'quantity. Crew-days follow usual daily outputs at '
          '${formatNumber(project.costs.productivityPct)}% pace.',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
        pw.SizedBox(height: 4),
        dupa,
      ],
    ),
  );
  return doc.save();
}
