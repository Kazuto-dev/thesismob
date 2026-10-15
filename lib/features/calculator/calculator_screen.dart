import 'dart:async';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../materials/items.dart';
import '../../materials/material_spec.dart';
import '../../router.dart';
import '../../state/estimates_controller.dart';
import '../../state/price_book_controller.dart';
import '../../state/projects_controller.dart';
import '../common/price_dialog.dart';
import '../projects/project_picker.dart';
import 'info_sheet.dart';
import 'result_panel.dart';

/// The state of the form: a result when every input is valid, otherwise
/// what is still missing.
class _Evaluation {
  const _Evaluation({
    this.result,
    this.error,
    this.missing = const [],
    this.numbers = const {},
    this.choices = const {},
  });

  final CalcResult? result;

  /// A problem with otherwise valid inputs, such as openings larger than
  /// the wall.
  final String? error;

  /// Labels of the inputs that are empty or invalid.
  final List<String> missing;
  final Map<String, double> numbers;
  final Map<String, String> choices;
}

/// One screen for every material, built from its [MaterialSpec]. The
/// estimate updates as the user types.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, required this.spec, this.fromEstimateId});

  final MaterialSpec spec;

  /// History entry whose inputs prefill the form.
  final String? fromEstimateId;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _resultKey = GlobalKey();
  late final Map<String, TextEditingController> _text = {
    for (final f in widget.spec.numbers)
      f.id: TextEditingController(text: f.initial),
  };
  late final Map<String, FocusNode> _focus = {
    for (final f in widget.spec.numbers) f.id: FocusNode(),
  };
  late Map<String, String> _selected = widget.spec.initialChoices;
  late final EstimatesController _estimates;
  late final ProjectsController _projects;
  late final PriceBookController _prices;
  late final AppLifecycleListener _lifecycle;

  /// Whether the price field follows the price book. It stops once the
  /// user types their own price.
  bool _autoPrice = true;

  /// The history entry that matches the inputs, once recorded.
  Estimate? _recorded;

  /// The history entry this visit created, updated in place as the user
  /// keeps editing.
  String? _visitEntryId;
  Timer? _recordTimer;

  MaterialSpec get spec => widget.spec;

  @override
  void initState() {
    super.initState();
    _estimates = context.read<EstimatesController>();
    _projects = context.read<ProjectsController>();
    _prices = context.read<PriceBookController>()..addListener(_pricesChanged);
    _prefill();
    _applySuggestedPrice();
    for (final c in _text.values) {
      c.addListener(_changed);
    }
    _lifecycle = AppLifecycleListener(onHide: _recordNow);
  }

  NumberField? get _priceField =>
      spec.visibleNumbers(_selected).where((f) => f.isPrice).firstOrNull;

  /// The price book's price for the main material with the chosen options.
  double? get _suggestedPrice =>
      _prices.suggest(spec.priceRef?.call(_selected));

  /// Fills the price field from the price book while the user has not
  /// typed a price of their own.
  void _applySuggestedPrice({bool force = false}) {
    if (!_autoPrice && !force) return;
    final field = _priceField;
    final price = _suggestedPrice;
    if (field == null || price == null) return;
    final text = price == price.roundToDouble()
        ? price.toInt().toString()
        : price.toStringAsFixed(2);
    final controller = _text[field.id]!;
    if (controller.text != text) controller.text = text;
    _autoPrice = true;
  }

  void _pricesChanged() {
    if (!mounted) return;
    setState(_applySuggestedPrice);
  }

  void _prefill() {
    final id = widget.fromEstimateId;
    if (id == null) return;
    final saved =
        _estimates.history.where((e) => e.id == id).firstOrNull ??
        _projects.projects
            .expand((p) => p.items)
            .where((e) => e.id == id)
            .firstOrNull;
    if (saved == null || saved.materialId != spec.id) return;
    for (final MapEntry(:key, :value) in saved.inputs.entries) {
      _text[key]?.text = value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toString();
    }
    _selected = {..._selected, ...saved.choices};
    _recorded = saved;
    final price = _priceField;
    if (price != null && (saved.inputs[price.id] ?? 0) > 0) _autoPrice = false;
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    final pending = _pendingEstimate();
    if (pending != null) {
      // Recording notifies listeners, which must not happen while the
      // tree is being torn down.
      scheduleMicrotask(() {
        if (_estimates.isActive) _record(pending);
      });
    }
    _lifecycle.dispose();
    _prices.removeListener(_pricesChanged);
    for (final c in _text.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _changed() {
    setState(() {});
    _scheduleRecord();
  }

  void _select(String id, String value) {
    setState(() {
      _selected = {..._selected, id: value};
      _applySuggestedPrice();
    });
    _scheduleRecord();
  }

  void _scheduleRecord() {
    _recordTimer?.cancel();
    _recordTimer = Timer(const Duration(milliseconds: 1200), _recordNow);
  }

  _Evaluation _evaluate() {
    final missing = <String>[];
    final numbers = <String, double>{};
    for (final f in spec.visibleNumbers(_selected)) {
      final value = f.parse(_text[f.id]!.text);
      if (value == null) {
        missing.add(f.label.toLowerCase());
      } else if (!(f.optional && value == 0)) {
        numbers[f.id] = value;
      }
    }
    final choices = <String, String>{};
    for (final c in spec.visibleChoices(_selected)) {
      final option = c.option(_selected[c.id]);
      if (option == null) {
        missing.add(c.label.toLowerCase());
      } else {
        choices[c.id] = option.id;
      }
    }
    if (missing.isNotEmpty) return _Evaluation(missing: missing);
    try {
      return _Evaluation(
        result: spec.calculate(numbers, choices),
        numbers: numbers,
        choices: choices,
      );
    } on ArgumentError catch (e) {
      return _Evaluation(error: '${e.message}');
    }
  }

  Estimate? _currentEstimate([_Evaluation? evaluation]) {
    final e = evaluation ?? _evaluate();
    final result = e.result;
    if (result == null) return null;
    return Estimate.fromResult(
      materialId: spec.id,
      result: result,
      inputs: e.numbers,
      choices: e.choices,
      priceOf: _prices.priceOf,
    );
  }

  /// The current estimate when it is not yet in the history.
  Estimate? _pendingEstimate() {
    final current = _currentEstimate();
    if (current == null) return null;
    final recorded = _recorded;
    if (recorded != null && recorded.sameCalculationAs(current)) return null;
    return current;
  }

  void _recordNow() {
    _recordTimer?.cancel();
    final pending = _pendingEstimate();
    if (pending != null) _record(pending);
  }

  /// Saves [estimate] to the history, replacing this visit's earlier
  /// entry unless that one went into a project.
  Estimate _record(Estimate estimate) {
    final visit = _visitEntryId;
    final replaced = visit != null && !_projects.isInAnyProject(visit)
        ? _estimates.replaceInHistory(visit, estimate)
        : null;
    final stored = replaced ?? _estimates.record(estimate);
    _visitEntryId = stored.id;
    if (mounted) setState(() => _recorded = stored);
    return stored;
  }

  /// The history entry for the current inputs, recording it if needed.
  Estimate? _ensureRecorded() {
    final current = _currentEstimate();
    if (current == null) return null;
    final recorded = _recorded;
    if (recorded != null && recorded.sameCalculationAs(current)) {
      return recorded;
    }
    _recordTimer?.cancel();
    return _record(current);
  }

  void _addToProject() {
    final recorded = _ensureRecorded();
    final current = _currentEstimate();
    if (recorded == null || current == null) return;
    // The project keeps today's prices for the companion materials.
    final estimate = current.withId(recorded.id);
    _projects.add(estimate);
    showMessage(
      context,
      'Added ${estimate.label} to ${_projects.active.name}.',
      action: SnackBarAction(
        label: 'View',
        onPressed: () => context.go(Routes.project),
      ),
    );
  }

  Future<void> _setLinePrice(EstimateLine line) async {
    final item = itemByKey(line.itemKey);
    final price = await showPriceDialog(
      context,
      title: line.label,
      unit: item?.unit ?? 'unit',
      initial: line.unitPrice,
      suggested: 'Saved to your price book for later estimates',
    );
    if (price != null) _prices.setPrice(line.itemKey, price);
  }

  void _showInfo({required bool solution}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => MaterialInfoSheet(
        spec: spec,
        title: solution ? "How it's calculated" : 'Definitions',
        sections: solution ? spec.solution : spec.definitions,
        references: solution ? spec.references : const [],
      ),
    );
  }

  void _showResult() {
    final target = _resultKey.currentContext;
    if (target == null) return;
    FocusScope.of(context).unfocus();
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.of(context);
    final twoPane = size == WindowSize.expanded;
    final evaluation = _evaluate();
    final result = evaluation.result;
    context.watch<PriceBookController>();
    final current = _currentEstimate(evaluation);
    final recorded = _recorded;
    final (projectName, inProject) = context
        .select<ProjectsController, (String, bool)>(
          (c) => (
            c.active.name,
            current != null &&
                recorded != null &&
                recorded.sameCalculationAs(current) &&
                c.contains(recorded.id),
          ),
        );
    final suggested = _suggestedPrice;

    final form = _CalculatorForm(
      spec: spec,
      text: _text,
      focus: _focus,
      selected: _selected,
      onSelect: _select,
      onShowInfo: _showInfo,
      onDone: twoPane ? null : _showResult,
      onPriceTyped: () => _autoPrice = false,
      priceNote: suggested == null
          ? null
          : _PriceNote(
              suggested: suggested,
              following: _autoPrice,
              region: _prices.region,
              onUse: () => setState(() => _applySuggestedPrice(force: true)),
            ),
    );
    final panel = KeyedSubtree(
      key: _resultKey,
      child: result == null
          ? ResultPending(
              spec: spec,
              missing: evaluation.missing,
              error: evaluation.error,
            )
          : ResultPanel(
              spec: spec,
              result: result,
              estimate: current!,
              projectName: projectName,
              inProject: inProject,
              onAdd: _addToProject,
              onChangeProject: () => showProjectPicker(context),
              onSetPrice: _setLinePrice,
            ),
    );

    return PageTitle(
      title: spec.name,
      child: Scaffold(
        appBar: AppBar(title: Text(spec.name)),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: Space.sm,
            bottom: bottomClearance(context),
          ),
          child: ContentWidth(
            maxWidth: twoPane ? 1120 : 680,
            child: twoPane
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 11, child: form),
                      const SizedBox(width: Space.xl),
                      Expanded(flex: 9, child: panel),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      form,
                      const SizedBox(height: Space.xl),
                      panel,
                    ],
                  ),
          ),
        ),
        bottomNavigationBar: twoPane
            ? null
            : _ResultBar(
                result: result,
                total: current?.grandTotal,
                inProject: inProject,
                onAdd: _addToProject,
                onShow: _showResult,
              ),
      ),
    );
  }
}

