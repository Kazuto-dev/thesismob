import 'package:flutter/foundation.dart';

import '../materials/catalog.dart';
import '../materials/work_items.dart';
import 'custom_items.dart';
import 'estimate.dart';
import 'project.dart';

double _centavos(double value) => (value * 100).roundToDouble() / 100;

final _recomputed = Expando<List<EstimateWork>>();

/// The work [e] measures. Estimates saved before work items existed are
/// worked out again from their inputs, so their labour can still be priced
/// by crews; when that fails the list is empty.
List<EstimateWork> worksOf(Estimate e) {
  if (e.works.isNotEmpty) return e.works;
  final cached = _recomputed[e];
  if (cached != null) return cached;
  var works = const <EstimateWork>[];
  final spec = materialById(e.materialId);
  if (spec != null && e.inputs.isNotEmpty) {
    try {
      // Choices added to the calculator since take their defaults.
      final result = spec.calculate(e.inputs, {
        ...spec.initialChoices,
        ...e.choices,
      });
      works = [
        for (final w in result.works)
          if (w.quantity > 0) EstimateWork(w.key, w.quantity, effort: w.effort),
      ];
    } on Object {
      // Inputs from an older calculator; priced as a share of materials.
    }
  }
  _recomputed[e] = works;
  return works;
}

/// One material in a unit price analysis: an estimate's main material or
/// a companion, with the part of it that goes into one work item.
typedef MaterialPart = ({
  String label,
  double quantity,
  String unit,
  double unitPrice,
  double amount,
});

bool _isRebar(String key) => key.startsWith('rebar_') || key == 'tie_wire';

bool _isForm(String key) =>
    key.startsWith('plywood_') ||
    key.startsWith('marine_plywood_') ||
    key == 'coco_lumber' ||
    key == 'good_lumber' ||
    key == 'nails';

/// The work item each of [e]'s materials goes into: the one the
/// calculator named, bars and tie wire to the rebar, form materials to the
/// formwork, gravel bedding to the bedding, and the rest to the main work.
Map<String, List<MaterialPart>> allocateMaterials(
  Estimate e,
  List<EstimateWork> works,
) {
  final keys = {for (final w in works) w.key};
  final main = works.isEmpty ? '' : works.first.key;
  final parts = <String, List<MaterialPart>>{};
  void add(String work, MaterialPart part) =>
      parts.putIfAbsent(keys.contains(work) ? work : main, () => []).add(part);

  add(main, (
    label: e.label,
    quantity: e.quantity,
    unit: e.unit.labelFor(e.quantity),
    unitPrice: e.unitPrice,
    amount: e.total,
  ));
  for (final l in e.companions) {
    final work =
        l.work ??
        (_isRebar(l.itemKey) && keys.contains(Work.rebar)
            ? Work.rebar
            : _isForm(l.itemKey) && keys.contains(Work.formwork)
            ? Work.formwork
            : l.itemKey == 'gravel_bedding' && keys.contains(Work.gravelBedding)
            ? Work.gravelBedding
            : main);
    add(work, (
      label: l.label,
      quantity: l.quantity,
      unit: l.unit,
      unitPrice: l.unitPrice,
      amount: l.total,
    ));
  }
  return parts;
}

/// Labour and equipment for an estimate under [s].
typedef LabourCost = ({double labour, double equipment, double crewDays});

/// [e]'s labour and equipment: by crews when [s] says so and the work is
/// known, otherwise as the trade's share of its materials.
LabourCost labourOf(Estimate e, CostSettings s) {
  if (e.isCustom) {
    return (labour: e.quantity * e.labourRate, equipment: 0, crewDays: 0);
  }
  final trade = tradeOf(e);
  final works = s.labourMethod == LabourMethod.crews
      ? worksOf(e)
      : const <EstimateWork>[];
  final known = [
    for (final w in works)
      if (workItemByKey(w.key) case final item?) (w, item),
  ];
  if (known.isEmpty) {
    return (
      labour: e.grandTotal * s.labourFor(trade) / 100,
      equipment: 0,
      crewDays: 0,
    );
  }
  final rates = s.dailyRates;
  var labour = 0.0;
  var equipment = 0.0;
  var days = 0.0;
  for (final (w, item) in known) {
    final d = item.crewDays(
      w.quantity,
      effort: w.effort,
      productivity: s.productivityPct / 100,
    );
    days += d;
    labour += d * item.crew.labourPerDay(rates);
    equipment += d * item.crew.equipmentPerDay(rates);
  }
  return (labour: labour, equipment: equipment, crewDays: days);
}

/// One line of labour or equipment in a unit price analysis.
typedef ResourceLine = ({
  String label,
  double count,
  double days,
  double rate,
  double amount,
});

/// A detailed unit price analysis (DUPA) of one work item of one
/// estimate: what a unit of it costs in materials, labour and equipment,
/// and with the project's markups.
@immutable
class WorkAnalysis {
  const WorkAnalysis({
    required this.estimate,
    required this.work,
    required this.item,
    required this.materials,
    required this.labour,
    required this.equipment,
    required this.toolsPct,
    required this.markupPct,
    required this.vatPct,
  });

  final Estimate estimate;
  final EstimateWork work;

