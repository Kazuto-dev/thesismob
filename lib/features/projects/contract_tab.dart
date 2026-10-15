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
import '../../materials/material_spec.dart';
import '../../state/projects_controller.dart';
import 'contract_actions.dart';

/// What follows the estimate once a job goes ahead: the quotation, the
/// schedule, progress billings, variation orders and actual costs.
class ContractTab extends StatelessWidget {
  const ContractTab({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _QuotationCard(project: project),
      const SizedBox(height: Space.lg),
      _ScheduleCard(project: project),
      const SizedBox(height: Space.lg),
      _BillingCard(project: project),
      const SizedBox(height: Space.lg),
      _VariationsCard(project: project),
      const SizedBox(height: Space.lg),
      _CostsCard(project: project),
    ],
  );
}

void _update(
  BuildContext context,
  Project project,
  ContractData Function(ContractData) change,
) => context.read<ProjectsController>().updateContract(project.id, change);

/// A titled card.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.children,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: Space.sm),
                ],
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: Space.xs),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            for (final c in children) ...[const SizedBox(height: Space.md), c],
          ],
        ),
      ),
    );
  }
}

/// A number that saves as the user types.
class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.max = 100,
  });

  final String label;
  final double value;
  final String? suffix;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final _controller = TextEditingController(
    text: formatNumber(widget.value).replaceAll(',', ''),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      const DecimalInputFormatter(),
      LengthLimitingTextInputFormatter(8),
    ],
    style: tabular(Theme.of(context).textTheme.bodyLarge),
    decoration: InputDecoration(
      labelText: widget.label,
      suffixText: widget.suffix,
      isDense: true,
    ),
    onChanged: (raw) {
      final v = double.tryParse(raw.trim());
      if (v != null && v >= 0 && v <= widget.max) widget.onChanged(v);
    },
  );
}

class _QuotationCard extends StatelessWidget {
  const _QuotationCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final t = project.contract.terms;
    void terms(QuoteTerms Function(QuoteTerms) change) =>
        _update(context, project, (c) => c.copyWith(terms: change(c.terms)));
    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: Space.md),
        Expanded(child: b),
      ],
    );
    return _Panel(
      icon: Icons.request_quote_outlined,
      title: context.tr('Quotation'),
      subtitle: context.tr(
        'A quotation for the client: your business details, the scope by '
        'trade, the price, the payment terms and a schedule.',
      ),
      children: [
        pair(
          _NumberField(
            label: context.tr('Valid for'),
            suffix: context.tr('days'),
            value: t.validityDays,
            max: 365,
            onChanged: (v) => terms((x) => x.copyWith(validityDays: v)),
          ),
          _NumberField(
            label: context.tr('Warranty'),
            suffix: context.tr('months'),
            value: t.warrantyMonths,
            max: 120,
            onChanged: (v) => terms((x) => x.copyWith(warrantyMonths: v)),
          ),
        ),
        pair(
          _NumberField(
            label: context.tr('Downpayment'),
            suffix: '%',
            value: t.downpaymentPct,
            max: 90,
            onChanged: (v) => terms((x) => x.copyWith(downpaymentPct: v)),
          ),
          _NumberField(
            label: context.tr('Retention'),
            suffix: '%',
            value: t.retentionPct,
            max: 50,
            onChanged: (v) => terms((x) => x.copyWith(retentionPct: v)),
          ),
        ),
        _TextArea(
          label: context.tr('Inclusions'),
          hint: context.tr('One per line, e.g. Supply of materials and labour'),
          value: t.inclusions,
          onChanged: (v) => terms((x) => x.copyWith(inclusions: v)),
        ),
        _TextArea(
          label: context.tr('Exclusions'),
          hint: context.tr('One per line, e.g. Building permit fees'),
          value: t.exclusions,
          onChanged: (v) => terms((x) => x.copyWith(exclusions: v)),
          action: t.exclusions.isEmpty
              ? TextButton(
                  onPressed: () => terms(
                    (x) => x.copyWith(exclusions: QuoteTerms.defaultExclusions),
                  ),
                  child: Text(context.tr('Use common exclusions')),
                )
              : null,
        ),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            FilledButton.icon(
              onPressed: project.items.isEmpty
                  ? null
                  : () => downloadQuotation(context, project),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(context.tr('Download quotation')),
            ),
          ],
        ),
      ],
    );
  }
}

/// Multi-line text that saves as the user types.
class _TextArea extends StatefulWidget {
  const _TextArea({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.action,
  });

  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  final Widget? action;

  @override
  State<_TextArea> createState() => _TextAreaState();
}

