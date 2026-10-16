import 'dart:math' as math;

import '../core/format.dart';
import 'items.dart';
import 'material_spec.dart';

/// Rounds a count up while ignoring floating-point noise, so that
/// 30 / 0.08 = 375.00000000000006 counts as 375, not 376.
int ceilCount(double value) => (value - 1e-9).ceil();

/// Rounds [value] up to [decimals] places, ignoring floating-point noise.
double roundUp(double value, [int decimals = 2]) {
  final factor = math.pow(10, decimals).toDouble();
  return ceilCount(value * factor) / factor;
}

/// A base count plus a waste allowance rounded up separately.
({int base, int extra, int total}) withWaste(int base, double waste) {
  final extra = waste == 0 ? 0 : ceilCount(base * waste);
  return (base: base, extra: extra, total: base + extra);
}

/// Extra pieces for cutting waste and breakage, as a share of the count.
ChoiceField wasteField({
  String initial = '5',
  String helper = 'Extra for cutting waste and breakage',
  List<int> percents = const [0, 5, 10, 15],
}) => ChoiceField(
  id: 'waste',
  label: 'Waste allowance',
  initial: initial,
  helper: helper,
  options: [
    for (final p in percents)
      ChoiceOption(p == 0 ? 'none' : '$p', p == 0 ? 'None' : '$p%', p / 100),
  ],
);

/// The breakdown line for a waste allowance, or nothing when there is none.
List<ResultDetail> wasteDetail(
  ({int base, int extra, int total}) count,
  double waste,
  QuantityUnit unit,
) => [
  if (count.extra > 0)
    ResultDetail(
      'Waste allowance (${formatPercent(waste)})',
      '+${formatQuantity(count.extra.toDouble(), unit)}',
    ),
];

/// Option id used by descriptive choices that do not change the quantity.
const notSpecified = 'any';

/// A choice that describes the item without changing the cost.
ChoiceField descriptor(
  String id,
  String label,
  List<(String, String)> options, {
  String? helper,
}) => ChoiceField(
  id: id,
  label: label,
  helper: helper,
  initial: notSpecified,
  options: [
    const ChoiceOption(notSpecified, 'Any'),
    for (final (oid, olabel) in options) ChoiceOption(oid, olabel),
  ],
);

/// Joins the parts of a summary label, skipping options left unspecified.
String describe(String base, Iterable<ChoiceOption?> parts) {
  final extra = [
    for (final p in parts)
      if (p != null && p.id != notSpecified) p.label,
  ];
  return extra.isEmpty ? base : '$base, ${extra.join(', ')}';
}

/// Area of doors and windows left out of a wall.
const openingsField = NumberField(
  id: 'openings',
  label: 'Doors and windows',
  unit: 'm²',
  hint: 'Optional. Area to leave out, about 2 m² per door',
  optional: true,
  max: 100000,
);

/// How a rafter length was measured. The value is the factor that turns
/// it into the length along the slope: √(1 + (rise ÷ run)²).
const slopeField = ChoiceField(
  id: 'measured',
  label: 'Rafter length measured',
  initial: 'slope',
  helper:
      'Along the roof surface, or on the floor plan with the roof pitch '
      '(rise per 12 of run)',
  options: [
    ChoiceOption('slope', 'Along the slope', 1),
    ChoiceOption('3', 'Plan, 3:12', 1.0308),
    ChoiceOption('4', 'Plan, 4:12', 1.0541),
    ChoiceOption('6', 'Plan, 6:12', 1.1180),
    ChoiceOption('8', 'Plan, 8:12', 1.2019),
    ChoiceOption('12', 'Plan, 12:12', 1.4142),
  ],
);

/// Number of roof planes: one for a shed roof, two for a gable.
const sidesField = ChoiceField(
  id: 'sides',
  label: 'Roof sides',
  initial: '2',
  helper: 'A shed roof has one side, a gable roof two',
  options: [ChoiceOption('1', '1 side', 1), ChoiceOption('2', '2 sides', 2)],
);

/// How a companion reads in a result or a bill of quantities.
extension CompanionText on Companion {
  Item get item => itemByKey(itemKey)!;

  String get name => label ?? item.name;

  /// The quantity with the item's unit, e.g. "12 bags".
  String get amount => '${formatNumber(quantity)} ${item.unitFor(quantity)}';
}

/// A companion material, rounded up to an amount that can be bought.
/// [work] names the work item it goes into when that is not the main one.
Companion buy(String itemKey, double quantity, {String? label, String? work}) {
  final item = itemByKey(itemKey);
  if (item == null) {
    throw ArgumentError.value(itemKey, 'itemKey', 'Unknown item');
  }
  return Companion(
    itemKey,
    item.purchasable(quantity),
    label: label,
    work: work,
  );
}

/// A lump sum worked out from the main cost, such as fittings at 40% of
/// the pipe cost. Bought as one lot at [amount] pesos.
Companion allowance(
  String itemKey,
  double amount, {
  String? label,
  String? work,
}) => Companion(
  itemKey,
  1,
  label: label,
  unitPrice: (amount * 100).roundToDouble() / 100,
  work: work,
);

/// Calculation for fixtures bought by the piece: quantity × price, with
/// [companions] listing the price book items each piece also needs and
/// how many of each. Each piece counts as one of [work] to install.
Calculation perPiece(
  String name, {
  List<String> descriptors = const [],
  QuantityUnit unit = QuantityUnit.pieces,
  List<(String, double)> companions = const [],
  String? itemKey,
  String? note,
  String? work,
}) => (input) {
  final quantity = input['quantity'];
  return CalcResult(
    label: describe(name, [for (final d in descriptors) input.choices[d]]),
    quantity: quantity,
    unit: unit,
    unitPrice: input['price'],
    itemKey: itemKey,
    companions: [
      for (final (key, each) in companions) buy(key, quantity * each),
    ],
    note: note,
    works: [?(work == null ? null : WorkQuantity(work, quantity))],
  );
};

NumberField quantityField(String label, {String? hint}) => NumberField(
  id: 'quantity',
  label: label,
  unit: 'pcs',
  hint: hint,
  integer: true,
  max: 100000,
);

NumberField priceField(
  String label, {
  String id = 'price',
  VisibleWhen? visibleWhen,
}) => NumberField(
  id: id,
  label: label,
  unit: '₱',
  isPrice: true,
  max: 10000000,
  visibleWhen: visibleWhen,
);
