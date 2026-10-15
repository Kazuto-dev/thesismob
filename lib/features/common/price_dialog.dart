import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/i18n.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Asks for a price in pesos. Returns null when cancelled.
Future<double?> showPriceDialog(
  BuildContext context, {
  required String title,
  required String unit,
  double? initial,
  String? suggested,
}) => showDialog<double>(
  context: context,
  builder: (context) => _PriceDialog(
    title: title,
    unit: unit,
    initial: initial,
    suggested: suggested,
  ),
);

class _PriceDialog extends StatefulWidget {
  const _PriceDialog({
    required this.title,
    required this.unit,
    this.initial,
    this.suggested,
  });

  final String title;
  final String unit;
  final double? initial;
  final String? suggested;

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final _controller = TextEditingController(
    text: widget.initial == null || widget.initial == 0
        ? ''
        : _plain(widget.initial!),
  );
  String? _error;

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || !value.isFinite || value < 0 || value > 1e8) {
      setState(() => _error = 'Enter a price, like 250');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            const DecimalInputFormatter(),
            LengthLimitingTextInputFormatter(12),
          ],
          style: tabular(Theme.of(context).textTheme.bodyLarge),
          decoration: InputDecoration(
            labelText: 'Price per ${widget.unit}',
            prefixText: '₱ ',
            errorText: _error,
            helperText: widget.suggested,
            helperMaxLines: 2,
          ),
          onSubmitted: (_) => _save(),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(onPressed: _save, child: Text(context.tr('Save'))),
    ],
  );
}

/// "₱240.00 per bag" for a price book line.
String pricePer(double price, String unit) =>
    price > 0 ? '${formatMoney(price)} per $unit' : 'No price yet';