  /// The work item, or null for work this version does not know.
  final WorkItem? item;
  final List<MaterialPart> materials;
  final List<ResourceLine> labour;
  final List<ResourceLine> equipment;
  final double toolsPct;

  /// Contingency, overhead and profit together, on the direct cost.
  final double markupPct;
  final double vatPct;

  double get quantity => work.quantity;

  /// The work item's unit, or the estimate's own for work this version
  /// does not know.
  String get unit => item?.unit ?? estimate.unit.labelFor(work.quantity);

  /// The work item's description, or the estimate's label.
  String get description => item?.description ?? estimate.label;

  double get materialCost =>
      _centavos(materials.fold(0, (sum, m) => sum + m.amount));
  double get labourCost =>
      _centavos(labour.fold(0, (sum, l) => sum + l.amount));
  double get toolsCost => _centavos(labourCost * toolsPct / 100);
  double get equipmentCost =>
      _centavos(equipment.fold(0, (sum, l) => sum + l.amount));
  double get crewDays => labour.isEmpty ? 0 : labour.first.days;

  /// Materials, labour, minor tools and equipment.
  double get directCost =>
      _centavos(materialCost + labourCost + toolsCost + equipmentCost);
  double get markups => _centavos(directCost * markupPct / 100);
  double get vat => _centavos((directCost + markups) * vatPct / 100);
  double get totalCost => _centavos(directCost + markups + vat);

  double get unitCost => quantity <= 0 ? 0 : _centavos(directCost / quantity);
  double get unitPrice => quantity <= 0 ? 0 : _centavos(totalCost / quantity);
}

/// The unit price analyses of a project's estimates, one per work item;
/// estimates without known work become one analysis of their own with
/// labour as a share of materials.
List<WorkAnalysis> analyseProject(Project p) => [
  for (final e in p.items) ...analyseEstimate(e, p.costs),
];

List<WorkAnalysis> analyseEstimate(Estimate e, CostSettings s) {
  final rates = s.dailyRates;
  final markupPct = s.contingencyPct + s.overheadPct + s.profitPct;
  if (e.isCustom) {
    final labour = e.quantity * e.labourRate;
    return [
      WorkAnalysis(
        estimate: e,
        work: EstimateWork(customItemId, e.quantity),
        item: null,
        materials: [
          (
            label: e.isAllIn ? e.customKind.label : 'Materials',
            quantity: e.quantity,
            unit: e.unit.labelFor(e.quantity),
            unitPrice: e.unitPrice,
            amount: e.total,
          ),
        ],
        labour: [
          if (labour > 0)
            (
              label: 'Labour',
              count: e.quantity,
              days: 0,
              rate: e.labourRate,
              amount: _centavos(labour),
            ),
        ],
        equipment: const [],
        toolsPct: s.toolsPct,
        markupPct: markupPct,
        vatPct: s.vatPct,
      ),
    ];
  }
  final works = s.labourMethod == LabourMethod.crews
      ? worksOf(e)
      : const <EstimateWork>[];
  if (works.isEmpty || works.every((w) => workItemByKey(w.key) == null)) {
    // One line for the whole estimate, as in the percentage method.
    final share = labourOf(
      e,
      s.copyWith(labourMethod: LabourMethod.percent),
    ).labour;
    final own = worksOf(e);
    final measure = own.isEmpty ? null : own.first;
    return [
      WorkAnalysis(
        estimate: e,
        work: measure ?? EstimateWork('', e.quantity),
        item: measure == null ? null : workItemByKey(measure.key),
        materials: allocateMaterials(
          e,
          const [],
        ).values.expand((m) => m).toList(),
        labour: [
          (
            label: 'Labour, ${_pct(e, s)}% of materials',
            count: 1,
            days: 0,
            rate: share,
            amount: _centavos(share),
          ),
        ],
        equipment: const [],
        toolsPct: s.toolsPct,
        markupPct: markupPct,
        vatPct: s.vatPct,
      ),
    ];
  }
  final parts = allocateMaterials(e, works);
  return [
    for (final w in works)
      if (workItemByKey(w.key) case final item?)
        () {
          final days = item.crewDays(
            w.quantity,
            effort: w.effort,
            productivity: s.productivityPct / 100,
          );
          ResourceLine line(String key, double count) => (
            label: DailyRates.labels[key] ?? key,
            count: count,
            days: days,
            rate: rates[key] ?? 0,
            amount: _centavos(count * days * (rates[key] ?? 0)),
          );
          final crew = item.crew;
          return WorkAnalysis(
            estimate: e,
            work: w,
            item: item,
            materials: parts[w.key] ?? const [],
            labour: [
              if (crew.foreman > 0) line(DailyRates.foreman, crew.foreman),
              if (crew.skilled > 0) line(DailyRates.skilled, crew.skilled),
              if (crew.helpers > 0) line(DailyRates.helper, crew.helpers),
            ],
            equipment: [
              for (final MapEntry(:key, :value) in crew.equipment.entries)
                line(key, value),
            ],
            toolsPct: s.toolsPct,
            markupPct: markupPct,
            vatPct: s.vatPct,
          );
        }(),
  ];
}

String _pct(Estimate e, CostSettings s) {
  final v = s.labourFor(tradeOf(e));
  return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
