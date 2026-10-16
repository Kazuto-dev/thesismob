import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/custom_items.dart';
import '../../data/estimate.dart';
import '../../materials/material_spec.dart';
import '../../state/projects_controller.dart';

/// Asks for a custom item and adds it to the project [projectId], or the
/// active project.
Future<void> addCustomItem(BuildContext context, {String? projectId}) async {
  final created = await showDialog<Estimate>(
    context: context,
    builder: (_) => const CustomItemDialog(),
  );
  if (created == null || !context.mounted) return;
  final controller = context.read<ProjectsController>();
  controller.add(created, projectId: projectId);
  showMessage(
    context,
    context.tr('Added {item}.', {'item': created.label}),
    action: SnackBarAction(
      label: context.tr('Undo'),
      onPressed: () => controller.removeItem(created.id, projectId: projectId),
    ),
  );
}

/// Changes the custom item [e] in the project [projectId].
Future<void> editCustomItem(
  BuildContext context,
  String projectId,
  Estimate e,
) async {
  final changed = await showDialog<Estimate>(
    context: context,
    builder: (_) => CustomItemDialog(initial: e),
  );
  if (changed == null || !context.mounted) return;
  context.read<ProjectsController>().updateItem(changed, projectId: projectId);
}

/// A line of work described and priced by hand: supply and install,
/// a subcontract or a provisional sum.
class CustomItemDialog extends StatefulWidget {
  const CustomItemDialog({super.key, this.initial});

  /// The item to change, or null for a new one.
  final Estimate? initial;

  @override
  State<CustomItemDialog> createState() => _CustomItemDialogState();
}

class _CustomItemDialogState extends State<CustomItemDialog> {
  late final Estimate? _from = widget.initial;
  late final _description = TextEditingController(text: _from?.label);
  late final _quantity = TextEditingController(
    text: _from == null ? '1' : _plain(_from.quantity),
  );
  late final _price = TextEditingController(
    text: _from == null || _from.unitPrice == 0 ? '' : _plain(_from.unitPrice),
  );
  late final _labour = TextEditingController(
    text: _from == null || _from.labourRate == 0
        ? ''
        : _plain(_from.labourRate),
  );
  late CustomKind _kind = _from?.customKind ?? CustomKind.supply;
  late MaterialCategory? _trade = _from == null
      ? MaterialCategory.architectural
      : tradeOf(_from);
  late QuantityUnit _unit = _from?.unit ?? QuantityUnit.lots;
  bool _tried = false;

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void initState() {
    super.initState();
    for (final c in [_description, _quantity, _price, _labour]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _quantity.dispose();
    _price.dispose();
    _labour.dispose();
    super.dispose();
  }

  double get _q => double.tryParse(_quantity.text.trim()) ?? 0;
  double get _p => double.tryParse(_price.text.trim()) ?? 0;
  double get _l => _kind == CustomKind.supply
      ? double.tryParse(_labour.text.trim()) ?? 0
      : 0;

  bool get _valid =>
      _description.text.trim().isNotEmpty && _q > 0 && (_p > 0 || _l > 0);

  void _save() {
    if (!_valid) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop(
      customItem(
        description: _description.text,
        kind: _kind,
        trade: _trade,
        unit: _unit,
        quantity: _q,
        price: _p,
        labour: _l,
        from: _from,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final unitLabel = _unit.singular;
    final number = [
      const DecimalInputFormatter(),
      LengthLimitingTextInputFormatter(12),
    ];
    return AlertDialog(
      title: Text(
        context.tr(_from == null ? 'Custom item' : 'Change custom item'),
      ),
      scrollable: true,
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(
                'For work no calculator covers: a subcontractor\'s price, an '
                'appliance, an allowance for something not yet chosen.',
              ),
              style: muted,
            ),
            const SizedBox(height: Space.lg),
            TextField(
              controller: _description,
              autofocus: _from == null,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              decoration: InputDecoration(
                labelText: context.tr('Description'),
                hintText: context.tr(
                  'Solar panels, 3 kW, supplied and installed',
                ),
                errorText: _tried && _description.text.trim().isEmpty
                    ? context.tr('Describe the work')
                    : null,
              ),
            ),
            const SizedBox(height: Space.lg),
            Text(context.tr('Priced as'), style: theme.textTheme.labelLarge),
            const SizedBox(height: Space.sm),
            SegmentedButton<CustomKind>(
              showSelectedIcon: false,
              segments: [
                for (final k in CustomKind.values)
                  ButtonSegment(value: k, label: Text(context.tr(k.label))),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: Space.xs),
            Text(context.tr(_kind.description), style: muted),
            const SizedBox(height: Space.lg),
            DropdownButtonFormField<MaterialCategory?>(
              initialValue: _trade,
              decoration: InputDecoration(
                labelText: context.tr('Section of the bill of quantities'),
              ),
              items: [
                for (final c in MaterialCategory.values)
                  DropdownMenuItem(value: c, child: Text(context.tr(c.label))),
                DropdownMenuItem(child: Text(context.tr('Other works'))),
              ],
              onChanged: (v) => setState(() => _trade = v),
            ),
            const SizedBox(height: Space.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: number,
                    style: tabular(theme.textTheme.bodyLarge),
                    decoration: InputDecoration(
                      labelText: context.tr('Quantity'),
                      errorText: _tried && _q <= 0
                          ? context.tr('More than 0')
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: DropdownButtonFormField<QuantityUnit>(
                    initialValue: _unit,
                    decoration: InputDecoration(labelText: context.tr('Unit')),
                    items: [
                      for (final u in customUnits)
                        DropdownMenuItem(value: u, child: Text(u.singular)),
                    ],
                    onChanged: (v) => setState(() => _unit = v ?? _unit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: number,
              style: tabular(theme.textTheme.bodyLarge),
              decoration: InputDecoration(
                labelText: context.tr(
                  switch (_kind) {
                    CustomKind.supply => 'Materials per {unit}',
                    CustomKind.subcontract => 'All-in price per {unit}',
                    CustomKind.provisional => 'Amount per {unit}',
                  },
                  {'unit': unitLabel},
                ),
                prefixText: '₱ ',
                errorText: _tried && _p <= 0 && _l <= 0
                    ? context.tr('Enter a price')
                    : null,
              ),
            ),
            if (_kind == CustomKind.supply) ...[
              const SizedBox(height: Space.lg),
              TextField(
                controller: _labour,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: number,
                style: tabular(theme.textTheme.bodyLarge),
                decoration: InputDecoration(
                  labelText: context.tr('Labour per {unit}', {
                    'unit': unitLabel,
                  }),
                  prefixText: '₱ ',
                  helperText: context.tr(
                    'Minor tools and the markups are added as for other items',
                  ),
                ),
              ),
            ],
            const SizedBox(height: Space.lg),
            KeyValueLine(
              context.tr('Direct cost'),
              formatMoney(_q * (_p + _l)),
              emphasize: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(context.tr(_from == null ? 'Add' : 'Save')),
        ),
      ],
    );
  }
}
