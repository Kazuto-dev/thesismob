import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/contract.dart';
import '../../data/contract_math.dart';
import '../../data/project.dart';
import '../../export/files.dart';
import '../../export/project_documents.dart';
import '../../state/profile_controller.dart';
import '../../state/projects_controller.dart';
// Loaded on first use, like the bill of quantities PDF.
import '../../export/contract_pdf.dart' deferred as contract_pdf;

Future<void> _save(
  BuildContext context,
  String name,
  Future<Uint8List> Function() make,
  String done,
) async {
  showMessage(context, context.tr('Preparing the PDF…'));
  try {
    final bytes = await make();
    final saved = await saveFile(name, bytes, 'application/pdf');
    if (!context.mounted) return;
    showMessage(
      context,
      saved ? context.tr(done) : "Downloads aren't supported here.",
    );
  } catch (_) {
    if (context.mounted) showMessage(context, "Couldn't make the PDF.");
  }
}

/// Downloads the quotation for the client.
Future<void> downloadQuotation(BuildContext context, Project project) {
  final profile = context.read<ProfileController>().profile;
  return _save(context, '${fileSlug(project, 'quotation')}.pdf', () async {
    await contract_pdf.loadLibrary();
    return contract_pdf.quotationPdf(project, profile);
  }, 'Downloaded the quotation.');
}

/// Downloads progress billing [index].
Future<void> downloadBilling(BuildContext context, Project project, int index) {
  final profile = context.read<ProfileController>().profile;
  return _save(
    context,
    '${fileSlug(project, 'billing-${index + 1}')}.pdf',
    () async {
      await contract_pdf.loadLibrary();
      return contract_pdf.billingPdf(project, profile, index);
    },
    'Downloaded the billing.',
  );
}

/// Opens progress billing [index] for editing, or a new one after the
/// last when [index] is null.
Future<void> editBilling(BuildContext context, Project project, int? index) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _BillingEditor(project: project, index: index),
      ),
    );

class _BillingEditor extends StatefulWidget {
  const _BillingEditor({required this.project, required this.index});

  final Project project;
  final int? index;

  @override
  State<_BillingEditor> createState() => _BillingEditorState();
}

class _BillingEditorState extends State<_BillingEditor> {
  late final List<ContractLine> _lines = contractLines(widget.project);
  late final List<Billing> _billings = widget.project.contract.billings;
  late final Billing? _previous = widget.index == null
      ? (_billings.isEmpty ? null : _billings.last)
      : (widget.index! > 0 ? _billings[widget.index! - 1] : null);
  late final Map<String, double> _progress = {
    ...?(widget.index == null
        ? _previous?.progress
        : _billings[widget.index!].progress),
  };
  late DateTime _date = widget.index == null
      ? DateTime.now()
      : _billings[widget.index!].date;
  late final Map<String, TextEditingController> _text = {
    for (final l in _lines)
      l.key: TextEditingController(text: _show(_progress[l.key] ?? 0)),
  };

