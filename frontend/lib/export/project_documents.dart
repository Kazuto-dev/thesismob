import 'dart:convert';

import '../core/format.dart';
import '../data/estimate.dart';
import '../data/price_quote.dart';
import '../data/project.dart';
import '../data/boq.dart';
import '../data/revisions.dart';

export '../data/boq.dart';
import '../materials/items.dart';

/// One printed or exported row of the bill of quantities.
typedef BoqRow = ({
  String number,
  String description,
  double? quantity,
  String unit,
  double? unitPrice,
  double? amount,
  bool isHeading,
  bool isSubtotal,
});

BoqRow _row(
  String number,
  String description, {
  double? quantity,
  String unit = '',
  double? unitPrice,
  double? amount,
  bool heading = false,
  bool subtotal = false,
}) => (
  number: number,
  description: description,
  quantity: quantity,
  unit: unit,
  unitPrice: unitPrice,
  amount: amount,
  isHeading: heading,
  isSubtotal: subtotal,
);

/// The bill of quantities: each trade's estimates with their companion
/// materials, and a subtotal per trade.
List<BoqRow> boqRows(Project project) {
  final rows = <BoqRow>[];
  for (final g in groupByTrade(project.items)) {
    rows.add(_row(g.letter, tradeLabel(g.trade).toUpperCase(), heading: true));
    var subtotal = 0.0;
    for (final (i, e) in g.items.indexed) {
      rows.add(
        _row(
          '${g.letter}.${i + 1}',
          e.note == null ? e.title : '${e.title} (${e.note})',
          quantity: e.quantity,
          unit: e.unit.labelFor(e.quantity),
          unitPrice: e.unitPrice,
          amount: e.total,
        ),
      );
      for (final l in e.companions) {
        rows.add(
          _row(
            '',
            l.label,
            quantity: l.quantity,
            unit: l.unit,
            unitPrice: l.unitPrice,
            amount: l.total,
          ),
        );
      }
      subtotal += e.grandTotal;
    }
    rows.add(
      _row(
        '',
        'Subtotal, ${tradeLabel(g.trade).toLowerCase()}',
        amount: (subtotal * 100).roundToDouble() / 100,
        subtotal: true,
      ),
    );
  }
  return rows;
}

/// The bill of quantities by work item: each trade's work with its
/// quantity, direct unit cost and amount, then the general requirements.
/// Markups are added in the cost summary.
List<BoqRow> workBoqRows(Project project) {
  final rows = <BoqRow>[];
  for (final section in workSections(project)) {
    rows.add(
      _row(
        section.letter,
        tradeLabel(section.trade).toUpperCase(),
        heading: true,
      ),
    );
    var subtotal = 0.0;
    for (final (:number, :analysis) in section.entries) {
      final a = analysis;
      rows.add(
        _row(
          number,
          workDescription(a),
          quantity: a.quantity,
          unit: a.unit,
          unitPrice: a.unitCost,
          amount: a.directCost,
        ),
      );
      subtotal += a.directCost;
    }
    rows.add(
      _row(
        '',
        'Subtotal, ${tradeLabel(section.trade).toLowerCase()}',
        amount: (subtotal * 100).roundToDouble() / 100,
        subtotal: true,
      ),
    );
  }
  final general = generalLines(project);
  if (general.isNotEmpty) {
    rows.add(_row('F', 'GENERAL REQUIREMENTS', heading: true));
    for (final (i, g) in general.indexed) {
      rows.add(
        _row(
          'F.${i + 1}',
          g.description,
          quantity: g.quantity,
          unit: g.unit,
          unitPrice: g.unitPrice,
          amount: g.amount,
        ),
      );
    }
    rows.add(
      _row(
        '',
        'Subtotal, general requirements',
        amount:
            (general.fold<double>(0, (s, g) => s + g.amount) * 100)
                .roundToDouble() /
            100,
        subtotal: true,
      ),
    );
  }
  return rows;
}

/// One row of a unit price analysis table.
typedef DupaRow = ({
  String number,
  String description,
  double? quantity,
  String unit,
  double? rate,
  double? amount,
  bool isHeading,
  bool isTotal,
});

DupaRow _dupa(
  String description, {
  String number = '',
  double? quantity,
  String unit = '',
  double? rate,
  double? amount,
  bool heading = false,
  bool total = false,
}) => (
  number: number,
  description: description,
  quantity: quantity,
  unit: unit,
  rate: rate,
  amount: amount,
  isHeading: heading,
  isTotal: total,
);

