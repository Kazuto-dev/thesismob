import 'dart:async';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../materials/items.dart';
import '../../materials/material_spec.dart';
import '../../router.dart';
import '../../state/appearance_controller.dart';
import '../../state/experience.dart';
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
  const CalculatorScreen({
    super.key,
    required this.spec,
    this.fromEstimateId,
    this.editProjectId,
  });

  final MaterialSpec spec;

  /// History entry or project item whose inputs prefill the form.
  final String? fromEstimateId;

  /// The project whose item [fromEstimateId] is being edited.
  final String? editProjectId;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _resultKey = GlobalKey();
  late final Map<String, TextEditingController> _text = {
    for (final f in widget.spec.numbers)
      f.id: TextEditingController(text: _shown(f).initial),
  };
  late final Map<String, FocusNode> _focus = {
    for (final f in widget.spec.numbers) f.id: FocusNode(),
  };
  late Map<String, String> _selected = widget.spec.initialChoices;
  final _mark = TextEditingController();
  late final EstimatesController _estimates;
  late final ProjectsController _projects;
  late final PriceBookController _prices;
  late final AppearanceController _appearance;
  late final AppLifecycleListener _lifecycle;

  /// The unit lengths are typed in. Inputs are saved in metres.
  late LengthUnit _lengthUnit;

  /// Whether the price field follows the price book. It stops once the
  /// user types their own price.
  bool _autoPrice = true;

  /// The history entry that matches the inputs, once recorded.
  Estimate? _recorded;

  /// The project item being edited, if any.
  Estimate? _editing;

  /// The item this visit last added to a project.
  Estimate? _added;

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
    _appearance = context.read<AppearanceController>()
      ..addListener(_unitChanged);
    _lengthUnit = _appearance.lengthUnit;
    _prefill();
    _applySuggestedPrice();
    for (final c in _text.values) {
      c.addListener(_changed);
    }
    _mark.addListener(_changed);
    _lifecycle = AppLifecycleListener(onHide: _recordNow);
  }

  /// [f] as the user sees it, in feet when they measure in feet.
  NumberField _shown(NumberField f) =>
      _lengthUnit == LengthUnit.feet ? f.inFeet() : f;

  /// A value typed into [shown], in the field's own unit. Feet are
  /// rounded to the millimetre so a value shown in feet reads back as the
  /// metres it came from.
  static double _toSaved(NumberField shown, double value) =>
      switch (shown.unit) {
        'ft' => _round(value / feetPerMetre, 3),
        'ft²' => _round(value / (feetPerMetre * feetPerMetre), 4),
        _ => value,
      };

  /// A saved value as text for [shown].
  static String _toText(NumberField shown, double value) {
    final v = switch (shown.unit) {
      'ft' => _round(value * feetPerMetre, 3),
      'ft²' => _round(value * feetPerMetre * feetPerMetre, 3),
      _ => value,
    };
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  static double _round(double v, int places) =>
      double.parse(v.toStringAsFixed(places));

  /// Converts what is typed in the length fields when the user switches
  /// between metres and feet.
  void _unitChanged() {
    final unit = _appearance.lengthUnit;
    if (!mounted || unit == _lengthUnit) return;
    final saved = <String, double>{};
    for (final f in spec.numbers) {
      final value = _shown(f).parse(_text[f.id]!.text);
      if (value != null && _text[f.id]!.text.trim().isNotEmpty) {
        saved[f.id] = _toSaved(_shown(f), value);
      }
    }
    setState(() {
      _lengthUnit = unit;
      for (final MapEntry(:key, :value) in saved.entries) {
        final f = spec.numbers.firstWhere((f) => f.id == key);
        if (f.unit == 'm' || f.unit == 'm²') {
          _text[key]!.text = _toText(_shown(f), value);
        }
      }
    });
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
    final editing = widget.editProjectId == null
        ? null
        : _projects
              .byId(widget.editProjectId!)
              ?.items
              .where((e) => e.id == id && e.materialId == spec.id)
              .firstOrNull;
    final saved =
        editing ??
        _estimates.history.where((e) => e.id == id).firstOrNull ??
        _projects.projects
            .expand((p) => p.items)
            .where((e) => e.id == id)
            .firstOrNull;
    if (saved == null || saved.materialId != spec.id) return;
    _editing = editing;
    _mark.text = saved.mark ?? '';
    for (final MapEntry(:key, :value) in saved.inputs.entries) {
      final f = spec.numbers.where((f) => f.id == key).firstOrNull;
      if (f != null) _text[key]!.text = _toText(_shown(f), value);
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
    _appearance.removeListener(_unitChanged);
    _mark.dispose();
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
      final shown = _shown(f);
      final value = shown.parse(_text[f.id]!.text);
      if (value == null) {
        missing.add(f.label);
      } else if (!(f.optional && value == 0)) {
        numbers[f.id] = _toSaved(shown, value);
      }
    }
    final choices = <String, String>{};
    for (final c in spec.visibleChoices(_selected)) {
      final option = c.option(_selected[c.id]);
      if (option == null) {
        missing.add(c.label);
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
    ).copyWith(mark: _mark.text);
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

  /// The project item being edited, while it is still in its project.
  Estimate? get _editingItem {
    final editing = _editing;
    final projectId = widget.editProjectId;
    if (editing == null || projectId == null) return null;
    return _projects.contains(editing.id, projectId: projectId)
        ? editing
        : null;
  }

  void _addToProject({String? projectId}) {
    final recorded = _ensureRecorded();
    final current = _currentEstimate();
    if (recorded == null || current == null) return;
    // The project keeps today's prices for the companion materials. An
    // estimate already in the project, e.g. under another mark, is added
    // again as a new item.
    final target = projectId ?? _projects.active.id;
    final estimate = current.withId(
      _projects.contains(recorded.id, projectId: target)
          ? Estimate.newId(DateTime.now())
          : recorded.id,
    );
    _projects.add(estimate, projectId: target);
    setState(() => _added = estimate);
    final project = _projects.byId(target)!;
    if (projectId != null) {
      context.go(Routes.projectById(target));
      showMessage(context, 'Added ${estimate.title} to ${project.name}.');
      return;
    }
    showMessage(
      context,
      'Added ${estimate.title} to ${project.name}.',
      action: SnackBarAction(
        label: context.tr('View'),
        onPressed: () => context.go(Routes.project),
      ),
    );
  }

  /// Saves the form over the project item being edited, keeping its note
  /// and its place in the project, then returns to the project.
  void _updateItem() {
    final editing = _editingItem;
    final current = _currentEstimate();
    final projectId = widget.editProjectId;
    if (editing == null || current == null || projectId == null) return;
    _recordNow();
    final updated = current
        .withId(editing.id)
        .copyWith(note: editing.note, source: editing.source);
    _projects.updateItem(updated, projectId: projectId);
    _editing = updated;
    context.go(Routes.projectById(projectId));
    showMessage(context, 'Updated ${updated.title}.');
  }

  void _cancelEdit() {
    final projectId = widget.editProjectId;
    context.go(
      projectId == null ? Routes.project : Routes.projectById(projectId),
    );
  }

  Future<void> _setLinePrice(EstimateLine line) async {
    final item = itemByKey(line.itemKey);
    final price = await showPriceDialog(
      context,
      title: line.label,
      unit: item?.unit ?? 'unit',
      initial: line.unitPrice,
      suggested: context.tr('Saved to your price book for later estimates'),
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
    final candidates = [?_added, ?_recorded];
    final editProjectId = widget.editProjectId;
    final (projectName, inProject, editing) = context
        .select<ProjectsController, (String, bool, bool)>((c) {
          final editing =
              editProjectId != null &&
              _editing != null &&
              c.contains(_editing!.id, projectId: editProjectId);
          final project = editing ? c.byId(editProjectId)! : c.active;
          // Already in the project, with the same inputs and name.
          final added =
              current != null &&
              project.items.any(
                (e) =>
                    candidates.any((x) => x.id == e.id) &&
                    e.sameCalculationAs(current) &&
                    e.mark == current.mark,
              );
          return (project.name, added, editing);
        });
    final suggested = _suggestedPrice;

    final form = _CalculatorForm(
      spec: spec,
      shown: _shown,
      lengthUnit: _lengthUnit,
      onLengthUnit: _appearance.setLengthUnit,
      text: _text,
      focus: _focus,
      selected: _selected,
      onSelect: _select,
      onShowInfo: _showInfo,
      onDone: twoPane ? null : _showResult,
      onPriceTyped: () => _autoPrice = false,
      mark: _mark,
      banner: editing
          ? _EditBanner(projectName: projectName, onCancel: _cancelEdit)
          : null,
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
              onUpdate: editing ? _updateItem : null,
              onAddNew: editing
                  ? () => _addToProject(projectId: editProjectId)
                  : null,
            ),
    );

    return PageTitle(
      title: context.materialName(spec),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            editing
                ? context.tr('Edit {material}', {
                    'material': context.materialName(spec),
                  })
                : context.materialName(spec),
          ),
        ),
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
                onUpdate: editing ? _updateItem : null,
                onShow: _showResult,
              ),
      ),
    );
  }
}