class _TextAreaState extends State<_TextArea> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(_TextArea old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: _controller,
        minLines: 2,
        maxLines: 6,
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: [LengthLimitingTextInputFormatter(1000)],
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          alignLabelWithHint: true,
        ),
        onChanged: widget.onChanged,
      ),
      ?widget.action,
    ],
  );
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.project});

  final Project project;

  Future<void> _pickStart(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: project.contract.startDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && context.mounted) {
      _update(context, project, (c) => c.copyWith(startDate: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedule = Schedule.of(project);
    final start = project.contract.startDate;
    final finish = start == null
        ? null
        : Schedule.addWorkingDays(start, schedule.days);
    final weeks = schedule.weeks.ceil();
    return _Panel(
      icon: Icons.calendar_month_outlined,
      title: context.tr('Schedule'),
      subtitle: context.tr(
        'Worked out from each item\'s crew-days and the crews working at '
        'once, six working days a week. A planning guide, not a promise.',
      ),
      children: [
        Text(
          schedule.days <= 0
              ? context.tr('Add estimates to see a schedule.')
              : context.tr('About {weeks} weeks ({days} working days)', {
                  'weeks': weeks,
                  'days': formatNumber(schedule.days),
                }),
          style: theme.textTheme.titleSmall,
        ),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickStart(context),
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(
                start == null
                    ? context.tr('Set start date')
                    : context.tr('Starts {date}', {'date': formatDate(start)}),
              ),
            ),
            if (finish != null)
              Text(
                context.tr('Finishes about {date}', {
                  'date': formatDate(finish),
                }),
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
        Text(
          context.tr('Crews working at once'),
          style: theme.textTheme.labelLarge,
        ),
        Wrap(
          spacing: Space.md,
          runSpacing: Space.md,
          children: [
            for (final trade in MaterialCategory.values)
              SizedBox(
                width: 150,
                child: _NumberField(
                  label: context.tr(trade.label),
                  value: project.contract.crewsFor(trade.name),
                  max: 20,
                  onChanged: (v) {
                    if (v < 1) return;
                    _update(
                      context,
                      project,
                      (c) => c.copyWith(crews: {...c.crews, trade.name: v}),
                    );
                  },
                ),
              ),
          ],
        ),
        if (schedule.tasks.isNotEmpty) ...[
          _Gantt(schedule: schedule),
          _SCurve(points: schedule.sCurve),
        ],
      ],
    );
  }
}

/// The schedule as bars along the working days.
class _Gantt extends StatelessWidget {
  const _Gantt({required this.schedule});

  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final total = schedule.days <= 0 ? 1.0 : schedule.days;
    return Semantics(
      label: context.tr('Schedule by phase'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final t in schedule.tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.tr(t.label)} · '
                    '${context.tr(t.trade?.label ?? 'Other')} · '
                    '${formatNumber(t.days)} ${context.tr('days')}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  LayoutBuilder(
                    builder: (context, c) => Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                        ),
                        Positioned(
                          left: c.maxWidth * t.start / total,
                          width: (c.maxWidth * t.days / total).clamp(
                            3,
                            c.maxWidth,
                          ),
                          top: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: palette.category(t.trade).chart,
                              borderRadius: BorderRadius.circular(Radii.sm),
                            ),
                          ),
                        ),
                      ],
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

/// The planned cumulative progress week by week.
class _SCurve extends StatelessWidget {
  const _SCurve({required this.points});

  final List<double> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (points.isEmpty) return const SizedBox.shrink();
    final half = points.indexWhere((p) => p >= 50) + 1;
    return Semantics(
      label: context.tr(
        'S-curve: half the work done by week {half} of {weeks}',
        {'half': half, 'weeks': points.length},
      ),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Planned progress (S-curve)'),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: Space.sm),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _CurvePainter(
                points,
                line: theme.colorScheme.primary,
                grid: theme.colorScheme.outlineVariant,
                text: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                weekLabel: context.tr('Week'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter(
    this.points, {
    required this.line,
    required this.grid,
    required this.text,
    required this.weekLabel,
  });

  final List<double> points;
  final Color line;
  final Color grid;
  final TextStyle text;
  final String weekLabel;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0;
    const bottom = 18.0;
    final w = size.width - left;
    final h = size.height - bottom;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    void label(String s, Offset at, {bool right = false}) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: text),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, right ? at - Offset(tp.width, tp.height / 2) : at);
    }

    for (final pct in [0, 50, 100]) {
      final y = h - h * pct / 100;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
      label('$pct%', Offset(left - 4, y), right: true);
    }
    final n = points.length;
    final path = Path()..moveTo(left, h);
    for (var i = 0; i < n; i++) {
      path.lineTo(left + w * (i + 1) / n, h - h * points[i] / 100);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    label('$weekLabel 1', Offset(left, h + 2));
    label('$n', Offset(size.width - 12, h + 2));
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.points != points || old.line != line;
}

