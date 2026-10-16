import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/permit_fees.dart';
import '../../data/project.dart';
import '../../state/projects_controller.dart';

/// Opens the permit fee worksheet for [project]; its total can go into the
/// project's general requirement for permits.
Future<void> showPermitFees(BuildContext context, Project project) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PermitFeesPage(project: project),
      ),
    );

/// Puts [amount] into the general requirement [key] of [project].
void _setGeneral(
  BuildContext context,
  Project project,
  String key,
  double amount,
) {
  final controller = context.read<ProjectsController>();
  final costs = controller.byId(project.id)?.costs ?? project.costs;
  final general = {...costs.general};
  if (amount > 0) {
    general[key] = amount;
  } else {
    general.remove(key);
  }
  controller.updateCosts(project.id, costs.copyWith(general: general));
}

class _PermitFeesPage extends StatefulWidget {
  const _PermitFeesPage({required this.project});

  final Project project;

  @override
  State<_PermitFeesPage> createState() => _PermitFeesPageState();
}

class _PermitFeesPageState extends State<_PermitFeesPage> {
  late PermitInputs _in = PermitInputs.forProject(
    widget.project,
    storeys: (widget.project.floorArea ?? 0) > 100 ? 2 : 1,
  );
  late final double _measuredExcavation = excavationOf(widget.project);

  /// Fields the user typed, which no longer follow the floor area.
  final _typed = <String>{};
  final _text = <String, TextEditingController>{};

  static String _show(num v) => v == 0
      ? ''
      : v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(2);

  TextEditingController _controller(String key, num value) =>
      _text.putIfAbsent(key, () => TextEditingController(text: _show(value)));

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Follows a new floor area or storey count in the guesses the user has
  /// not typed over.
  void _rederive() {
    final area = _in.floorArea;
    final storeys = _in.storeys < 1 ? 1 : _in.storeys;
    final guesses = <String, num>{
      'load': typicalConnectedLoad(area),
      'baths': typicalBathrooms(area, storeys),
      if (_measuredExcavation <= 0)
        'excavation': (area / storeys * 0.5).ceilToDouble(),
    };
    for (final MapEntry(:key, :value) in guesses.entries) {
      if (_typed.contains(key)) continue;
      _in = switch (key) {
        'load' => _in.copyWith(connectedLoad: value.toDouble()),
        'baths' => _in.copyWith(bathrooms: value.toInt()),
        _ => _in.copyWith(excavation: value.toDouble()),
      };
      _text[key]?.text = _show(value);
    }
  }

  void _change(String key, String raw) {
    final v = double.tryParse(raw.trim()) ?? 0;
    setState(() {
      _typed.add(key);
      _in = switch (key) {
        'area' => _in.copyWith(floorArea: v),
        'storeys' => _in.copyWith(storeys: v.round()),
        'cost' => _in.copyWith(projectCost: v),
        'frontage' => _in.copyWith(frontage: v),
        'excavation' => _in.copyWith(excavation: v),
        'fence' => _in.copyWith(fenceLength: v),
        'load' => _in.copyWith(connectedLoad: v),
        'aircon' => _in.copyWith(airconUnits: v.round()),
        'baths' => _in.copyWith(bathrooms: v.round()),
        _ => _in.copyWith(otherLguFees: v),
      };
      if (key == 'area' || key == 'storeys') _rederive();
    });
  }

  Widget _field(
    String key,
    String label,
    num value, {
    String? prefix,
    String? suffix,
    String? helper,
    bool whole = false,
  }) => TextField(
    controller: _controller(key, value),
    keyboardType: TextInputType.numberWithOptions(decimal: !whole),
    inputFormatters: [
      DecimalInputFormatter(allowDecimal: !whole),
      LengthLimitingTextInputFormatter(12),
    ],
    style: tabular(Theme.of(context).textTheme.bodyLarge),
    decoration: InputDecoration(
      labelText: label,
      prefixText: prefix,
      suffixText: suffix,
      helperText: helper,
      helperMaxLines: 2,
      isDense: true,
    ),
    onChanged: (raw) => _change(key, raw),
  );

