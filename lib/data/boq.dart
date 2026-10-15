import '../materials/catalog.dart';
import '../materials/material_spec.dart';
import 'estimate.dart';
import 'project.dart';
import 'unit_prices.dart';

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

/// A project's work in bill of quantities order: by trade, each
/// estimate's work items numbered A.1, A.2…
List<
  ({
    String letter,
    MaterialCategory? trade,
    List<({String number, WorkAnalysis analysis})> entries,
  })
>
workSections(Project project) => [
  for (final g in groupByTrade(project.items))
    (
      letter: g.letter,
      trade: g.trade,
      entries: [
        for (final (i, a) in [
          for (final e in g.items) ...analyseEstimate(e, project.costs),
        ].indexed)
          (number: '${g.letter}.${i + 1}', analysis: a),
      ],
    ),
];

/// The description of an analysed work item in a bill of quantities,
/// naming the estimate it came from.
String workDescription(WorkAnalysis a) {
  final title = a.estimate.title;
  final base = a.item == null ? title : '${a.description} ($title)';
  return a.estimate.note == null ? base : '$base. ${a.estimate.note}';
}