class _CalculatorForm extends StatelessWidget {
  const _CalculatorForm({
    required this.spec,
    required this.text,
    required this.focus,
    required this.selected,
    required this.onSelect,
    required this.onShowInfo,
    required this.onDone,
    required this.onPriceTyped,
    this.priceNote,
  });

  final MaterialSpec spec;
  final Map<String, TextEditingController> text;
  final Map<String, FocusNode> focus;
  final Map<String, String> selected;
  final void Function(String id, String value) onSelect;
  final void Function({required bool solution}) onShowInfo;
  final VoidCallback? onDone;

  /// Called when the user types in a price field.
  final VoidCallback onPriceTyped;

  /// Where the price came from, shown under the price field.
  final Widget? priceNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numbers = spec.visibleNumbers(selected);
    final measurements = [
      for (final f in numbers)
        if (!f.isPrice) f,
    ];
    final prices = [
      for (final f in numbers)
        if (f.isPrice) f,
    ];
    final choices = spec.visibleChoices(selected);
    final leading = [
      for (final c in choices)
        if (c.leading) c,
    ];
    final options = [
      for (final c in choices)
        if (!c.leading) c,
    ];
    final last = numbers.isEmpty ? null : numbers.last;

    Widget numberField(NumberField f) => _NumberInput(
      key: ValueKey('number-${f.id}'),
      field: f,
      controller: text[f.id]!,
      focusNode: focus[f.id]!,
      isLast: f == last,
      onDone: onDone,
      onChanged: f.isPrice ? (_) => onPriceTyped() : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconTile.material(spec, size: 56),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Text(
                spec.blurb,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () => onShowInfo(solution: false),
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('Definitions'),
            ),
            OutlinedButton.icon(
              onPressed: () => onShowInfo(solution: true),
              icon: const Icon(Icons.functions, size: 18),
              label: const Text("How it's calculated"),
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        _FormSection(
          title: 'Measurements',
          children: [
            for (final c in leading)
              _ChoiceInput(field: c, selected: selected, onSelect: onSelect),
            _FieldGrid(
              children: [for (final f in measurements) numberField(f)],
            ),
          ],
        ),
        if (options.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          _FormSection(
            title: 'Options',
            children: [
              for (final c in options)
                _ChoiceInput(field: c, selected: selected, onSelect: onSelect),
            ],
          ),
        ],
        if (prices.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          _FormSection(
            title: 'Price',
            children: [
              _FieldGrid(children: [for (final f in prices) numberField(f)]),
              ?priceNote,
            ],
          ),
        ],
      ],
    );
  }
}

