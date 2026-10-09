import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/layout.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../data/sheets_export_service.dart';
import '../../materials/material_spec.dart';
import '../../router.dart';
import '../../state/estimates_controller.dart';
import '../../state/sheet_settings_controller.dart';
import 'info_sheet.dart';
import 'result_card.dart';

/// One screen for every material, built from its [MaterialSpec].
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, required this.spec, this.fromEstimateId});

  final MaterialSpec spec;

  /// History entry whose inputs prefill the form.
  final String? fromEstimateId;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _resultKey = GlobalKey();
  late final Map<String, TextEditingController> _text = {
    for (final f in widget.spec.numbers) f.id: TextEditingController(),
  };
  late final Map<String, FocusNode> _focus = {
    for (final f in widget.spec.numbers) f.id: FocusNode(),
  };
  late Map<String, String> _selected = widget.spec.initialChoices;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  Estimate? _estimate;
  CalcResult? _result;
  bool _stale = false;

  MaterialSpec get spec => widget.spec;

  @override
  void initState() {
    super.initState();
    _prefill();
    for (final c in _text.values) {
      c.addListener(_markStale);
    }
  }

  void _prefill() {
    final id = widget.fromEstimateId;
    if (id == null) return;
    final history = context.read<EstimatesController>().history;
    final saved = history.where((e) => e.id == id).firstOrNull;
    if (saved == null || saved.materialId != spec.id) return;
    for (final MapEntry(:key, :value) in saved.inputs.entries) {
      _text[key]?.text = value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toString();
    }
    _selected = {..._selected, ...saved.choices};
    try {
      _result = spec.calculate(saved.inputs, _selected);
      _estimate = saved;
    } on ArgumentError {
      // Saved by an older version with different options; let the user redo it.
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _markStale() {
    if (_estimate != null && !_stale) setState(() => _stale = true);
  }

  void _select(String id, String? value) {
    if (value == null) return;
    setState(() => _selected = {..._selected, id: value});
    _markStale();
  }

  void _calculate() {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) {
      for (final field in spec.numbers) {
        if (field.validate(_text[field.id]!.text) != null) {
          _focus[field.id]!.requestFocus();
          break;
        }
      }
      return;
    }
    final numbers = {
      for (final f in spec.numbers) f.id: f.parse(_text[f.id]!.text)!,
    };
    final visible = {
      for (final c in spec.visibleChoices(_selected)) c.id: _selected[c.id]!,
    };
    final result = spec.calculate(numbers, visible);
    final recorded = context.read<EstimatesController>().record(
      Estimate.fromResult(
        materialId: spec.id,
        result: result,
        inputs: numbers,
        choices: visible,
      ),
    );
    setState(() {
      _result = result;
      _estimate = recorded;
      _stale = false;
    });
    if (WindowSize.of(context) != WindowSize.expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _resultKey.currentContext;
        if (target != null && target.mounted) {
          Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 300),
            alignment: 0.05,
          );
        }
      });
    }
  }

  void _addToSummary() {
    final estimate = _estimate;
    if (estimate == null) return;
    context.read<EstimatesController>().addToSummary(estimate);
    showMessage(
      context,
      'Added ${estimate.label} to the summary.',
      action: SnackBarAction(
        label: 'View',
        onPressed: () => context.go(Routes.summary),
      ),
    );
  }

  Future<void> _export() async {
    final estimate = _estimate;
    if (estimate == null) return;
    final result = await context.read<SheetSettingsController>().export([
      estimate,
    ]);
    if (!mounted) return;
    showMessage(
      context,
      result.message,
      action: result.status == SheetsExportStatus.missingSheetInfo
          ? SnackBarAction(
              label: 'Set up',
              onPressed: () => context.go(Routes.sheet),
            )
          : null,
    );
  }

  void _showInfo({required bool solution}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MaterialInfoSheet(
        title: solution ? "How it's calculated" : 'Definitions',
        sections: solution ? spec.solution : spec.definitions,
        references: solution ? const [] : spec.references,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expanded = WindowSize.of(context) == WindowSize.expanded;
    final inSummary = context.select<EstimatesController, bool>(
      (c) => _estimate != null && c.isInSummary(_estimate!.id),
    );
    final exporting = context.select<SheetSettingsController, bool>(
      (c) => c.isExporting,
    );

    final form = _CalculatorForm(
      spec: spec,
      formKey: _formKey,
      autovalidate: _autovalidate,
      text: _text,
      focus: _focus,
      selected: _selected,
      onSelect: _select,
      onCalculate: _calculate,
      onShowInfo: _showInfo,
    );
    final result = _estimate == null || _result == null
        ? null
        : ResultCard(
            key: _resultKey,
            estimate: _estimate!,
            result: _result!,
            stale: _stale,
            inSummary: inSummary,
            exporting: exporting,
            onAddToSummary: _addToSummary,
            onExport: _export,
          );

    return PageTitle(
      title: spec.name,
      child: Scaffold(
        appBar: AppBar(title: Text(spec.name)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          child: expanded
              ? ContentWidth(
                  maxWidth: 1100,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: form),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 4,
                        child: result ?? const ResultPlaceholder(),
                      ),
                    ],
                  ),
                )
              : ContentWidth(
                  maxWidth: 640,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      form,
                      if (result != null) ...[
                        const SizedBox(height: 24),
                        result,
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _CalculatorForm extends StatelessWidget {
  const _CalculatorForm({
    required this.spec,
    required this.formKey,
    required this.autovalidate,
    required this.text,
    required this.focus,
    required this.selected,
    required this.onSelect,
    required this.onCalculate,
    required this.onShowInfo,
  });

  final MaterialSpec spec;
  final GlobalKey<FormState> formKey;
  final AutovalidateMode autovalidate;
  final Map<String, TextEditingController> text;
  final Map<String, FocusNode> focus;
  final Map<String, String> selected;
  final void Function(String id, String? value) onSelect;
  final VoidCallback onCalculate;
  final void Function({required bool solution}) onShowInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final measurements = [
      for (final f in spec.numbers)
        if (!f.isPrice) f,
    ];
    final price = spec.numbers.firstWhere((f) => f.isPrice);
    final choices = spec.visibleChoices(selected);

    Widget numberField(NumberField f) {
      final isLast = f == price;
      return TextFormField(
        controller: text[f.id],
        focusNode: focus[f.id],
        decoration: InputDecoration(
          labelText: f.label,
          helperText: f.hint,
          prefixText: f.isPrice ? '₱ ' : null,
          suffixText: f.isPrice ? null : f.unit,
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: !f.integer),
        inputFormatters: [
          DecimalInputFormatter(allowDecimal: !f.integer),
          LengthLimitingTextInputFormatter(12),
        ],
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: isLast ? (_) => onCalculate() : null,
        validator: (value) => f.validate(value ?? ''),
      );
    }

    Widget choiceField(ChoiceField c) => DropdownButtonFormField<String>(
      key: ValueKey('choice-${c.id}'),
      initialValue: selected[c.id],
      isExpanded: true,
      decoration: InputDecoration(labelText: c.label, helperText: c.helper),
      hint: const Text('Choose one'),
      items: [
        for (final o in c.options)
          DropdownMenuItem(
            value: o.id,
            child: Text(o.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) => onSelect(c.id, value),
      validator: (value) =>
          c.option(value) == null ? 'Choose a ${c.label.toLowerCase()}' : null,
    );

    final fields = <Widget>[
      for (final f in measurements) numberField(f),
      for (final c in choices) choiceField(c),
      numberField(price),
    ];

    return Form(
      key: formKey,
      autovalidateMode: autovalidate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(spec.blurb, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => onShowInfo(solution: false),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Definitions'),
              ),
              OutlinedButton.icon(
                onPressed: () => onShowInfo(solution: true),
                icon: const Icon(Icons.functions),
                label: const Text("How it's calculated"),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 16.0;
              final twoColumns = constraints.maxWidth >= 480;
              final width = twoColumns
                  ? (constraints.maxWidth - gap) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: gap,
                runSpacing: 20,
                children: [
                  for (final f in fields) SizedBox(width: width, child: f),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onCalculate,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate'),
          ),
        ],
      ),
    );
  }
}