/// The detailed unit price analysis of every work item, numbered as in
/// the bill of quantities.
List<DupaRow> dupaRows(Project project) {
  double r(double v) => (v * 100).roundToDouble() / 100;
  final rows = <DupaRow>[];
  for (final section in workSections(project)) {
    for (final (:number, :analysis) in section.entries) {
      final a = analysis;
      rows
        ..add(
          _dupa(
            workDescription(a),
            number: number,
            quantity: a.quantity,
            unit: a.unit,
            heading: true,
          ),
        )
        ..add(_dupa('Materials', amount: a.materialCost))
        ..addAll([
          for (final m in a.materials)
            _dupa(
              '  ${m.label}',
              quantity: m.quantity,
              unit: m.unit,
              rate: m.unitPrice,
              amount: m.amount,
            ),
        ])
        ..add(_dupa('Labour', amount: a.labourCost))
        ..addAll([
          for (final l in a.labour)
            l.days == 0
                ? _dupa('  ${l.label}', amount: l.amount)
                : _dupa(
                    '  ${l.label} × ${formatNumber(l.count)}',
                    quantity: r(l.count * l.days),
                    unit: 'days',
                    rate: l.rate,
                    amount: l.amount,
                  ),
        ]);
      if (a.toolsCost > 0) {
        rows.add(
          _dupa(
            'Minor tools, ${formatNumber(a.toolsPct)}% of labour',
            amount: a.toolsCost,
          ),
        );
      }
      if (a.equipmentCost > 0) {
        rows
          ..add(_dupa('Equipment', amount: a.equipmentCost))
          ..addAll([
            for (final l in a.equipment)
              _dupa(
                '  ${l.label}',
                quantity: r(l.count * l.days),
                unit: 'days',
                rate: l.rate,
                amount: l.amount,
              ),
          ]);
      }
      rows
        ..add(_dupa('Direct cost', amount: a.directCost, total: true))
        ..add(
          _dupa(
            'Direct cost per ${a.unit}',
            quantity: 1,
            unit: a.unit,
            amount: a.unitCost,
          ),
        );
      if (a.markupPct > 0 || a.vatPct > 0) {
        rows
          ..add(
            _dupa(
              'Contingency, overhead and profit, '
              '${formatNumber(a.markupPct)}%',
              amount: a.markups,
            ),
          )
          ..addAll([
            if (a.vat > 0)
              _dupa('VAT, ${formatNumber(a.vatPct)}%', amount: a.vat),
          ])
          ..add(
            _dupa(
              'Unit price per ${a.unit}',
              quantity: 1,
              unit: a.unit,
              amount: a.unitPrice,
              total: true,
            ),
          );
      }
    }
  }
  return rows;
}

/// The cost summary lines, from materials to the total.
List<(String, double, {bool strong})> costLines(Project project) {
  final b = project.breakdown;
  final s = project.costs;
  return [
    ('Materials', b.materials, strong: false),
    (
      s.labourMethod == LabourMethod.crews && b.crewDays > 0
          ? 'Labour, ${formatNumber((b.crewDays * 10).ceilToDouble() / 10)} '
                'crew-days'
          : 'Labour',
      b.labour,
      strong: false,
    ),
    if (b.tools > 0)
      (
        'Minor tools, ${formatNumber(s.toolsPct)}% of labour',
        b.tools,
        strong: false,
      ),
    if (b.equipment > 0) ('Equipment rental', b.equipment, strong: false),
    if (b.subcontracts > 0)
      ('Subcontracts and provisional sums', b.subcontracts, strong: false),
    if (b.hauling > 0) ('Hauling and delivery', b.hauling, strong: false),
    if (b.general > 0) ('General requirements', b.general, strong: false),
    ('Direct cost', b.direct, strong: true),
    if (b.escalation > 0)
      (
        'Price escalation, ${formatNumber(s.escalationPct)}%',
        b.escalation,
        strong: false,
      ),
    if (b.contingency > 0)
      (
        'Contingency, ${formatNumber(s.contingencyPct)}%',
        b.contingency,
        strong: false,
      ),
    if (b.overhead > 0)
      ('Overhead, ${formatNumber(s.overheadPct)}%', b.overhead, strong: false),
    if (b.profit > 0)
      ('Profit, ${formatNumber(s.profitPct)}%', b.profit, strong: false),
    if (b.vat > 0) ...[
      ('Subtotal before VAT', b.subtotal, strong: true),
      ('VAT, ${formatNumber(s.vatPct)}%', b.vat, strong: false),
    ],
    (
      s.isContractorBid ? 'Total contract price' : 'Project budget',
      b.total,
      strong: true,
    ),
  ];
}

String _csvCell(Object? value) {
  if (value == null) return '';
  final text = value is double
      ? (value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(2))
      : value.toString();
  return text.contains(RegExp('[",\n]'))
      ? '"${text.replaceAll('"', '""')}"'
      : text;
}

