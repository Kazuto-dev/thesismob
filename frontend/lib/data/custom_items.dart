import '../materials/catalog.dart';
import '../materials/material_spec.dart';
import 'estimate.dart';

/// Material id of items the user describes and prices by hand, for work no
/// calculator measures: a subcontractor's quote, a kitchen hood, solar
/// panels, an allowance for something not yet designed.
const customItemId = 'custom';

/// How a custom item is priced.
enum CustomKind {
  /// Materials and labour per unit, bought and built by the contractor.
  supply(
    'Supply and install',
    'Materials and labour priced per unit, like any other item',
  ),

  /// An all-in price from a subcontractor, per unit or as a lot.
  subcontract(
    'Subcontract',
    'A specialist\'s all-in price: materials, labour and their margin',
  ),

  /// A set amount for work not yet designed or chosen, adjusted to the
  /// actual cost later.
  provisional(
    'Provisional sum',
    'An allowance for work not yet designed or chosen, settled at cost',
  );

  const CustomKind(this.label, this.description);

  final String label;
  final String description;
}

/// Units a custom item can be measured in.
const customUnits = [
  QuantityUnit.lots,
  QuantityUnit.sets,
  QuantityUnit.pieces,
  QuantityUnit.squareMetres,
  QuantityUnit.cubicMetres,
  QuantityUnit.metres,
  QuantityUnit.kilograms,
];

/// Reading an estimate as a custom item. Its inputs hold the quantity, the
/// price per unit (materials, or all-in for a subcontract) and the labour
/// per unit; its choices hold the kind and the trade.
extension CustomItem on Estimate {
  bool get isCustom => materialId == customItemId;

  CustomKind get customKind => CustomKind.values.firstWhere(
    (k) => k.name == choices['kind'],
    orElse: () => CustomKind.supply,
  );

  /// Labour per unit, for a supply-and-install item.
  double get labourRate =>
      customKind == CustomKind.supply ? inputs['labour'] ?? 0 : 0;

  /// Whether this is a subcontract or provisional sum: an all-in amount
  /// rather than materials to buy.
  bool get isAllIn => isCustom && customKind != CustomKind.supply;
}

/// The trade an estimate belongs to: its calculator's, or the one chosen
/// for a custom item. Null for items of no known trade.
MaterialCategory? tradeOf(Estimate e) => e.isCustom
    ? MaterialCategory.values.asNameMap()[e.choices['trade']]
    : materialById(e.materialId)?.category;

double _centavos(double value) => (value * 100).roundToDouble() / 100;

/// A custom item. Pass [from] to change an existing one, keeping its id,
/// date, mark and note.
Estimate customItem({
  required String description,
  required CustomKind kind,
  required MaterialCategory? trade,
  required QuantityUnit unit,
  required double quantity,
  required double price,
  double labour = 0,
  Estimate? from,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  return Estimate(
    id: from?.id ?? Estimate.newId(at),
    materialId: customItemId,
    label: description.trim(),
    quantity: quantity,
    unit: unit,
    unitPrice: price,
    total: _centavos(quantity * price),
    createdAt: from?.createdAt ?? at,
    inputs: Map.unmodifiable({
      'quantity': quantity,
      'price': price,
      if (kind == CustomKind.supply && labour > 0) 'labour': labour,
    }),
    choices: Map.unmodifiable({'kind': kind.name, 'trade': trade?.name ?? ''}),
    mark: from?.mark,
    note: from?.note,
  );
}
