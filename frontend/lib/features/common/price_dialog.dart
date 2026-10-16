import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/i18n.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/price_quote.dart';

/// A price with the supplier who quoted it and the day of the quote.
typedef QuotedPrice = ({double price, String supplier, DateTime date});

final _quoteDate = DateFormat('MMM d, y', 'en_US');

/// "Wilcon Depot · quoted Oct 3, 2026" for a price book line.
String quoteLabel(PriceQuote quote) => [
  if (quote.supplier.isNotEmpty) quote.supplier,
  if (quote.date case final d?) 'quoted ${_quoteDate.format(d)}',
].join(' · ');

/// Asks for a price in pesos. Returns null when cancelled.
Future<double?> showPriceDialog(
  BuildContext context, {
  required String title,
  required String unit,
  double? initial,
  String? suggested,
}) async => (await showDialog<QuotedPrice>(
  context: context,
  builder: (context) => _PriceDialog(
    title: title,
    unit: unit,
    initial: initial,
    suggested: suggested,
  ),
))?.price;

/// Asks for a price in pesos with the supplier and the day of the quote,
/// starting from [quote]. Returns null when cancelled.
Future<QuotedPrice?> showQuoteDialog(
  BuildContext context, {
  required String title,
  required String unit,
  double? initial,
  String? suggested,
  PriceQuote? quote,
}) => showDialog<QuotedPrice>(
  context: context,
  builder: (context) => _PriceDialog(
    title: title,
    unit: unit,
    initial: initial,
    suggested: suggested,
    withQuote: true,
    quote: quote,
  ),
);

class _PriceDialog extends StatefulWidget {
  const _PriceDialog({
    required this.title,
    required this.unit,
    this.initial,
    this.suggested,
    this.withQuote = false,
    this.quote,
  });

  final String title;
  final String unit;
  final double? initial;
  final String? suggested;

  /// Whether to ask for the supplier and the quote date too.
  final bool withQuote;
  final PriceQuote? quote;

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final _controller = TextEditingController(
    text: widget.initial == null || widget.initial == 0
        ? ''
        : _plain(widget.initial!),
  );
  late final _supplier = TextEditingController(
    text: widget.quote?.supplier ?? '',
  );
  late DateTime _date = widget.quote?.date ?? _today();
  String? _error;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  void dispose() {
    _controller.dispose();
    _supplier.dispose();
    super.dispose();
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || !value.isFinite || value < 0 || value > 1e8) {
      setState(() => _error = 'Enter a price, like 250');
      return;
    }
    Navigator.of(context)
        .pop((price: value, supplier: _supplier.text.trim(), date: _date));
  }

  Future<void> _pickDate() async {
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null) setState(() => _date = picked);
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
        if (widget.withQuote) ...[
          const SizedBox(height: Space.md),
          TextField(
            controller: _supplier,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            decoration: InputDecoration(
              labelText: context.tr('Supplier'),
              hintText: context.tr('Optional'),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: Space.md),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text(
              context.tr('Quoted {date}', {'date': _quoteDate.format(_date)}),
            ),
          ),
        ],
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