class _CalculatorForm extends StatefulWidget {
  const _CalculatorForm({
    required this.spec,
    required this.shown,
    required this.lengthUnit,
    required this.onLengthUnit,
    required this.text,
    required this.focus,
    required this.selected,
    required this.onSelect,
    required this.onShowInfo,
    required this.onDone,
    required this.onPriceTyped,
    required this.mark,
    this.priceNote,
    this.banner,
  });

  final MaterialSpec spec;

  /// A field as the user sees it, in their length unit.
  final NumberField Function(NumberField) shown;
  final LengthUnit lengthUnit;
  final ValueChanged<LengthUnit> onLengthUnit;
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

  /// The item's name or mark in a project.
  final TextEditingController mark;

  /// Shown above the form, e.g. while editing a project item.
  final Widget? banner;

  @override
  State<_CalculatorForm> createState() => _CalculatorFormState();
}

class _CalculatorFormState extends State<_CalculatorForm> {
  /// Options shown before "More options".
  static const _firstOptions = 3;

  bool _moreOptions = false;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final spec = w.spec;
    final selected = w.selected;
    final text = w.text;
    final focus = w.focus;
    final onSelect = w.onSelect;
    final onShowInfo = w.onShowInfo;
    final onDone = w.onDone;
    final theme = Theme.of(context);
    final numbers = [for (final f in spec.visibleNumbers(selected)) w.shown(f)];
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
    final hasLengths = measurements.any(
      (f) => const {'m', 'm²', 'ft', 'ft²'}.contains(f.unit),
    );
    final shownOptions = _moreOptions || options.length <= _firstOptions + 1
        ? options
        : options.take(_firstOptions).toList();
    final hidden = options.skip(shownOptions.length).toList();

