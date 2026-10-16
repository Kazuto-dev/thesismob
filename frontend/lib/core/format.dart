import 'package:intl/intl.dart';

import '../materials/material_spec.dart';

final _money = NumberFormat.currency(
  locale: 'en_US',
  symbol: '₱',
  decimalDigits: 2,
);
final _number = NumberFormat('#,##0.##', 'en_US');
final _dateTime = DateFormat('MMM d, y · h:mm a', 'en_US');
final _date = DateFormat('EEEE, MMM d, y', 'en_US');
final _time = DateFormat('h:mm a', 'en_US');

/// `₱9,375.00`
String formatMoney(double value) => _money.format(value);

/// `1,234.5` — at most two decimals, no trailing zeros.
String formatNumber(double value) => _number.format(value);

/// `375 blocks`, `1 roll`, `12.5 m`
String formatQuantity(double quantity, QuantityUnit unit) =>
    '${formatNumber(quantity)} ${unit.labelFor(quantity)}';

/// `16 bags`, `1 bag`
String formatCount(num count, String singular, [String? plural]) =>
    '${formatNumber(count.toDouble())} '
    '${count == 1 ? singular : plural ?? '${singular}s'}';

/// `30 m²`
String formatArea(double area) => '${formatNumber(area)} m²';

/// `12.5 m`
String formatLength(double metres) => '${formatNumber(metres)} m';

/// `1.31 m³`
String formatVolume(double cubicMetres) => '${formatNumber(cubicMetres)} m³';

/// `15%`
String formatPercent(double fraction) => '${formatNumber(fraction * 100)}%';

/// `Oct 9, 2026 · 3:41 PM`
String formatDateTime(DateTime value) => _dateTime.format(value);

/// `Friday, Oct 9, 2026`
String formatDate(DateTime value) => _date.format(value);

/// `3:41 PM`
String formatTime(DateTime value) => _time.format(value);