/// A titled card grouping related inputs.
class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.lg,
          Space.lg,
          Space.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
            for (final child in children) ...[
              const SizedBox(height: Space.lg),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// Number fields in two columns when there is room, one otherwise.
class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = Space.lg;
      final twoColumns = constraints.maxWidth >= 440 && children.length > 1;
      final width = twoColumns
          ? (constraints.maxWidth - gap) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: gap,
        runSpacing: Space.lg,
        children: [for (final f in children) SizedBox(width: width, child: f)],
      );
    },
  );
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    super.key,
    required this.field,
    required this.controller,
    required this.focusNode,
    required this.isLast,
    required this.onDone,
    this.onChanged,
  });

  final NumberField field;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLast;
  final VoidCallback? onDone;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final f = field;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: f.label,
        helperText: f.hint,
        prefixText: f.isPrice ? '₱ ' : null,
        suffixText: f.isPrice ? null : f.unit,
      ),
      style: tabular(Theme.of(context).textTheme.bodyLarge),
      keyboardType: TextInputType.numberWithOptions(decimal: !f.integer),
      inputFormatters: [
        DecimalInputFormatter(allowDecimal: !f.integer),
        LengthLimitingTextInputFormatter(12),
      ],
      textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: isLast && onDone != null ? (_) => onDone!() : null,
      onChanged: onChanged,
      validator: (value) => f.validate(value ?? ''),
    );
  }
}

