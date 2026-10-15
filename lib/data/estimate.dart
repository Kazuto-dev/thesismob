import 'dart:math';

import 'package:flutter/foundation.dart';

import '../materials/items.dart';
import '../materials/material_spec.dart';

final _random = Random();

double _centavos(double value) => (value * 100).roundToDouble() / 100;

/// A priced companion material in an estimate, e.g. 28 bags of cement.
@immutable
class EstimateLine {
  const EstimateLine({
    required this.itemKey,
    required this.label,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
  });

  /// Prices [companion] with [priceOf], the price book lookup.
  factory EstimateLine.fromCompanion(
    Companion companion,
    double Function(String itemKey) priceOf,
  ) {
    final item = itemByKey(companion.itemKey);
    return EstimateLine(
      itemKey: companion.itemKey,
      label: companion.label ?? item?.name ?? companion.itemKey,
      quantity: companion.quantity,
      unit: item?.unitFor(companion.quantity) ?? '',
      unitPrice: companion.unitPrice ?? priceOf(companion.itemKey),
    );
  }

  factory EstimateLine.fromJson(Map<String, dynamic> json) {
    final quantity = json['quantity'];
    final unitPrice = json['unitPrice'];
    if (json['itemKey'] is! String ||
        quantity is! num ||
        !quantity.isFinite ||
        unitPrice is! num ||
        !unitPrice.isFinite) {
      throw FormatException('EstimateLine is malformed', json);
    }
    return EstimateLine(
      itemKey: json['itemKey'] as String,
      label: json['label'] is String ? json['label'] as String : '',
      quantity: quantity.toDouble(),
      unit: json['unit'] is String ? json['unit'] as String : '',
      unitPrice: unitPrice.toDouble(),
    );
  }

  final String itemKey;
  final String label;
  final double quantity;
  final String unit;
  final double unitPrice;

  double get total => _centavos(quantity * unitPrice);

  EstimateLine withPrice(double price) => EstimateLine(
    itemKey: itemKey,
    label: label,
    quantity: quantity,
    unit: unit,
    unitPrice: price,
  );

  Map<String, dynamic> toJson() => {
    'itemKey': itemKey,
    'label': label,
    'quantity': quantity,
    'unit': unit,
    'unitPrice': unitPrice,
  };
}

/// One calculated estimate: the main material plus the companion materials
/// the job needs. All amounts are stored as numbers; formatting happens only
/// when they are displayed.
@immutable
class Estimate {
  const Estimate({
    required this.id,
    required this.materialId,
    required this.label,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.total,
    required this.createdAt,
    this.area,
    this.inputs = const {},
    this.choices = const {},
    this.itemKey,
    this.companions = const [],
    this.mark,
    this.note,
  });