    Widget numberField(NumberField f) => _NumberInput(
      key: ValueKey('number-${f.id}'),
      field: f,
      controller: text[f.id]!,
      focusNode: focus[f.id]!,
      isLast: f.id == last?.id,
      onDone: onDone,
      onChanged: f.isPrice ? (_) => w.onPriceTyped() : null,
    );

    Widget choice(ChoiceField c) => _ChoiceInput(
      field: c,
      selected: selected,
      onSelect: onSelect,
      definition: spec.definitions
          .where((d) => d.title.toLowerCase() == c.label.toLowerCase())
          .firstOrNull,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (w.banner != null) ...[w.banner!, const SizedBox(height: Space.lg)],
        Row(
          children: [
            IconTile.material(spec, size: 56),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.materialBlurb(spec),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  // The trade name too, as stores and builders call it.
                  if (context.plainWords) ...[
                    const SizedBox(height: Space.xs),
                    Text(
                      context.tr('Builders and stores call this: {name}', {
                        'name': context.tr(spec.name),
                      }),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
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
              label: Text(context.tr('Definitions')),
            ),
            OutlinedButton.icon(
              onPressed: () => onShowInfo(solution: true),
              icon: const Icon(Icons.functions, size: 18),
              label: Text(context.tr("How it's calculated")),
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        _FormSection(
          title: context.tr('Measurements'),
          trailing: hasLengths
              ? _LengthUnitToggle(unit: w.lengthUnit, onChanged: w.onLengthUnit)
              : null,
          children: [
            for (final c in leading) choice(c),
            _FieldGrid(
              children: [for (final f in measurements) numberField(f)],
            ),
          ],
        ),
        if (options.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          _FormSection(
            title: context.tr('Options'),
            children: [
              for (final c in shownOptions) choice(c),
              if (hidden.isNotEmpty)
                _MoreOptions(
                  summary: [
                    for (final c in hidden)
                      '${context.tr(c.label)}: '
                          '${context.tr(c.option(selected[c.id])?.label ?? 'not set')}',
                  ].join(' · '),
                  onOpen: () => setState(() => _moreOptions = true),
                ),
            ],
          ),
        ],
        if (prices.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          _FormSection(
            title: context.tr('Price'),
            children: [
              _FieldGrid(children: [for (final f in prices) numberField(f)]),
              ?w.priceNote,
            ],
          ),
        ],
        const SizedBox(height: Space.lg),
        _FormSection(
          title: context.tr('Name in the project'),
          children: [
            TextField(
              key: const ValueKey('mark'),
              controller: w.mark,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
              decoration: InputDecoration(
                labelText: context.tr('Name or mark (optional)'),
                hintText: context.tr('F1, Kitchen wall, 2nd floor slab'),
                helperText: context.tr('Shown in the bill of quantities'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Says that the form edits a project item, with a way back.
class _EditBanner extends StatelessWidget {
  const _EditBanner({required this.projectName, required this.onCancel});

  final String projectName;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.md,
          Space.sm,
          Space.md,
        ),
        child: Row(
          children: [
            Icon(Icons.edit_outlined, color: scheme.onSecondaryContainer),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Editing an item in {project}', {
                      'project': projectName,
                    }),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    context.tr(
                      'Change what you need, then choose Update item.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onCancel, child: Text(context.tr('Cancel'))),
          ],
        ),
      ),
    );
  }
}

/// A titled card grouping related inputs.
class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

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
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
                ?trailing,
              ],
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // The unit is always on show, not only once the field has focus, so a
    // length is never typed in the wrong unit unawares.
    Widget unit(String text, {required bool start}) => Padding(
      padding: EdgeInsetsDirectional.only(
        start: start ? Space.md : Space.sm,
        end: start ? Space.xs : Space.md,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
    const fit = BoxConstraints(minWidth: 0, minHeight: 0);
    final value = double.tryParse(controller.text.trim());
    // Asked even past the field's limit, where the likely unit helps most.
    final unusual = value != null && value > 0 && f.isUnusual(value);
    final input = TextFormField(
      controller: controller,
      focusNode: focusNode,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: context.tr(f.label),
        helperText: f.hint == null ? null : context.tr(f.hint!),
        prefixIcon: f.isPrice ? unit('₱', start: true) : null,
        prefixIconConstraints: fit,
        suffixIcon: f.isPrice || f.unit == null
            ? null
            : unit(f.unit!, start: false),
        suffixIconConstraints: fit,
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
    // Always a column, so the field keeps its state when the warning comes
    // and goes.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        input,
        if (unusual)
          _UnitWarning(field: f, value: value, controller: controller),
      ],
    );
  }
}

/// Asks about a value far above the usual, which is most often a
/// measurement in the wrong unit, and offers the likely one.
class _UnitWarning extends StatelessWidget {
  const _UnitWarning({
    required this.field,
    required this.value,
    required this.controller,
  });

  final NumberField field;
  final double value;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final meant = field.likelyMeant(value);
    final unit = field.unit ?? '';
    final fixed = meant == null ? null : formatNumber(meant.value);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: Space.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: palette.warning,
              ),
            ),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meant == null
                        ? context.tr(
                            '{value} is a lot for {field}. Check the unit.',
                            {
                              'value': '${formatNumber(value)} $unit',
                              'field': context.tr(field.label).toLowerCase(),
                            },
                          )
                        : context.tr(
                            '{value} is a lot for {field}. Did you type '
                            '{unit}?',
                            {
                              'value': '${formatNumber(value)} $unit',
                              'field': context.tr(field.label).toLowerCase(),
                              'unit': meant.unit,
                            },
                          ),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (fixed != null)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () =>
                          controller.text = fixed.replaceAll(',', ''),
                      child: Text(
                        context.tr('Use {value}', {'value': '$fixed $unit'}),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Metres or feet, for the length fields.
class _LengthUnitToggle extends StatelessWidget {
  const _LengthUnitToggle({required this.unit, required this.onChanged});

  final LengthUnit unit;
  final ValueChanged<LengthUnit> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr('Length unit'),
    child: SegmentedButton<LengthUnit>(
      showSelectedIcon: false,
      style: ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(
          value: LengthUnit.metres,
          label: Text(context.tr('m')),
          tooltip: context.tr('Metres'),
        ),
        ButtonSegment(
          value: LengthUnit.feet,
          label: Text(context.tr('ft')),
          tooltip: context.tr('Feet'),
        ),
      ],
      selected: {unit},
      onSelectionChanged: (s) => onChanged(s.first),
    ),
  );
}

/// The options left out until the user asks for them, with what they are
/// set to.
class _MoreOptions extends StatelessWidget {
  const _MoreOptions({required this.summary, required this.onOpen});

  final String summary;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'More options. $summary',
      excludeSemantics: true,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.sm),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('More options'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.expand_more, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
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
    this.definition,
  });

