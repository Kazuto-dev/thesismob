import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/format.dart';
import '../data/boq.dart';
import '../data/contract_math.dart';
import '../data/project.dart';
import '../state/profile_controller.dart';

const _ink = PdfColor.fromInt(0xFF1C1917);
const _muted = PdfColor.fromInt(0xFF57534E);
const _line = PdfColor.fromInt(0xFFE4DED6);
const _band = PdfColor.fromInt(0xFFF1EEE9);
const _amber = PdfColor.fromInt(0xFFF59E0B);

String _pdfText(String text) => text.replaceAll('⅜', '3/8');
String _money(double v) => formatMoney(v).substring(1);

const _ones = [
  '',
  'One',
  'Two',
  'Three',
  'Four',
  'Five',
  'Six',
  'Seven',
  'Eight',
  'Nine',
  'Ten',
  'Eleven',
  'Twelve',
  'Thirteen',
  'Fourteen',
  'Fifteen',
  'Sixteen',
  'Seventeen',
  'Eighteen',
  'Nineteen',
];
const _tens = [
  '',
  '',
  'Twenty',
  'Thirty',
  'Forty',
  'Fifty',
  'Sixty',
  'Seventy',
  'Eighty',
  'Ninety',
];

String _below1000(int n) {
  final parts = <String>[];
  if (n >= 100) {
    parts.add('${_ones[n ~/ 100]} Hundred');
    n %= 100;
  }
  if (n >= 20) {
    parts.add(
      n % 10 == 0 ? _tens[n ~/ 10] : '${_tens[n ~/ 10]}-${_ones[n % 10]}',
    );
  } else if (n > 0) {
    parts.add(_ones[n]);
  }
  return parts.join(' ');
}

/// [amount] in words as written on Philippine quotations and checks:
/// "One Million Two Hundred Thousand Pesos and 50/100".
String pesosInWords(double amount) {
  final centavos = (amount * 100).round();
  var pesos = centavos ~/ 100;
  final cents = centavos % 100;
  if (pesos == 0) {
    return 'Zero Pesos and ${cents.toString().padLeft(2, '0')}/100';
  }
  final scales = ['', 'Thousand', 'Million', 'Billion'];
  final parts = <String>[];
  for (var i = 0; pesos > 0 && i < scales.length; i++) {
    final chunk = pesos % 1000;
    if (chunk > 0) {
      parts.insert(
        0,
        [_below1000(chunk), scales[i]].where((s) => s.isNotEmpty).join(' '),
      );
    }
    pesos ~/= 1000;
  }
  final words = '${parts.join(' ')} Pesos';
  return cents == 0
      ? '$words Only'
      : '$words and ${cents.toString().padLeft(2, '0')}/100';
}

Future<pw.Document> _document(String title) async {
  Future<pw.Font> font(String weight) async => pw.Font.ttf(
    await rootBundle.load('assets/fonts/jakarta/PlusJakartaSans-$weight.ttf'),
  );
  return pw.Document(
    title: title,
    author: 'BuildQuantify',
    theme: pw.ThemeData.withFont(
      base: await font('Regular'),
      bold: await font('Bold'),
    ),
  );
}

