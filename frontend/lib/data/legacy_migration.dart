// Converts entries saved by the original app, which stored every amount as
// formatted text ("₱9375.0", "375pcs", "1.06Gal", "9375.0₱"), into numeric
// [Estimate]s.

import '../materials/material_spec.dart';
import 'estimate.dart';

final _numberPattern = RegExp(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');

/// Extracts the number from legacy text such as `₱1,250.50`, `375pcs` or
/// `₱1.249999975e+26`. Returns null when there is no finite number.
double? parseLegacyNumber(Object? value) {
  if (value is num) return value.isFinite ? value.toDouble() : null;
  if (value is! String) return null;
  final match = _numberPattern.firstMatch(value.replaceAll(',', ''));
  final parsed = match == null ? null : double.tryParse(match.group(0)!);
  return parsed != null && parsed.isFinite ? parsed : null;
}

QuantityUnit _legacyUnit(Object? quantity) {
  final text = quantity is String ? quantity.toLowerCase() : '';
  if (text.contains('gal')) return QuantityUnit.gallons;
  if (RegExp(r'\d\s*m$').hasMatch(text)) return QuantityUnit.metres;
  return QuantityUnit.pieces;
}

String _cleanLabel(Object? value) {
  final text = value is String ? value : 'Estimate';
  return text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && line.toLowerCase() != 'none')
      .join(', ');
}

Estimate? _legacyEstimate({
  required Object? label,
  required Object? quantityText,
  required Object? totalText,
  Object? areaText,
  DateTime? createdAt,
  required int index,
}) {
  final quantity = parseLegacyNumber(quantityText);
  final total = parseLegacyNumber(totalText);
  if (quantity == null || total == null) return null;
  final area = parseLegacyNumber(areaText);
  final when = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  return Estimate(
    id: 'legacy-${when.microsecondsSinceEpoch}-$index',
    materialId: Estimate.legacyMaterialId,
    label: _cleanLabel(label),
    area: area == null || area == 0 ? null : area,
    quantity: quantity,
    unit: _legacyUnit(quantityText),
    unitPrice: quantity == 0 ? 0 : total / quantity,
    total: total,
    createdAt: when,
  );
}

/// Original history entry: `{calculatorType, material, area, quantity,
/// date, totalamount}`.
Estimate? estimateFromLegacyHistory(Map<String, dynamic> json, int index) =>
    _legacyEstimate(
      label: json['material'] ?? json['calculatorType'],
      quantityText: json['quantity'],
      totalText: json['totalamount'],
      areaText: json['area'],
      createdAt: DateTime.tryParse('${json['date']}'),
      index: index,
    );

/// Original summary entry: `{materialName, quantity, totalamount}`.
Estimate? estimateFromLegacySummary(Map<String, dynamic> json, int index) =>
    _legacyEstimate(
      label: json['materialName'],
      quantityText: json['quantity'],
      totalText: json['totalamount'],
      index: index,
    );
