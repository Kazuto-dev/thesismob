import 'dart:convert';

import '../core/format.dart';
import '../data/estimate.dart';
import '../data/project.dart';
import '../materials/catalog.dart';
import '../materials/items.dart';
import '../materials/material_spec.dart';

/// Trades in bill-of-quantities order, with their section letters.
const tradeSections = [
  (MaterialCategory.structural, 'A'),
  (MaterialCategory.architectural, 'B'),
  (MaterialCategory.electrical, 'C'),
  (MaterialCategory.plumbing, 'D'),
  (null, 'E'),
];

String tradeLabel(MaterialCategory? c) =>
    c == null ? 'Other works' : '${c.label} works';

/// A project's items grouped by trade, in bill-of-quantities order.
List<({MaterialCategory? trade, String letter, List<Estimate> items})>
groupByTrade(List<Estimate> items) => [
  for (final (trade, letter) in tradeSections)
    if (items.any((e) => materialById(e.materialId)?.category == trade))
      (
        trade: trade,
        letter: letter,
        items: [
          for (final e in items)
            if (materialById(e.materialId)?.category == trade) e,
        ],
      ),
];

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

/// The cost summary lines, from materials to the total.
List<(String, double, {bool strong})> costLines(Project project) {
  final b = project.breakdown;
  final s = project.costs;
  return [
    ('Materials', b.materials, strong: false),
    ('Labour', b.labour, strong: false),
    if (b.tools > 0)
      (
        'Minor tools, ${formatNumber(s.toolsPct)}% of labour',
        b.tools,
        strong: false,
      ),
    if (b.hauling > 0) ('Hauling and delivery', b.hauling, strong: false),
    ('Direct cost', b.direct, strong: true),
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

/// The project as CSV for Excel or Google Sheets: bill of quantities,
/// materials list and cost summary.
String projectCsv(Project project) {
  final lines = <List<Object?>>[
    ['Project', project.name],
    if (project.client.isNotEmpty) ['Client', project.client],
    if (project.location.isNotEmpty) ['Location', project.location],
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
    for (final r in boqRows(project))
      [r.number, r.description, r.quantity, r.unit, r.unitPrice, r.amount],
    [],
    ['MATERIALS LIST'],
    [
      'Group',
      'Material',
      'Quantity',
      'Unit',
      'Unit cost (PHP)',
      'Amount (PHP)',
    ],
    for (final m in project.materials)
      [m.group.label, m.label, m.quantity, m.unit, m.unitPrice, m.amount],
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

/// Everything the user has made, for a backup file.
String backupJson({
  required List<Project> projects,
  required Map<String, double> prices,
  required List<Estimate> history,
}) => const JsonEncoder.withIndent(' ').convert({
  'app': 'BuildQuantify',
  'version': 1,
  'exportedAt': DateTime.now().toIso8601String(),
  'projects': [for (final p in projects) p.toJson()],
  'prices': prices,
  'history': [for (final e in history) e.toJson()],
});

/// What a backup file holds.
typedef Backup = ({
  List<Project> projects,
  Map<String, double> prices,
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