pw.Widget _cell(
  String text, {
  bool right = false,
  bool strong = false,
  PdfColor color = _ink,
}) => pw.Padding(
  padding: const pw.EdgeInsets.fromLTRB(4, 3, 4, 3),
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

pw.Widget _head(String text, {bool right = false}) => pw.Padding(
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

pw.Widget _heading(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
  child: pw.Text(
    text,
    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
  ),
);

pw.Widget _small(String text) =>
    pw.Text(_pdfText(text), style: const pw.TextStyle(fontSize: 9));

/// The business's name and details, or a plain title when there is no
/// profile.
pw.Widget _letterhead(BusinessProfile p, String title, String subtitle) =>
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(height: 4, color: _amber),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (p.name.isNotEmpty)
                    pw.Text(
                      _pdfText(p.name),
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  for (final line in [
                    p.address,
                    [p.phone, p.email].where((s) => s.isNotEmpty).join(' · '),
                    if (p.tin.isNotEmpty) 'TIN ${p.tin}',
                  ])
                    if (line.isNotEmpty)
                      pw.Text(
                        _pdfText(line),
                        style: const pw.TextStyle(fontSize: 8.5, color: _muted),
                      ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                pw.Text(
                  subtitle,
                  style: const pw.TextStyle(fontSize: 8.5, color: _muted),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
      ],
    );

pw.Widget _footer(pw.Context context) => pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [
    pw.Text(
      'Made with BuildQuantify',
      style: const pw.TextStyle(fontSize: 7, color: _muted),
    ),
    pw.Text(
      'Page ${context.pageNumber} of ${context.pagesCount}',
      style: const pw.TextStyle(fontSize: 7, color: _muted),
    ),
  ],
);

pw.Widget _signature(String role, String name) => pw.Expanded(
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(role, style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
      pw.SizedBox(height: 28),
      pw.Container(height: 0.6, color: _ink),
      pw.SizedBox(height: 3),
      pw.Text(
        _pdfText(name.isEmpty ? 'Signature over printed name' : name),
        style: const pw.TextStyle(fontSize: 8.5),
      ),
      pw.Text('Date:', style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
    ],
  ),
);

/// A quotation for the client: business details, the scope by trade, the
/// contract price in figures and words, payment terms, the schedule,
/// inclusions and exclusions, signature blocks and, at the back, the
/// priced bill of quantities.
Future<Uint8List> quotationPdf(
  Project project,
  BusinessProfile profile, {
  DateTime? date,
}) async {
  final today = date ?? DateTime.now();
  final doc = await _document('${project.name} quotation');
  final t = project.contract.terms;
  final lines = contractLines(project);
  final price = project.breakdown.total;
  final number =
      'Q-${today.toIso8601String().substring(0, 10).replaceAll('-', '')}-'
      '${project.id.hashCode.abs() % 1000}';
  final validUntil = today.add(Duration(days: t.validityDays.round()));
  final schedule = Schedule.of(project);
  final start = project.contract.startDate;

  // The price by section: trades A–E and general requirements F.
  final sections = <String, double>{};
  final names = {
    for (final (trade, letter) in tradeSections) letter: tradeLabel(trade),
    'F': 'General requirements',
  };
  for (final l in lines) {
    if (l.number.startsWith('VO')) continue;
    final letter = l.number.split('.').first;
    sections[letter] = (sections[letter] ?? 0) + l.amount;
  }

  List<String> items(String text) => [
    for (final line in text.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
  final inclusions = items(t.inclusions);
  final exclusions = items(t.exclusions);
  final vat = project.costs.vatPct;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
      footer: _footer,
      build: (context) => [
        _letterhead(profile, 'QUOTATION', 'No. $number'),
        pw.Wrap(
          spacing: 18,
          runSpacing: 2,
          children: [
            _small('Date: ${formatDate(today)}'),
            _small('Valid until: ${formatDate(validUntil)}'),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          _pdfText(project.name),
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        if (project.client.isNotEmpty) _small('Client: ${project.client}'),
        if (project.location.isNotEmpty)
          _small('Location: ${project.location}'),
        _heading('Scope and price'),
        pw.Table(
          columnWidths: const {
            0: pw.FixedColumnWidth(30),
            1: pw.FlexColumnWidth(),
            2: pw.FixedColumnWidth(100),
          },
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _line, width: 0.5),
          ),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _band),
              children: [
                _head(''),
                _head('Scope'),
                _head('Amount', right: true),
              ],
            ),
            for (final MapEntry(:key, :value) in sections.entries)
              pw.TableRow(
                children: [
                  _cell(key),
                  _cell(names[key] ?? key),
                  _cell(_money(value), right: true),
                ],
              ),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _band),
              children: [
                _cell(''),
                _cell(
                  vat > 0
                      ? 'Total contract price, VAT included'
                      : 'Total contract price',
                  strong: true,
                ),
                _cell(formatMoney(price), right: true, strong: true),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _pdfText(pesosInWords(price)),
          style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
        ),
        _heading('Payment terms'),
        for (final term in [
          if (t.downpaymentPct > 0)
            '${formatNumber(t.downpaymentPct)}% downpayment on signing '
                '(${formatMoney(price * t.downpaymentPct / 100)}), recouped '
                'from each progress billing.',
          'Progress billings for work done, as measured against the bill of '
              'quantities.',
          if (t.retentionPct > 0)
            '${formatNumber(t.retentionPct)}% of each billing retained and '
                'released on acceptance of the work'
                '${t.warrantyMonths > 0 ? ' or at the end of the warranty' : ''}.',
          if (t.warrantyMonths > 0)
            'Workmanship warranty of ${formatNumber(t.warrantyMonths)} months '
                'from turnover.',
        ])
          pw.Bullet(
            text: _pdfText(term),
            style: const pw.TextStyle(fontSize: 9),
          ),
        if (schedule.days > 0) ...[
          _heading('Schedule'),
          _small(
            'About ${schedule.weeks.ceil()} weeks '
            '(${formatNumber(schedule.days)} working days, Monday to Saturday)'
            '${start == null ? ' from the start of work' : ', from ${formatDate(start)} to about ${formatDate(Schedule.addWorkingDays(start, schedule.days))}'}.',
          ),
          pw.SizedBox(height: 4),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(),
              1: pw.FixedColumnWidth(90),
              2: pw.FixedColumnWidth(60),
              3: pw.FixedColumnWidth(60),
            },
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _line, width: 0.5),
            ),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _band),
                children: [
                  _head('Phase'),
                  _head('Trade'),
                  _head('From day', right: true),
                  _head('Days', right: true),
                ],
              ),
              for (final task in schedule.tasks)
                pw.TableRow(
                  children: [
                    _cell(task.label),
                    _cell(task.trade?.label ?? 'Other'),
                    _cell(formatNumber(task.start + 1), right: true),
                    _cell(formatNumber(task.days), right: true),
                  ],
                ),
            ],
          ),
        ],
        if (inclusions.isNotEmpty) ...[
          _heading('Inclusions'),
          for (final i in inclusions)
            pw.Bullet(
              text: _pdfText(i),
              style: const pw.TextStyle(fontSize: 9),
            ),
        ],
        if (exclusions.isNotEmpty) ...[
          _heading('Exclusions'),
          for (final e in exclusions)
            pw.Bullet(
              text: _pdfText(e),
              style: const pw.TextStyle(fontSize: 9),
            ),
        ],
        pw.SizedBox(height: 10),
        _small(
          'Quantities follow the bill of quantities attached. Work not '
          'listed, or changed at the client\'s request, is charged as a '
          'variation order.',
        ),
        pw.SizedBox(height: 24),
        pw.Row(
          children: [
            _signature('Prepared by', profile.preparedBy),
            pw.SizedBox(width: 36),
            _signature('Conforme', project.client),
          ],
        ),
        pw.NewPage(),
        _heading('Bill of quantities'),
        pw.Text(
          'Amounts include overhead, profit${vat > 0 ? ' and VAT' : ''}.',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          columnWidths: const {
            0: pw.FixedColumnWidth(34),
            1: pw.FlexColumnWidth(),
            2: pw.FixedColumnWidth(50),
            3: pw.FixedColumnWidth(32),
            4: pw.FixedColumnWidth(66),
            5: pw.FixedColumnWidth(76),
          },
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _line, width: 0.5),
          ),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _band),
              children: [
                _head('Item'),
                _head('Description'),
                _head('Qty', right: true),
                _head('Unit'),
                _head('Unit price', right: true),
                _head('Amount', right: true),
              ],
            ),
            for (final l in lines)
              if (!l.number.startsWith('VO'))
                pw.TableRow(
                  children: [
                    _cell(l.number),
                    _cell(l.description),
                    _cell(formatNumber(l.quantity), right: true),
                    _cell(l.unit),
                    _cell(
                      _money(l.quantity <= 0 ? 0 : l.amount / l.quantity),
                      right: true,
                    ),
                    _cell(_money(l.amount), right: true),
                  ],
                ),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _band),
              children: [
                _cell(''),
                _cell('Total', strong: true),
                _cell(''),
                _cell(''),
                _cell(''),
                _cell(formatMoney(price), right: true, strong: true),
              ],
            ),
          ],
        ),
      ],
    ),
  );
  return doc.save();
}

