import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../data/project.dart';
import '../../export/project_documents.dart';
import '../../state/projects_controller.dart';
import 'project_items.dart';

/// The bill of quantities as a dense table for wide screens: every item
/// and companion material with its quantity, unit price and amount, unit
/// prices edited in place.
class BoqGrid extends StatelessWidget {
  const BoqGrid({super.key, required this.project});

  final Project project;

  static const _columns = <int, TableColumnWidth>{
    0: FixedColumnWidth(52),
    1: FlexColumnWidth(),
    2: FixedColumnWidth(84),
    3: FixedColumnWidth(64),
    4: FixedColumnWidth(124),
    5: FixedColumnWidth(124),
    6: FixedColumnWidth(48),
  };

  void _setMainPrice(BuildContext context, Estimate e, double price) => context
      .read<ProjectsController>()
      .updateItem(e.copyWith(unitPrice: price), projectId: project.id);

  void _setLinePrice(
    BuildContext context,
    Estimate e,
    EstimateLine line,
    double price,
  ) => context.read<ProjectsController>().updateItem(
    e.copyWith(
      companions: [
        for (final l in e.companions)
          identical(l, line) ? l.withPrice(price) : l,
      ],
    ),
    projectId: project.id,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final number = tabular(theme.textTheme.bodyMedium);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final strong = tabular(
      theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
    );

    Widget cell(
      Widget child, {
      Alignment align = Alignment.centerLeft,
      double start = Space.sm,
    }) => Padding(
      padding: EdgeInsetsDirectional.fromSTEB(start, 6, Space.sm, 6),
      child: Align(alignment: align, child: child),
    );
    Widget text(String value, {TextStyle? style, bool right = false}) => cell(
      Text(value, style: style ?? number),
      align: right ? Alignment.centerRight : Alignment.centerLeft,
    );
    const empty = SizedBox.shrink();

    final rows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(color: scheme.surfaceContainerHigh),
        children: [
          for (final (label, right) in const [
            ('No.', false),
            ('Description', false),
            ('Qty', true),
            ('Unit', false),
            ('Unit price', true),
            ('Amount', true),
            ('', false),
          ])
            Semantics(
              header: true,
              child: text(
                label,
                style: theme.textTheme.labelLarge,
                right: right,
              ),
            ),
        ],
      ),
    ];

    for (final g in groupByTrade(project.items)) {
      final subtotal = g.items.fold<double>(0, (s, e) => s + e.grandTotal);
      rows.add(
        TableRow(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          children: [
            text(g.letter, style: theme.textTheme.titleSmall),
            Semantics(
              header: true,
              child: text(
                tradeLabel(g.trade).toUpperCase(),
                style: theme.textTheme.titleSmall,
              ),
            ),
            empty,
            empty,
            empty,
            text(formatMoney(subtotal), style: strong, right: true),
            empty,
          ],
        ),
      );
      for (final (i, e) in g.items.indexed) {
        rows.add(
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            children: [
              text('${g.letter}.${i + 1}'),
              cell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (e.note != null)
                      Text(
                        e.note!,
                        style: muted?.copyWith(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
              text(formatNumber(e.quantity), right: true),
              text(e.unit.labelFor(e.quantity)),
              _PriceCell(
                label: e.label,
                price: e.unitPrice,
                onChanged: (p) => _setMainPrice(context, e, p),
              ),
              text(formatMoney(e.total), right: true),
              ItemMenu(
                project: project,
                estimate: e,
                first: i == 0,
                last: i == g.items.length - 1,
              ),
            ],
          ),
        );
        for (final l in e.companions) {
          rows.add(
            TableRow(
              children: [
                empty,
                cell(Text(l.label, style: muted), start: Space.xl),
                text(formatNumber(l.quantity), style: muted, right: true),
                text(l.unit, style: muted),
                _PriceCell(
                  label: l.label,
                  price: l.unitPrice,
                  muted: true,
                  onChanged: (p) => _setLinePrice(context, e, l, p),
                ),
                text(formatMoney(l.total), style: muted, right: true),
                empty,
              ],
            ),
          );
        }
      }
    }
    rows.add(
      TableRow(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          border: Border(top: BorderSide(color: scheme.outline)),
        ),
        children: [
          empty,
          text('Materials total', style: theme.textTheme.titleSmall),
          empty,
          empty,
          empty,
          text(
            formatMoney(project.breakdown.materials),
            style: strong,
            right: true,
          ),
          empty,
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.lg,
              Space.md,
              Space.lg,
              Space.md,
            ),
            child: Text(
              'Click a unit price to change it for this item only. Prices '
              'for the whole project are set under To buy.',
              style: muted,
            ),
          ),
          Table(
            columnWidths: _columns,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: rows,
          ),
        ],
      ),
    );
  }
}

/// A unit price that turns into a field when clicked. Enter or leaving the
/// field saves it; Escape puts it back.
class _PriceCell extends StatefulWidget {
  const _PriceCell({
    required this.label,
    required this.price,
    required this.onChanged,
    this.muted = false,
  });

  final String label;
  final double price;
  final ValueChanged<double> onChanged;
  final bool muted;

  @override
  State<_PriceCell> createState() => _PriceCellState();
}

class _PriceCellState extends State<_PriceCell> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _start() {
    final p = widget.price;
    _controller.text = p <= 0
        ? ''
        : p == p.roundToDouble()
        ? p.toInt().toString()
        : p.toStringAsFixed(2);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _commit() {
    final value = double.tryParse(_controller.text.trim());
    setState(() => _editing = false);
    if (value != null && value >= 0 && value != widget.price) {
      widget.onChanged((value * 100).roundToDouble() / 100);
    }
  }

  void _cancel() {
    _controller.text = '';
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (_editing) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xs),
        child: CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.escape): _cancel},
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            textAlign: TextAlign.end,
            style: tabular(theme.textTheme.bodyMedium),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              const DecimalInputFormatter(),
              LengthLimitingTextInputFormatter(12),
            ],
            decoration: InputDecoration(
              isDense: true,
              prefixText: '₱ ',
              labelText: null,
              hintText: '0',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Space.sm,
                vertical: Space.sm,
              ),
              semanticCounterText: 'Unit price of ${widget.label}',
            ),
            onSubmitted: (_) => _focus.unfocus(),
          ),
        ),
      );
    }
    final missing = widget.price <= 0;
    return Semantics(
      button: true,
      label:
          'Unit price of ${widget.label}, '
          '${missing ? 'not set' : formatMoney(widget.price)}',
      hint: 'Edit',
      excludeSemantics: true,
      child: InkWell(
        onTap: _start,
        borderRadius: BorderRadius.circular(Radii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.sm,
            vertical: 6,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              missing ? 'Set price' : formatMoney(widget.price),
              style: missing
                  ? theme.textTheme.labelLarge?.copyWith(color: scheme.primary)
                  : tabular(
                      (widget.muted
                              ? theme.textTheme.bodySmall
                              : theme.textTheme.bodyMedium)
                          ?.copyWith(
                            color: widget.muted
                                ? scheme.onSurfaceVariant
                                : null,
                            decoration: TextDecoration.underline,
                            decorationStyle: TextDecorationStyle.dotted,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