  static String _show(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _setAll(double pct) => setState(() {
    for (final l in _lines) {
      final floor = _previous?.progress[l.key] ?? 0;
      final v = pct < floor ? floor : pct;
      _progress[l.key] = v;
      _text[l.key]!.text = _show(v);
    }
  });

  void _save() {
    final billing = Billing(
      id: widget.index == null
          ? ContractData.newId()
          : _billings[widget.index!].id,
      date: _date,
      progress: {
        for (final MapEntry(:key, :value) in _progress.entries)
          if (value > 0) key: value,
      },
    );
    context.read<ProjectsController>().updateContract(
      widget.project.id,
      (c) => c.copyWith(
        billings: widget.index == null
            ? [...c.billings, billing]
            : [
                for (final (i, b) in c.billings.indexed)
                  i == widget.index ? billing : b,
              ],
      ),
    );
    Navigator.of(context).pop();
  }

  void _delete() {
    context.read<ProjectsController>().updateContract(
      widget.project.id,
      (c) => c.copyWith(
        billings: [
          for (final (i, b) in c.billings.indexed)
            if (i != widget.index) b,
        ],
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final number = (widget.index ?? _billings.length) + 1;
    final draft = Billing(id: '', date: _date, progress: _progress);
    final toDate = accomplished(_lines, draft);
    final before = _previous == null ? 0.0 : accomplished(_lines, _previous);
    final price = contractPrice(widget.project);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Billing {n}', {'n': number})),
        actions: [
          if (widget.index != null)
            IconButton(
              tooltip: context.tr('Delete'),
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          Padding(
            padding: const EdgeInsets.only(right: Space.sm),
            child: FilledButton(
              onPressed: _save,
              child: Text(context.tr('Save')),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          Text(
            context.tr(
              'Enter how far each line is done, in percent, to date. Lines '
              'start from the last billing.',
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(_date.year - 3),
                    lastDate: DateTime(_date.year + 3),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(formatDate(_date)),
              ),
              for (final pct in [25, 50, 75, 100])
                ActionChip(
                  label: Text(context.tr('All {pct}%', {'pct': pct})),
                  onPressed: () => _setAll(pct.toDouble()),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.md),
              child: Column(
                children: [
                  KeyValueLine(
                    context.tr('Accomplished to date'),
                    '${formatMoney(toDate)} · '
                    '${formatNumber(price <= 0 ? 0 : (toDate / price * 1000).round() / 10)}%',
                    emphasize: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  KeyValueLine(
                    context.tr('This billing, before deductions'),
                    formatMoney(toDate - before),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          for (final l in _lines)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l.number} ${l.description}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          formatMoney(l.amount),
                          style: tabular(
                            theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.md),
                  SizedBox(
                    width: 96,
                    child: TextField(
                      controller: _text[l.key],
                      textAlign: TextAlign.end,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        const DecimalInputFormatter(),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      decoration: InputDecoration(
                        isDense: true,
                        suffixText: '%',
                        semanticCounterText: l.description,
                      ),
                      onChanged: (raw) {
                        final v = double.tryParse(raw.trim()) ?? 0;
                        setState(() => _progress[l.key] = v.clamp(0, 100));
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Asks for a variation order and adds it.
Future<void> addVariation(BuildContext context, Project project) async {
  final result = await showDialog<({String text, double amount})>(
    context: context,
    builder: (_) => const _AmountDialog(variation: true),
  );
  if (result == null || !context.mounted) return;
  context.read<ProjectsController>().updateContract(
    project.id,
    (c) => c.copyWith(
      variations: [
        ...c.variations,
        VariationOrder(
          id: ContractData.newId(),
          date: DateTime.now(),
          description: result.text,
          amount: result.amount,
        ),
      ],
    ),
  );
}

/// Asks for an expense and records it.
Future<void> addExpense(BuildContext context, Project project) async {
  final result =
      await showDialog<({String text, double amount, ExpenseKind kind})>(
        context: context,
        builder: (_) => const _AmountDialog(variation: false),
      );
  if (result == null || !context.mounted) return;
  context.read<ProjectsController>().updateContract(
    project.id,
    (c) => c.copyWith(
      expenses: [
        ...c.expenses,
        Expense(
          id: ContractData.newId(),
          date: DateTime.now(),
          description: result.text,
          kind: result.kind,
          amount: result.amount,
        ),
      ],
    ),
  );
}

/// A description and an amount: a variation order (added or taken out)
/// or an expense (with its kind).
class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.variation});

  final bool variation;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _description = TextEditingController();
  final _amount = TextEditingController();
  var _deduct = false;
  var _kind = ExpenseKind.materials;

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final value = double.tryParse(_amount.text.trim());
    final text = _description.text.trim();
    if (value == null || value <= 0 || text.isEmpty) return;
    Navigator.of(context).pop(
      widget.variation
          ? (text: text, amount: _deduct ? -value : value)
          : (text: text, amount: value, kind: _kind),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.variation;
    return AlertDialog(
      title: Text(context.tr(v ? 'Variation order' : 'Record an expense')),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _description,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.tr(v ? 'What changed' : 'What for'),
                hintText: context.tr(
                  v
                      ? 'Extra window in the kitchen'
                      : '50 bags of cement, week 2 payroll',
                ),
              ),
            ),
            const SizedBox(height: Space.md),
            if (v)
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, label: Text(context.tr('Added'))),
                  ButtonSegment(
                    value: true,
                    label: Text(context.tr('Taken out')),
                  ),
                ],
                selected: {_deduct},
                onSelectionChanged: (s) => setState(() => _deduct = s.first),
              )
            else
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  for (final k in ExpenseKind.values)
                    ChoiceChip(
                      label: Text(context.tr(k.label)),
                      selected: _kind == k,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _kind = k),
                    ),
                ],
              ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                const DecimalInputFormatter(),
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: InputDecoration(
                labelText: context.tr(
                  v ? 'Amount, with markups and VAT' : 'Amount',
                ),
                prefixText: '₱ ',
              ),
              onSubmitted: (_) => _save(),
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
          child: Text(context.tr(v ? 'Add' : 'Save')),
        ),
      ],
    );
  }
}