/// A choice shown as a segmented button, a set of chips or a menu,
/// depending on how many options it has.
class _ChoiceInput extends StatelessWidget {
  const _ChoiceInput({
    required this.field,
    required this.selected,
    required this.onSelect,
  });

  final ChoiceField field;
  final Map<String, String> selected;
  final void Function(String id, String value) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = field;
    final value = c.option(selected[c.id])?.id;
    final labelLength = c.options.fold<int>(0, (n, o) => n + o.label.length);
    final segmented = c.options.length <= 4 && labelLength <= 34;

    final Widget input;
    if (segmented) {
      input = SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          segments: [
            for (final o in c.options)
              ButtonSegment(
                value: o.id,
                label: Text(o.label, textAlign: TextAlign.center),
              ),
          ],
          selected: {?value},
          emptySelectionAllowed: value == null,
          showSelectedIcon: false,
          onSelectionChanged: (s) {
            if (s.isNotEmpty) onSelect(c.id, s.first);
          },
        ),
      );
    } else if (c.options.length <= 8) {
      input = Wrap(
        spacing: Space.sm,
        runSpacing: Space.sm,
        children: [
          for (final o in c.options)
            ChoiceChip(
              label: Text(o.label),
              selected: o.id == value,
              showCheckmark: false,
              onSelected: (_) => onSelect(c.id, o.id),
            ),
        ],
      );
    } else {
      input = DropdownButtonFormField<String>(
        key: ValueKey('choice-${c.id}'),
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(),
        hint: const Text('Choose one'),
        items: [
          for (final o in c.options)
            DropdownMenuItem(
              value: o.id,
              child: Text(o.label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) {
          if (v != null) onSelect(c.id, v);
        },
      );
    }

    return Semantics(
      container: true,
      label: c.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.label, style: theme.textTheme.labelLarge),
          if (c.helper != null) ...[
            const SizedBox(height: 2),
            Text(
              c.helper!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Space.sm),
          input,
        ],
      ),
    );
  }
}

/// The live total pinned above the navigation bar on phones and tablets.
class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.result,
    required this.total,
    required this.inProject,
    required this.onAdd,
    required this.onShow,
  });

  final CalcResult? result;

  /// Main material and companions together.
  final double? total;
  final bool inProject;
  final VoidCallback onAdd;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: r == null
          ? const SizedBox(width: double.infinity)
          : InkPanel(
              grid: false,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Radii.lg),
              ),
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.md,
                Space.md,
                Space.md,
              ),
              child: SafeArea(
                top: false,
                child: Builder(
                  builder: (context) {
                    final theme = Theme.of(context);
                    final palette = AppPalette.of(context);
                    return Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            button: true,
                            liveRegion: true,
                            label:
                                'Estimate ${formatMoney(total ?? r.total)} for '
                                '${formatQuantity(r.quantity, r.unit)}. '
                                'Show details',
                            excludeSemantics: true,
                            child: InkWell(
                              onTap: onShow,
                              borderRadius: BorderRadius.circular(Radii.md),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: Space.xs,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      formatQuantity(r.quantity, r.unit),
                                      style: tabular(
                                        theme.textTheme.labelLarge?.copyWith(
                                          color: palette.onInkMuted,
                                        ),
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        formatMoney(total ?? r.total),
                                        style: tabular(
                                          theme.textTheme.titleLarge?.copyWith(
                                            color: palette.inkAccent,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Space.md),
                        FilledButton.icon(
                          onPressed: inProject ? null : onAdd,
                          icon: Icon(inProject ? Icons.check : Icons.add),
                          label: Text(inProject ? 'Added' : 'Add'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}

/// Where the suggested price came from, or a way back to it after the user
/// typed their own.
class _PriceNote extends StatelessWidget {
  const _PriceNote({
    required this.suggested,
    required this.following,
    required this.region,
    required this.onUse,
  });

  final double suggested;
  final bool following;
  final PriceRegion region;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    if (following) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.sell_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              'From your price book (${region.label}). Type your supplier\'s '
              'price to use it instead.',
              style: style,
            ),
          ),
        ],
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onUse,
        icon: const Icon(Icons.sell_outlined, size: 18),
        label: Text('Use price book price, ${formatMoney(suggested)}'),
      ),
    );
  }
}
