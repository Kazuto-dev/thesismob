import '../data/google_sheets_client.dart';
import '../data/project.dart';
import '../data/revisions.dart';
import '../materials/work_items.dart';
import 'project_documents.dart';

/// The spreadsheet name for [project] in the user's Drive.
String projectSheetTitle(Project project) => 'BuildQuantify – ${project.name}';

String _percent(double value) =>
    '${value == value.roundToDouble() ? value.toInt() : value}%';

/// The project as Google Sheets tabs: the bill of quantities, the unit
/// price analyses, the materials to buy (with the [suppliers] of the
/// user's prices, by item key) and the budget.
List<SheetTab> projectSheetTabs(
  Project project, {
  DateTime? date,
  Map<String, String> suppliers = const {},
}) {
  final day = (date ?? DateTime.now()).toIso8601String().substring(0, 10);
  final heading = <List<Object?>>[
    [project.name],
    [
      [
        if (project.client.isNotEmpty) 'Client: ${project.client}',
        if (project.location.isNotEmpty) 'Location: ${project.location}',
        if (revisionLabel(project) case final revision?) 'Revision: $revision',
        'Date: $day',
      ].join('   '),
    ],
    [],
  ];

  final boq = workBoqRows(project);
  final boqHeader = heading.length;
  final boqTab = (
    title: 'Bill of quantities',
    rows: <List<Object?>>[
      ...heading,
      [
        'Item',
        'Description',
        'Quantity',
        'Unit',
        'Unit cost (₱)',
        'Amount (₱)',
      ],
      for (final r in boq)
        [
          r.number,
          r.isHeading || r.number.isNotEmpty || r.isSubtotal
              ? r.description
              : '    ${r.description}',
          r.quantity,
          r.unit,
          r.unitPrice,
          r.amount,
        ],
      [],
      ['', 'Direct cost', null, null, null, project.breakdown.direct],
    ],
    headerRow: boqHeader,
    moneyColumns: const [4, 5],
    quantityColumns: const [2],
    boldRows: [
      for (final (i, r) in boq.indexed)
        if (r.isHeading || r.isSubtotal) boqHeader + 1 + i,
      boqHeader + boq.length + 2,
    ],
  );

  final dupa = dupaRows(project);
  final dupaHeader = heading.length;
  final dupaTab = (
    title: 'Unit price analysis',
    rows: <List<Object?>>[
      ...heading,
      ['Item', 'Description', 'Quantity', 'Unit', 'Rate (₱)', 'Amount (₱)'],
      for (final r in dupa)
        [r.number, r.description, r.quantity, r.unit, r.rate, r.amount],
    ],
    headerRow: dupaHeader,
    moneyColumns: const [4, 5],
    quantityColumns: const [2],
    boldRows: [
      for (final (i, r) in dupa.indexed)
        if (r.isHeading || r.isTotal) dupaHeader + 1 + i,
    ],
  );

  final materials = project.materials;
  final bySupplier = materials.any((m) => suppliers.containsKey(m.key));
  final materialsHeader = heading.length;
  final materialsTab = (
    title: 'Materials',
    rows: <List<Object?>>[
      ...heading,
      [
        'Group',
        'Material',
        'Quantity',
        'Unit',
        'Unit cost (₱)',
        'Amount (₱)',
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
      ['', 'Total', null, null, null, project.breakdown.materials],
    ],
    headerRow: materialsHeader,
    moneyColumns: const [4, 5],
    quantityColumns: const [2],
    boldRows: [materialsHeader + materials.length + 2],
  );

  final lines = costLines(project);
  final s = project.costs;
  final budgetHeader = heading.length;
  final budgetTab = (
    title: 'Budget',
    rows: <List<Object?>>[
      ...heading,
      ['Item', 'Amount (₱)'],
      for (final (label, amount, strong: _) in lines) [label, amount],
      [],
      ['Settings'],
      if (s.labourMethod == LabourMethod.crews) ...[
        ['Labour', 'By crew output, ${_percent(s.productivityPct)} pace'],
        for (final MapEntry(:key, :value) in s.dailyRates.entries)
          ['${DailyRates.labels[key] ?? key}, a day', value],
      ] else ...[
        ['Labour', '${_percent(s.labourPct)} of materials'],
        for (final e in s.labourByTrade.entries)
          ['Labour, ${e.key}', '${_percent(e.value)} of materials'],
      ],
      ['Minor tools', '${_percent(s.toolsPct)} of labour'],
      ['Contingency', _percent(s.contingencyPct)],
      ['Overhead (OCM)', _percent(s.overheadPct)],
      ['Profit', _percent(s.profitPct)],
      ['VAT', _percent(s.vatPct)],
    ],
    headerRow: budgetHeader,
    moneyColumns: const [1],
    quantityColumns: const <int>[],
    boldRows: [
      for (final (i, (_, _, strong: strong)) in lines.indexed)
        if (strong) budgetHeader + 1 + i,
      budgetHeader + lines.length + 2,
    ],
  );

  return [boqTab, dupaTab, materialsTab, budgetTab];
}
