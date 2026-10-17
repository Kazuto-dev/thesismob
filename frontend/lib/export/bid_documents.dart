import '../data/project.dart';
import '../data/quotes.dart';
import '../data/revisions.dart';
import 'project_documents.dart';

/// The title of the bill of quantities sent to bidders.
const bidBoqTitle = 'Bill of quantities for bidders';

BoqRow _row(
  String number,
  String description, {
  double? quantity,
  String unit = '',
  bool heading = false,
  bool subtotal = false,
}) => (
  number: number,
  description: description,
  quantity: quantity,
  unit: unit,
  unitPrice: null,
  amount: null,
  isHeading: heading,
  isSubtotal: subtotal,
);

/// The bill of quantities for bidders: the work items of [scope] (a
/// [BidScope] key) numbered as in the project's own bill, with their
/// quantities and units, and no prices. The whole job ends with the
/// general requirements; one trade has its own section only.
List<BoqRow> bidBoqRows(Project project, {String scope = wholeJob}) {
  final rows = <BoqRow>[];
  for (final section in workSections(project)) {
    if (scope != wholeJob && (section.trade?.name ?? 'other') != scope) {
      continue;
    }
    final label = tradeLabel(section.trade);
    rows.add(_row(section.letter, label.toUpperCase(), heading: true));
    for (final (:number, :analysis) in section.entries) {
      rows.add(
        _row(
          number,
          workDescription(analysis),
          quantity: analysis.quantity,
          unit: analysis.unit,
        ),
      );
    }
    rows.add(_row('', 'Subtotal, ${label.toLowerCase()}', subtotal: true));
  }
  final general = generalLines(project);
  if ((scope == wholeJob || scope == generalScope) && general.isNotEmpty) {
    rows.add(_row('F', 'GENERAL REQUIREMENTS', heading: true));
    for (final (i, g) in general.indexed) {
      rows.add(
        _row('F.${i + 1}', g.description, quantity: g.quantity, unit: g.unit),
      );
    }
    rows.add(_row('', 'Subtotal, general requirements', subtotal: true));
  }
  return rows;
}

/// How [scope] is named on the bill: "Whole job" or "C. Electrical works".
String bidScopeTitle(BidScope scope) =>
    scope.letter.isEmpty ? scope.label : '${scope.letter}. ${scope.label}';

/// Short instructions to bidders, printed above the bill.
List<String> bidInstructions(BidScope scope) => [
  'Write a unit price for every item and multiply it by the quantity for '
      'the amount. Add up the amounts for each subtotal and for the total '
      'bid price.',
  'Prices are in Philippine pesos and include materials, labour, tools, '
      'equipment, hauling, overhead, profit and VAT.',
  'Quantities are estimated from the plans. Price them as given, so every '
      'bid is compared on the same quantities, and list any you find '
      'different on a separate sheet.',
  'An item left without a price is taken as included in your other prices.',
  'State how long your prices hold and anything you leave out.',
  if (scope.key != wholeJob)
    'This bill covers ${scope.label.toLowerCase()} only.',
];

/// The lines a bidder fills in and signs at the end of the bill.
const bidderLines = [
  'Bidder',
  'Address and contact number',
  'Prices valid for (days)',
  'Signature over printed name',
  'Date of bid',
];

/// The file name of the bill for bidders, e.g. `santos-house-bid-boq` or
/// `santos-house-bid-boq-electrical`.
String bidFileSlug(Project project, String scope) =>
    fileSlug(project, scope == wholeJob ? 'bid-boq' : 'bid-boq-$scope');

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

/// The bill of quantities for bidders as CSV for Excel or Google Sheets:
/// project details, instructions, the items with empty unit price and
/// amount columns, a total line and the bidder's details to fill in.
String bidCsv(Project project, {String scope = wholeJob, DateTime? date}) {
  final s = bidScope(scope);
  final revision = revisionLabel(project);
  final lines = <List<Object?>>[
    [bidBoqTitle.toUpperCase()],
    ['Project', project.name],
    if (project.client.isNotEmpty) ['Client', project.client],
    if (project.location.isNotEmpty) ['Location', project.location],
    ['Scope', bidScopeTitle(s)],
    if (revision != null) ['Revision', revision],
    ['Date', (date ?? DateTime.now()).toIso8601String().substring(0, 10)],
    [],
    ['INSTRUCTIONS TO BIDDERS'],
    for (final (i, text) in bidInstructions(s).indexed) ['${i + 1}', text],
    [],
    [
      'Item',
      'Description',
      'Quantity',
      'Unit',
      'Unit price (PHP)',
      'Amount (PHP)',
    ],
    for (final r in bidBoqRows(project, scope: s.key))
      [r.number, r.description, r.quantity, r.unit],
    [],
    ['', 'TOTAL BID PRICE (PHP)'],
    [],
    for (final label in bidderLines) [label, ''],
  ];
  // A byte-order mark lets Excel read accents and signs.
  return '﻿${lines.map((r) => r.map(_csvCell).join(',')).join('\r\n')}';
}
