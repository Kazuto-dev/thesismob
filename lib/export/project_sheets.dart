import '../data/google_sheets_client.dart';
import '../data/project.dart';
import 'project_documents.dart';

/// The spreadsheet name for [project] in the user's Drive.
String projectSheetTitle(Project project) => 'BuildQuantify – ${project.name}';

String _percent(double value) =>
    '${value == value.roundToDouble() ? value.toInt() : value}%';

/// The project as three Google Sheets tabs: the bill of quantities, the
/// materials to buy and the budget.
List<SheetTab> projectSheetTabs(Project project, {DateTime? date}) {
  final day = (date ?? DateTime.now()).toIso8601String().substring(0, 10);
  final heading = <List<Object?>>[
    [project.name],
    [
      [
        if (project.client.isNotEmpty) 'Client: ${project.client}',
        if (project.location.isNotEmpty) 'Location: ${project.location}',
        'Date: $day',
      ].join('   '),
    ],
    [],
  ];

  final boq = boqRows(project);
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
      ['', 'Total materials', null, null, null, project.breakdown.materials],
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

  final materials = project.materials;
  final materialsHeader = heading.length;
  final materialsTab = (
    title: 'Materials',
    rows: <List<Object?>>[
      ...heading,
      ['Group', 'Material', 'Quantity', 'Unit', 'Unit cost (₱)', 'Amount (₱)'],
      for (final m in materials)
        [m.group.label, m.label, m.quantity, m.unit, m.unitPrice, m.amount],
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
      ['Labour', '${_percent(s.labourPct)} of materials'],
      for (final e in s.labourByTrade.entries)
        ['Labour, ${e.key}', '${_percent(e.value)} of materials'],
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

  return [boqTab, materialsTab, budgetTab];
}