  Widget _pair(Widget left, Widget right) => Padding(
    padding: const EdgeInsets.only(bottom: Space.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: Space.md),
        Expanded(child: right),
      ],
    ),
  );

  void _apply(double total) {
    _setGeneral(context, widget.project, 'permits', total);
    Navigator.of(context).pop();
    showMessage(
      context,
      context.tr('Permits and fees set to {amount}.', {
        'amount': formatMoney(total),
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final lines = permitFees(_in);
    final total = permitTotal(_in);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Permit fees'))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          Space.lg,
          Space.lg,
          Space.lg,
          bottomClearance(context),
        ),
        children: [
          Text(
            context.tr(
              'The national fee schedule of the National Building Code (PD '
              '1096) that building officials assess, with the fire code '
              'fees of the BFP and, for a house, the zoning clearance.',
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Space.lg),
          DropdownButtonFormField<PermitUse>(
            initialValue: _in.use,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('Use of the building'),
            ),
            items: [
              for (final u in PermitUse.values)
                DropdownMenuItem(value: u, child: Text(context.tr(u.label))),
            ],
            onChanged: (u) {
              if (u != null) setState(() => _in = _in.copyWith(use: u));
            },
          ),
          const SizedBox(height: Space.md),
          _pair(
            _field(
              'area',
              context.tr('Total floor area'),
              _in.floorArea,
              suffix: 'm²',
            ),
            _field('storeys', context.tr('Storeys'), _in.storeys, whole: true),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: _field(
              'cost',
              context.tr('Project cost'),
              _in.projectCost.roundToDouble(),
              prefix: '₱ ',
              helper: context.tr(
                'The budget without permits and professional fees',
              ),
            ),
          ),
          _pair(
            _field(
              'frontage',
              context.tr('Street frontage'),
              _in.frontage,
              suffix: 'm',
            ),
            _field(
              'excavation',
              context.tr('Excavation'),
              _in.excavation,
              suffix: 'm³',
              helper: _measuredExcavation > 0
                  ? context.tr('From the estimates')
                  : null,
            ),
          ),
          _pair(
            _field(
              'load',
              context.tr('Connected load'),
              _in.connectedLoad,
              suffix: 'kVA',
            ),
            _field(
              'baths',
              context.tr('Bathrooms'),
              _in.bathrooms,
              whole: true,
            ),
          ),
          _pair(
            _field(
              'aircon',
              context.tr('Air-conditioners'),
              _in.airconUnits,
              whole: true,
            ),
            _field(
              'fence',
              context.tr('Fence length'),
              _in.fenceLength,
              suffix: 'm',
            ),
          ),
          if (_in.fenceLength > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: DropdownButtonFormField<FenceKind>(
                initialValue: _in.fence,
                isExpanded: true,
                decoration: InputDecoration(labelText: context.tr('Fence')),
                items: [
                  for (final f in FenceKind.values)
                    DropdownMenuItem(
                      value: f,
                      child: Text(context.tr(f.label)),
                    ),
                ],
                onChanged: (f) {
                  if (f != null) setState(() => _in = _in.copyWith(fence: f));
                },
              ),
            ),
          _field(
            'other',
            context.tr('Other LGU fees'),
            _in.otherLguFees,
            prefix: '₱ ',
            helper: context.tr(
              'Filing and processing fees, barangay clearance and the like, '
              'from your city or town hall',
            ),
          ),
          const SizedBox(height: Space.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final l in lines) ...[
                    KeyValueLine(
                      context.tr(l.label),
                      formatMoney(l.amount),
                      padding: const EdgeInsets.only(top: Space.sm),
                    ),
                    Text(l.basis, style: muted),
                  ],
                  const Divider(height: Space.xl),
                  KeyValueLine(
                    context.tr('Permits and fees'),
                    formatMoney(total),
                    emphasize: true,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          Text(
            context.tr(
              'Cities and towns add their own fees, such as filing and '
              'processing fees and the barangay clearance, and some charge '
              'more than the national rates. The BFP collects the fire code '
              'fees. Ask your building official for the assessment before '
              'you rely on this.',
            ),
            style: muted,
          ),
          const SizedBox(height: Space.lg),
          FilledButton.icon(
            onPressed: total > 0 ? () => _apply(total) : null,
            icon: const Icon(Icons.check),
            label: Text(
              context.tr('Put {amount} in permits', {
                'amount': formatMoney(total),
              }),
            ),
          ),
        ],
      ),
    );
  }
}