class _BillingCard extends StatelessWidget {
  const _BillingCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statements = billingStatements(project);
    final terms = project.contract.terms;
    return _Panel(
      icon: Icons.receipt_long_outlined,
      title: context.tr('Progress billing'),
      subtitle: context.tr(
        'Bill the client for work done: each line\'s percent complete, less '
        'the downpayment recouped and the retention held.',
      ),
      children: [
        KeyValueLine(
          context.tr('Contract price'),
          formatMoney(contractPrice(project)),
          emphasize: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
        if (terms.downpaymentPct > 0)
          KeyValueLine(
            context.tr('Downpayment, {pct}%', {
              'pct': formatNumber(terms.downpaymentPct),
            }),
            formatMoney(downpayment(project)),
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
        for (final s in statements)
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                context.tr('Billing {n} · {date}', {
                  'n': s.number,
                  'date': formatDate(s.date),
                }),
              ),
              subtitle: Text(
                context.tr('{pct}% complete · net due {amount}', {
                  'pct': formatNumber((s.percentComplete * 10).round() / 10),
                  'amount': formatMoney(s.netDue),
                }),
                style: tabular(theme.textTheme.bodySmall),
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: context.tr('Download billing {n}', {
                      'n': s.number,
                    }),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: () =>
                        downloadBilling(context, project, s.number - 1),
                  ),
                  IconButton(
                    tooltip: context.tr('Edit billing {n}', {'n': s.number}),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        editBilling(context, project, s.number - 1),
                  ),
                ],
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: project.items.isEmpty
                ? null
                : () => editBilling(context, project, null),
            icon: const Icon(Icons.add),
            label: Text(context.tr('New progress billing')),
          ),
        ),
      ],
    );
  }
}

class _VariationsCard extends StatelessWidget {
  const _VariationsCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final variations = project.contract.variations;
    return _Panel(
      icon: Icons.difference_outlined,
      title: context.tr('Variation orders'),
      subtitle: context.tr(
        'Work added or taken out after the contract was agreed. They change '
        'the contract price and can be billed.',
      ),
      children: [
        for (final (i, v) in variations.indexed)
          KeyValueLine(
            'VO-${i + 1} · ${v.description}',
            '${v.amount < 0 ? '−' : '+'}${formatMoney(v.amount.abs())}',
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
        if (variations.isNotEmpty)
          KeyValueLine(
            context.tr('Revised contract price'),
            formatMoney(contractPrice(project)),
            emphasize: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => addVariation(context, project),
            icon: const Icon(Icons.add),
            label: Text(context.tr('Add a variation order')),
          ),
        ),
      ],
    );
  }
}

class _CostsCard extends StatelessWidget {
  const _CostsCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = project.breakdown;
    final expenses = project.contract.expenses;
    final budget = {
      ExpenseKind.materials: b.materials,
      ExpenseKind.labour: b.labour + b.tools,
      ExpenseKind.equipment: b.equipment,
      ExpenseKind.subcontract: 0.0,
      ExpenseKind.other: b.hauling + b.general,
    };
    final actual = {
      for (final k in ExpenseKind.values)
        k: expenses
            .where((e) => e.kind == k)
            .fold<double>(0, (s, e) => s + e.amount),
    };
    final spent = project.contract.spent;
    final statements = billingStatements(project);
    final done = statements.isEmpty ? 0.0 : statements.last.percentComplete;
    return _Panel(
      icon: Icons.account_balance_wallet_outlined,
      title: context.tr('Actual costs'),
      subtitle: context.tr(
        'Record what you spend to compare it with the budget as the work '
        'goes on.',
      ),
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(),
            1: FixedColumnWidth(108),
            2: FixedColumnWidth(108),
          },
          children: [
            TableRow(
              children: [
                Text('', style: theme.textTheme.labelLarge),
                Text(
                  context.tr('Budget'),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelLarge,
                ),
                Text(
                  context.tr('Spent'),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
            for (final k in ExpenseKind.values)
              if ((budget[k] ?? 0) > 0 || (actual[k] ?? 0) > 0)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(context.tr(k.label)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        formatMoney(budget[k] ?? 0),
                        textAlign: TextAlign.right,
                        style: tabular(theme.textTheme.bodyMedium),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        formatMoney(actual[k] ?? 0),
                        textAlign: TextAlign.right,
                        style: tabular(
                          theme.textTheme.bodyMedium?.copyWith(
                            color: (actual[k] ?? 0) > (budget[k] ?? 0)
                                ? theme.colorScheme.error
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          ],
        ),
        Text(
          context.tr(
            'Spent {spent} of a {direct} direct cost ({pct}%); the work is '
            '{done}% complete by the last billing.',
            {
              'spent': formatMoney(spent),
              'direct': formatMoney(b.direct),
              'pct': b.direct <= 0
                  ? '0'
                  : formatNumber((spent / b.direct * 1000).round() / 10),
              'done': formatNumber((done * 10).round() / 10),
            },
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        for (final e in expenses.reversed.take(5))
          KeyValueLine(
            '${formatDate(e.date)} · ${e.description}',
            formatMoney(e.amount),
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => addExpense(context, project),
            icon: const Icon(Icons.add),
            label: Text(context.tr('Record an expense')),
          ),
        ),
      ],
    );
  }
}