  final ChoiceField field;
  final Map<String, String> selected;
  final void Function(String id, String value) onSelect;

  /// What the choice means, from the material's definitions.
  final InfoSection? definition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = field;
    final value = c.option(selected[c.id])?.id;
    String name(ChoiceOption o) => context.tr(o.label);
    final labelLength = c.options.fold<int>(0, (n, o) => n + name(o).length);
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
                label: Text(name(o), textAlign: TextAlign.center),
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
              label: Text(name(o)),
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
        hint: Text(context.tr('Choose one')),
        items: [
          for (final o in c.options)
            DropdownMenuItem(
              value: o.id,
              child: Text(name(o), overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) {
          if (v != null) onSelect(c.id, v);
        },
      );
    }

    return Semantics(
      container: true,
      label: context.tr(c.label),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  context.tr(c.label),
                  style: theme.textTheme.labelLarge,
                ),
              ),
              if (definition != null)
                IconButton(
                  tooltip: context.tr('What is {term}?', {
                    'term': context.tr(c.label).toLowerCase(),
                  }),
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(32),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  iconSize: 18,
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (dialog) => AlertDialog(
                      title: Text(definition!.title),
                      content: Text(definition!.body),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialog).pop(),
                          child: Text(context.tr('OK')),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (c.helper != null) ...[
            const SizedBox(height: 2),
            Text(
              context.tr(c.helper!),
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
    this.onUpdate,
  });

  final CalcResult? result;

  /// Main material and companions together.
  final double? total;
  final bool inProject;
  final VoidCallback onAdd;
  final VoidCallback onShow;

  /// Set while editing a project item.
  final VoidCallback? onUpdate;

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
                        if (onUpdate != null)
                          FilledButton.icon(
                            onPressed: onUpdate,
                            icon: const Icon(Icons.check),
                            label: Text(context.tr('Update')),
                          )
                        else
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