/// The project as CSV for Excel or Google Sheets: bill of quantities by
/// work item, unit price analyses, materials list and cost summary. The
/// materials list names the [suppliers] of the user's prices, by item key.
String projectCsv(Project project, {Map<String, String> suppliers = const {}}) {
  final materials = project.materials;
  final bySupplier = materials.any((m) => suppliers.containsKey(m.key));
  final lines = <List<Object?>>[
    ['Project', project.name],
    if (project.client.isNotEmpty) ['Client', project.client],
    if (project.location.isNotEmpty) ['Location', project.location],
    if (revisionLabel(project) case final revision?) ['Revision', revision],
    ['Date', DateTime.now().toIso8601String().substring(0, 10)],
    [],
    ['BILL OF QUANTITIES'],
    [
      'Item',
      'Description',
      'Quantity',
      'Unit',
      'Unit cost (PHP)',
      'Amount (PHP)',
    ],
    for (final r in workBoqRows(project))
      [r.number, r.description, r.quantity, r.unit, r.unitPrice, r.amount],
    [],
    ['UNIT PRICE ANALYSIS'],
    ['Item', 'Description', 'Quantity', 'Unit', 'Rate (PHP)', 'Amount (PHP)'],
    for (final r in dupaRows(project))
      [r.number, r.description, r.quantity, r.unit, r.rate, r.amount],
    [],
    ['MATERIALS LIST'],
    [
      'Group',
      'Material',
      'Quantity',
      'Unit',
      'Unit cost (PHP)',
      'Amount (PHP)',
      if (bySupplier) 'Supplier',
    ],
    for (final m in materials)
      [
        m.group.label,
        m.label,
        m.quantity,
        m.unit,
        m.unitPrice,
        m.amount,
        if (bySupplier) suppliers[m.key] ?? '',
      ],
    [],
    ['COST SUMMARY'],
    for (final (label, amount, strong: _) in costLines(project))
      [label, amount],
  ];
  // A byte-order mark lets Excel read the peso sign and accents.
  return '﻿${lines.map((r) => r.map(_csvCell).join(',')).join('\r\n')}';
}

/// The project as plain text, for a message or a note.
String projectText(Project project) {
  final b = StringBuffer('${project.name}\n');
  if (project.client.isNotEmpty) b.writeln('Client: ${project.client}');
  if (project.location.isNotEmpty) b.writeln('Location: ${project.location}');
  for (final g in groupByTrade(project.items)) {
    b.writeln('\n${tradeLabel(g.trade)}');
    for (final e in g.items) {
      b.writeln(
        '• ${e.title}: ${formatQuantity(e.quantity, e.unit)} × '
        '${formatMoney(e.unitPrice)} = ${formatMoney(e.total)}',
      );
      if (e.note != null) b.writeln('   ${e.note}');
      for (final l in e.companions) {
        b.writeln(
          '   – ${l.label}: ${formatNumber(l.quantity)} ${l.unit} = '
          '${formatMoney(l.total)}',
        );
      }
    }
  }
  b.writeln('\nShopping list');
  for (final m in project.materials) {
    b.writeln('• ${m.label}: ${formatNumber(m.quantity)} ${m.unit}');
  }
  b.writeln();
  for (final (label, amount, strong: _) in costLines(project)) {
    b.writeln('$label: ${formatMoney(amount)}');
  }
  b.write('\nPlanning estimate made with BuildQuantify.');
  return b.toString();
}

/// Everything the user has made, for a backup file. [quotes] are the
/// suppliers and quote dates of the user's prices.
String backupJson({
  required List<Project> projects,
  required Map<String, double> prices,
  required List<Estimate> history,
  Map<String, PriceQuote> quotes = const {},
}) => const JsonEncoder.withIndent(' ').convert({
  'app': 'BuildQuantify',
  'version': 1,
  'exportedAt': DateTime.now().toIso8601String(),
  'projects': [for (final p in projects) p.toJson()],
  'prices': prices,
  if (quotes.isNotEmpty)
    'priceQuotes': {
      for (final MapEntry(:key, :value) in quotes.entries) key: value.toJson(),
    },
  'history': [for (final e in history) e.toJson()],
});

/// What a backup file holds.
typedef Backup = ({
  List<Project> projects,
  Map<String, double> prices,
  Map<String, PriceQuote> quotes,
  List<Estimate> history,
});

/// Reads a backup file. Throws a [FormatException] with a message for the
/// user when the file is not a BuildQuantify backup.
Backup parseBackup(String text) {
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    throw const FormatException('That file is not a BuildQuantify backup.');
  }
  if (json is! Map || json['app'] != 'BuildQuantify') {
    throw const FormatException('That file is not a BuildQuantify backup.');
  }
  final projects = <Project>[];
  for (final p in json['projects'] as List? ?? const []) {
    if (p is Map<String, dynamic>) {
      try {
        projects.add(Project.fromJson(p));
      } on FormatException {
        // Skip a damaged project and keep the rest.
      }
    }
  }
  final history = <Estimate>[];
  for (final e in json['history'] as List? ?? const []) {
    if (e is Map<String, dynamic>) {
      try {
        history.add(Estimate.fromJson(e));
      } on FormatException {
        // Skip a damaged entry.
      }
    }
  }
  return (
    projects: projects,
    prices: {
      for (final e in (json['prices'] as Map? ?? const {}).entries)
        if (e.key is String &&
            itemByKey(e.key as String) != null &&
            e.value is num &&
            (e.value as num) >= 0)
          e.key as String: (e.value as num).toDouble(),
    },
    quotes: {
      for (final e in (json['priceQuotes'] as Map? ?? const {}).entries)
        if (PriceQuote.fromJson(e.value) case final q? when e.key is String)
          e.key as String: q,
    },
    history: history,
  );
}

/// A file name for [project]'s exports, e.g. `santos-house-boq`.
String fileSlug(Project project, String suffix) {
  final base = project.name
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return '${base.isEmpty ? 'project' : base}-$suffix';
}
