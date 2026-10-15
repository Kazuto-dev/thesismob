import 'dart:math';

import 'package:flutter/foundation.dart';

import '../materials/material_spec.dart';

final _random = Random();

/// One calculated estimate. All amounts are stored as numbers; formatting
/// happens only when they are displayed.
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
  });

  factory Estimate.fromResult({
    required String materialId,
    required CalcResult result,
    required Map<String, double> inputs,
    required Map<String, String> choices,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
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
  final double total;
  final DateTime createdAt;

  /// The values typed into the calculator, keyed by field id.
  final Map<String, double> inputs;

  /// The selected dropdown options, keyed by field id.
  final Map<String, String> choices;

  static String newId(DateTime at) =>
      '${at.microsecondsSinceEpoch.toRadixString(36)}-'
      '${_random.nextInt(0x3fffffff).toRadixString(36)}';

  /// A copy of this estimate stored under [newId].
  Estimate withId(String newId) => Estimate(
    id: newId,
    materialId: materialId,
    label: label,
    area: area,
    quantity: quantity,
    unit: unit,
    unitPrice: unitPrice,
    total: total,
    createdAt: createdAt,
    inputs: inputs,
    choices: choices,
  );

  /// True when [other] came from the same calculator with the same inputs.
  bool sameCalculationAs(Estimate other) =>
      materialId == other.materialId &&
      mapEquals(inputs, other.inputs) &&
      mapEquals(choices, other.choices);

  /// Columns for Google Sheets: Materials, Area(sqm), Quantity, Cost(₱).
  List<Object?> toSheetRow() => [label, area ?? '', quantity, total];

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
  };
}
