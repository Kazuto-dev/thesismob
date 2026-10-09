import '../core/format.dart';
import 'material_spec.dart';

/// Rounds a count up while ignoring floating-point noise, so that
/// 30 / 0.08 = 375.00000000000006 counts as 375, not 376.
int ceilCount(double value) => (value - 1e-9).ceil();

/// Pieces needed to cover [area] with units of [unitArea], plus a
/// [contingency] fraction rounded up separately.
({int base, int extra, int total}) countByArea(
  double area,
  double unitArea,
  double contingency,
) {
  final base = ceilCount(area / unitArea);
  final extra = contingency == 0 ? 0 : ceilCount(base * contingency);
  return (base: base, extra: extra, total: base + extra);
}

const contingencyField = ChoiceField(
  id: 'contingency',
  label: 'Contingency',
  initial: 'none',
  helper: 'Extra pieces for cutting and breakage',
  options: [
    ChoiceOption('none', 'None', 0),
    ChoiceOption('5', '5% extra', 0.05),
    ChoiceOption('10', '10% extra', 0.10),
    ChoiceOption('15', '15% extra', 0.15),
  ],
);

/// Option id used by descriptive dropdowns that do not change the quantity.
const notSpecified = 'any';

/// Joins the parts of a summary label, skipping options left unspecified.
String describe(String base, Iterable<ChoiceOption?> parts) {
  final extra = [
    for (final p in parts)
      if (p != null && p.id != notSpecified) p.label,
  ];
  return extra.isEmpty ? base : '$base, ${extra.join(', ')}';
}

/// Breakdown lines shared by the area-based calculators.
List<ResultDetail> areaDetails({
  required double area,
  required double unitArea,
  required ({int base, int extra, int total}) count,
  required double contingency,
  required QuantityUnit unit,
  required String unitAreaLabel,
}) => [
  ResultDetail(unitAreaLabel, formatArea(unitArea)),
  ResultDetail(
    'Needed to cover ${formatArea(area)}',
    formatQuantity(count.base.toDouble(), unit),
  ),
  if (count.extra > 0)
    ResultDetail(
      'Contingency (${formatPercent(contingency)})',
      '+${formatQuantity(count.extra.toDouble(), unit)}',
    ),
];

/// Calculation for fixtures bought by the piece: quantity × price.
Calculation perPiece(
  String name, {
  List<String> descriptors = const [],
  QuantityUnit unit = QuantityUnit.pieces,
}) => (input) {
  final quantity = input['quantity'];
  return CalcResult(
    label: describe(name, [for (final d in descriptors) input.choices[d]]),
    quantity: quantity,
    unit: unit,
    unitPrice: input['price'],
  );
};

NumberField quantityField(String label) => NumberField(
  id: 'quantity',
  label: label,
  unit: 'pcs',
  integer: true,
  max: 100000,
);

NumberField priceField(String label) => NumberField(
  id: 'price',
  label: label,
  unit: '₱',
  isPrice: true,
  max: 10000000,
);