/// Progress billing [index]: the statement of account and the
/// accomplishment of each line.
Future<Uint8List> billingPdf(
  Project project,
  BusinessProfile profile,
  int index,
) async {
  final doc = await _document('${project.name} progress billing');
  final statements = billingStatements(project);
  final s = statements[index];
  final billing = project.contract.billings[index];
  final previous = index > 0 ? project.contract.billings[index - 1] : null;
  final lines = contractLines(project);
  final t = project.contract.terms;
  final original = project.breakdown.total;
  final variations = project.contract.variationsTotal;

  pw.TableRow money(String label, double amount, {bool strong = false}) =>
      pw.TableRow(
        decoration: strong ? const pw.BoxDecoration(color: _band) : null,
        children: [
          _cell(label, strong: strong),
          _cell(formatMoney(amount), right: true, strong: strong),
        ],
      );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
      footer: _footer,
      build: (context) => [
        _letterhead(
          profile,
          'PROGRESS BILLING',
          'No. ${s.number} · ${formatDate(s.date)}',
        ),
        pw.Text(
          _pdfText(project.name),
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        if (project.client.isNotEmpty) _small('Client: ${project.client}'),
        if (project.location.isNotEmpty)
          _small('Location: ${project.location}'),
        _heading('Statement'),
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(),
            1: pw.FixedColumnWidth(120),
          },
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _line, width: 0.5),
          ),
          children: [
            money('Original contract price', original),
            if (variations != 0) ...[
              money('Variation orders', variations),
              money('Revised contract price', original + variations),
            ],
            money(
              'Work accomplished to date, '
              '${formatNumber((s.percentComplete * 10).round() / 10)}%',
              s.toDate,
            ),
            money('Less previous billings', s.previous),
            money('This billing', s.thisPeriod, strong: true),
            if (s.recoupment > 0)
              money(
                'Less downpayment recouped, ${formatNumber(t.downpaymentPct)}%',
                -s.recoupment,
              ),
            if (s.retention > 0)
              money(
                'Less retention, ${formatNumber(t.retentionPct)}%',
                -s.retention,
              ),
            money('Amount due', s.netDue, strong: true),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _pdfText(pesosInWords(s.netDue)),
          style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
        ),
        _heading('Accomplishment'),
        pw.Table(
          columnWidths: const {
            0: pw.FixedColumnWidth(34),
            1: pw.FlexColumnWidth(),
            2: pw.FixedColumnWidth(72),
            3: pw.FixedColumnWidth(40),
            4: pw.FixedColumnWidth(40),
            5: pw.FixedColumnWidth(72),
          },
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _line, width: 0.5),
          ),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: _band),
              children: [
                _head('Item'),
                _head('Description'),
                _head('Contract', right: true),
                _head('Prev %', right: true),
                _head('To date %', right: true),
                _head('This billing', right: true),
              ],
            ),
            for (final l in lines)
              () {
                final now = billing.progress[l.key] ?? 0;
                final before = previous?.progress[l.key] ?? 0;
                return pw.TableRow(
                  children: [
                    _cell(l.number),
                    _cell(l.description),
                    _cell(_money(l.amount), right: true),
                    _cell(formatNumber(before), right: true),
                    _cell(formatNumber(now), right: true),
                    _cell(_money(l.amount * (now - before) / 100), right: true),
                  ],
                );
              }(),
          ],
        ),
        pw.SizedBox(height: 24),
        pw.Row(
          children: [
            _signature('Prepared by', profile.preparedBy),
            pw.SizedBox(width: 36),
            _signature('Received by', project.client),
          ],
        ),
      ],
    ),
  );
  return doc.save();
}