  /// Builds an estimate from a calculation, pricing its companions with
  /// [priceOf].
  factory Estimate.fromResult({
    required String materialId,
    required CalcResult result,
    required Map<String, double> inputs,
    required Map<String, String> choices,
    double Function(String itemKey)? priceOf,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    final lookup = priceOf ?? (key) => itemByKey(key)?.price ?? 0;
    return Estimate(
      id: newId(now),
      materialId: materialId,
      label: result.label,
      area: result.area,
      quantity: result.quantity,
      unit: result.unit,
      unitPrice: result.unitPrice,
      total: result.total,
      createdAt: now,
      inputs: Map.unmodifiable(inputs),
      choices: Map.unmodifiable(choices),
      itemKey: result.itemKey,
      companions: List.unmodifiable([
        for (final c in result.companions)
          if (c.quantity > 0) EstimateLine.fromCompanion(c, lookup),
      ]),
    );
  }

  /// Parses an entry saved by this version of the app. Throws a
  /// [FormatException] when required fields are missing or malformed.
  factory Estimate.fromJson(Map<String, dynamic> json) {
    double number(String key) {
      final value = json[key];
      if (value is num && value.isFinite) return value.toDouble();
      throw FormatException('Estimate.$key is not a number', value);
    }

    String text(String key) {
      final value = json[key];
      if (value is String) return value;
      throw FormatException('Estimate.$key is not text', value);
    }

    final area = json['area'];
    final companions = <EstimateLine>[];
    if (json['companions'] case final List<dynamic> list) {
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          try {
            companions.add(EstimateLine.fromJson(item));
          } on FormatException {
            // Skip a damaged line rather than losing the estimate.
          }
        }
      }
    }
    return Estimate(
      id: text('id'),
      materialId: text('materialId'),
      label: text('label'),
      area: area is num && area.isFinite ? area.toDouble() : null,
      quantity: number('quantity'),
      unit: QuantityUnit.byName(text('unit')),
      unitPrice: number('unitPrice'),
      total: number('total'),
      createdAt:
          DateTime.tryParse(text('createdAt')) ??
          (throw FormatException('Estimate.createdAt', json['createdAt'])),
      inputs: {
        for (final e in (json['inputs'] as Map? ?? const {}).entries)
          if (e.value is num) e.key as String: (e.value as num).toDouble(),
      },
      choices: {
        for (final e in (json['choices'] as Map? ?? const {}).entries)
          if (e.value is String) e.key as String: e.value as String,
      },
      itemKey: json['itemKey'] is String ? json['itemKey'] as String : null,
      companions: List.unmodifiable(companions),
      mark: _optionalText(json['mark']),
      note: _optionalText(json['note']),
    );
  }

  /// Material id given to entries migrated from the original app, which
  /// did not record which calculator produced them.
  static const legacyMaterialId = 'legacy';

  final String id;
  final String materialId;

  /// Short description such as `CHB 4"`.
  final String label;
  final double? area;
  final double quantity;
  final QuantityUnit unit;
  final double unitPrice;

  /// Cost of the main material only.
  final double total;
  final DateTime createdAt;

  /// The values typed into the calculator, keyed by field id.
  final Map<String, double> inputs;

  /// The selected options, keyed by field id.
  final Map<String, String> choices;

  /// Price book entry of the main material, when the calculator has one.
  final String? itemKey;

  /// Priced companion materials, such as cement and sand for blocks.
  final List<EstimateLine> companions;

  /// The user's name for this item in a project, such as "F1" or "Kitchen
  /// wall".
  final String? mark;

  /// The user's note on this item, printed in the bill of quantities.
  final String? note;

  /// The mark and the label, as shown in lists and documents.
  String get title => mark == null ? label : '$mark – $label';

  /// Calculator fields that hold the main material's price.
  static const _priceInputs = {'price', 'piecePrice', 'tankPrice'};

  static String? _optionalText(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Cost of the companion materials.
  double get companionsTotal =>
      _centavos(companions.fold<double>(0, (sum, l) => sum + l.total));

  /// Cost of the main material and its companions.
  double get grandTotal => _centavos(total + companionsTotal);

  static String newId(DateTime at) =>
      '${at.microsecondsSinceEpoch.toRadixString(36)}-'
      '${_random.nextInt(0x3fffffff).toRadixString(36)}';

  /// True when [other] came from the same calculator with the same inputs.
  bool sameCalculationAs(Estimate other) =>
      materialId == other.materialId &&
      mapEquals(inputs, other.inputs) &&
      mapEquals(choices, other.choices);

  /// A copy with changes. Pass an empty string as [mark] or [note] to
  /// clear it.
  Estimate copyWith({
    String? id,
    double? unitPrice,
    List<EstimateLine>? companions,
    String? mark,
    String? note,
  }) {
    final price = unitPrice ?? this.unitPrice;
    return Estimate(
      id: id ?? this.id,
      materialId: materialId,
      label: label,
      area: area,
      quantity: quantity,
      unit: unit,
      unitPrice: price,
      total: unitPrice == null ? total : _centavos(quantity * price),
      createdAt: createdAt,
      // The price typed into the calculator follows, so the item reopens
      // at its new price.
      inputs: unitPrice == null
          ? inputs
          : Map.unmodifiable({
              for (final MapEntry(:key, :value) in inputs.entries)
                key: _priceInputs.contains(key) && value == this.unitPrice
                    ? unitPrice
                    : value,
            }),
      choices: choices,
      itemKey: itemKey,
      companions: companions ?? this.companions,
      mark: mark == null ? this.mark : _optionalText(mark),
      note: note == null ? this.note : _optionalText(note),
    );
  }

  /// A copy of this estimate stored under [newId].
  Estimate withId(String newId) => copyWith(id: newId);

  /// Rows for Google Sheets: the main material, then each companion, as
  /// Item, Quantity, Unit, Unit cost, Amount.
  List<List<Object?>> toSheetRows() => [
    [title, quantity, unit.labelFor(quantity), unitPrice, total],
    for (final l in companions)
      ['  ${l.label}', l.quantity, l.unit, l.unitPrice, l.total],
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'materialId': materialId,
    'label': label,
    if (area != null) 'area': area,
    'quantity': quantity,
    'unit': unit.name,
    'unitPrice': unitPrice,
    'total': total,
    'createdAt': createdAt.toIso8601String(),
    'inputs': inputs,
    'choices': choices,
    if (itemKey != null) 'itemKey': itemKey,
    if (companions.isNotEmpty)
      'companions': [for (final l in companions) l.toJson()],
    if (mark != null) 'mark': mark,
    if (note != null) 'note': note,
  };
}
