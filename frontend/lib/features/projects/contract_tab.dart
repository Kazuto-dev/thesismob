import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/contract.dart';
import '../../data/contract_math.dart';
import '../../data/job_plan.dart';
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
      _CashFlowCard(project: project),
      const SizedBox(height: Space.lg),
      _PurchaseCard(project: project),
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
        pair(
          DropdownButtonFormField<ClientType>(
            initialValue: t.client,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('Client'),
              isDense: true,
            ),
            items: [
              for (final c in ClientType.values)
                DropdownMenuItem(
                  value: c,
                  child: Text(
                    context.tr(c.label),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (c) {
              if (c != null) terms((x) => x.copyWith(client: c));
            },
          ),
          _NumberField(
            label: context.tr('Client pays within'),
            suffix: context.tr('days'),
            value: t.paymentDays,
            max: 180,
            onChanged: (v) => terms((x) => x.copyWith(paymentDays: v)),
          ),
        ),
        if (t.client != ClientType.individual)
          Text(
            _withholdingNote(context, project),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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

/// What [project]'s client withholds from each billing, in a sentence.
String _withholdingNote(BuildContext context, Project project) {
  final rates = withholding(project);
  if (rates.businessTax <= 0) {
    return context.tr(
      'The client withholds {pct}% creditable income tax from each billing, '
      'before VAT, and gives you BIR Form 2307 to credit it.',
      {'pct': formatNumber(rates.incomeTax)},
    );
  }
  return context.tr(
    'The client withholds {pct}% creditable income tax and {tax}% {name} '
    'from each billing, before VAT, and gives you BIR Form 2307 to credit '
    'them.',
    {
      'pct': formatNumber(rates.incomeTax),
      'tax': formatNumber(rates.businessTax),
      'name': context.tr(businessTaxName(project)),
    },
  );
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

  Future<void> _pickFinishBy(BuildContext context, DateTime start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          project.contract.finishBy ?? start.add(const Duration(days: 7 * 26)),
      firstDate: start.add(const Duration(days: 1)),
      lastDate: DateTime(start.year + 5),
    );
    if (picked != null && context.mounted) {
      _update(context, project, (c) => c.withTarget(date: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final contract = project.contract;
    final schedule = Schedule.of(project);
    final start = contract.startDate;
    final finish = start == null
        ? null
        : Schedule.addWorkingDays(start, schedule.days);
    final weeks = schedule.weeks.ceil();
    final trades = [
      for (final trade in MaterialCategory.values) tradeKey(trade),
      if (schedule.crewsFor('other') != null) 'other',
    ];
    String tradeName(String key) =>
        MaterialCategory.byId(key)?.label ?? 'Other works';
    final target = schedule.target;
    return _Panel(
      icon: Icons.calendar_month_outlined,
      title: context.tr('Schedule'),
      subtitle: context.tr(
        'Worked out from each item\'s crew-days, the crews working at once '
        'and how the phases overlap, six working days a week, with an '
        'allowance for rain and the regular holidays skipped. A planning '
        'guide, not a promise.',
      ),
      children: [
        Text(
          schedule.days <= 0
              ? context.tr('Add estimates to see a schedule.')
              : context.tr(
                  'About {weeks} weeks ({days} working days), about {months} '
                  'months',
                  {
                    'weeks': weeks,
                    'days': formatNumber(schedule.days),
                    'months': formatNumber((schedule.months * 10).round() / 10),
                  },
                ),
          style: theme.textTheme.titleSmall,
        ),
        if (schedule.days > 0 && schedule.allowanceDays > 0)
          Text(
            context.tr(
              'Includes {days} working days for rain and unworkable days.',
              {'days': formatNumber(schedule.allowanceDays)},
            ),
            style: muted,
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
        Wrap(
          spacing: Space.md,
          runSpacing: Space.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 190,
              child: _NumberField(
                label: context.tr('Rain and unworkable days'),
                suffix: '%',
                value: contract.rainPct,
                max: 50,
                onChanged: (v) =>
                    _update(context, project, (c) => c.copyWith(rainPct: v)),
              ),
            ),
            SizedBox(
              width: 190,
              child: _OptionalNumberField(
                key: ValueKey(contract.finishBy),
                label: context.tr('Finish within'),
                suffix: context.tr('weeks'),
                hint: context.tr('No target'),
                value: contract.finishBy == null ? contract.targetWeeks : null,
                max: 520,
                onChanged: (v) =>
                    _update(context, project, (c) => c.withTarget(weeks: v)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: start == null
                  ? null
                  : () => _pickFinishBy(context, start),
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: Text(
                contract.finishBy == null
                    ? context.tr('Finish by a date')
                    : context.tr('Finish by {date}', {
                        'date': formatDate(contract.finishBy!),
                      }),
              ),
            ),
            if (contract.targetWeeks != null || contract.finishBy != null)
              IconButton(
                tooltip: context.tr('Clear the target'),
                icon: const Icon(Icons.close),
                onPressed: () =>
                    _update(context, project, (c) => c.withTarget()),
              ),
          ],
        ),
        if (contract.finishBy != null && start == null)
          Text(
            context.tr('Set a start date to use the finish-by date.'),
            style: muted,
          )
        else if (target != null && schedule.meetsTarget != null)
          Text(
            schedule.meetsTarget!
                ? context.tr(
                    'Meets the target of {weeks} weeks with the crews below.',
                    {'weeks': formatNumber((target / 6 * 10).round() / 10)},
                  )
                : context.tr(
                    "Can't finish within {weeks} weeks with a small site's "
                    'limits; the fastest is about {fastest} weeks. Add crews '
                    'by hand, or move the date.',
                    {
                      'weeks': formatNumber((target / 6 * 10).round() / 10),
                      'fastest': weeks,
                    },
                  ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: schedule.meetsTarget!
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
          ),
        Text(
          context.tr('Crews working at once'),
          style: theme.textTheme.labelLarge,
        ),
        Text(
          context.tr(
            'Leave a trade on Auto and the app sizes its crews phase by '
            'phase, about three weeks of work each, within a small site\'s '
            'limits.',
          ),
          style: muted,
        ),
        Wrap(
          spacing: Space.md,
          runSpacing: Space.md,
          children: [
            for (final trade in trades)
              SizedBox(
                width: 150,
                child: _OptionalNumberField(
                  label: context.tr(tradeName(trade)),
                  hint: schedule.crewsFor(trade) == null
                      ? context.tr('Auto')
                      : context.tr('Auto · up to {n}', {
                          'n': formatNumber(schedule.crewsFor(trade)!),
                        }),
                  value: contract.crews[trade],
                  min: 1,
                  max: 20,
                  onChanged: (v) => _update(
                    context,
                    project,
                    (c) => c.copyWith(
                      crews: v == null
                          ? ({...c.crews}..remove(trade))
                          : {...c.crews, trade: v},
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (schedule.critical.isNotEmpty)
          Text(
            context.tr('Critical phases: {phases}', {
              'phases': [for (final p in schedule.critical) context.tr(p)]
                  .join(' → '),
            }),
            style: theme.textTheme.bodyMedium,
          ),
        if (schedule.tasks.isNotEmpty) ...[
          _Gantt(schedule: schedule),
          _SCurve(points: schedule.sCurve),
        ],
      ],
    );
  }
}

/// A number that may be left empty, saved as the user types: null when
/// empty.
class _OptionalNumberField extends StatefulWidget {
  const _OptionalNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.suffix,
    this.min = 0,
    this.max = 100,
  });

  final String label;
  final String? hint;
  final double? value;
  final String? suffix;
  final double min;
  final double max;
  final ValueChanged<double?> onChanged;

  @override
  State<_OptionalNumberField> createState() => _OptionalNumberFieldState();
}

class _OptionalNumberFieldState extends State<_OptionalNumberField> {
  late final _controller = TextEditingController(
    text: widget.value == null
        ? ''
        : formatNumber(widget.value!).replaceAll(',', ''),
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
      LengthLimitingTextInputFormatter(6),
    ],
    style: tabular(Theme.of(context).textTheme.bodyLarge),
    decoration: InputDecoration(
      labelText: widget.label,
      hintText: widget.hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      suffixText: widget.suffix,
      isDense: true,
    ),
    onChanged: (raw) {
      if (raw.trim().isEmpty) return widget.onChanged(null);
      final v = double.tryParse(raw.trim());
      if (v != null && v >= widget.min && v <= widget.max) {
        widget.onChanged(v);
      }
    },
  );
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
                    [
                      context.tr(t.label),
                      if (t.crewDays > 0) context.tr(t.trade?.label ?? 'Other'),
                      '${formatNumber(t.days)} ${context.tr('days')}',
                      if (t.crewDays > 0)
                        t.crews == 1
                            ? context.tr('1 crew')
                            : context.tr('{n} crews', {
                                'n': formatNumber(t.crews),
                              }),
                      if (t.critical) context.tr('critical'),
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: t.critical ? FontWeight.w700 : null,
                    ),
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
                              color: t.crewDays > 0
                                  ? palette.category(t.trade).chart
                                  : theme.colorScheme.outline,
                              borderRadius: BorderRadius.circular(Radii.sm),
                              border: t.critical
                                  ? Border.all(
                                      color: theme.colorScheme.onSurface,
                                      width: 1.5,
                                    )
                                  : null,
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

/// What the expenses so far say about the estimate: the cost variance of
/// materials and labour, the crews' productivity, and a button to use it.
class _Actuals extends StatelessWidget {
  const _Actuals(this.project, this.review);

  final Project project;
  final ActualsReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    String variance(double earned, double spent) {
      final diff = earned - spent;
      final pct = earned <= 0
          ? ''
          : ' (${formatNumber((diff.abs() / earned * 1000).round() / 10)}%)';
      return diff >= 0
          ? context.tr('{amount} under budget', {
              'amount': '${formatMoney(diff)}$pct',
            })
          : context.tr('{amount} over budget', {
              'amount': '${formatMoney(-diff)}$pct',
            });
    }

    Widget line(String label, double earned, double spent) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyValueLine(
          label,
          context.tr('{earned} earned · {spent} spent', {
            'earned': formatMoney(earned),
            'spent': formatMoney(spent),
          }),
          padding: const EdgeInsets.symmetric(vertical: 2),
        ),
        Text(
          variance(earned, spent),
          style: tabular(theme.textTheme.bodySmall)?.copyWith(
            color: spent > earned
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
          ),
        ),
      ],
    );

    final productivity = review.productivity;
    final suggested = review.suggestedProductivity;
    final current = project.costs.productivityPct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('Learn from actuals'),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: Space.xs),
        Text(
          context.tr(
            'The budget of the work done by the last billing, {pct}% '
            'complete, against what you recorded.',
            {'pct': formatNumber((review.percentComplete * 10).round() / 10)},
          ),
          style: muted,
        ),
        if (review.spentMaterials > 0)
          line(
            context.tr('Materials'),
            review.earnedMaterials,
            review.spentMaterials,
          ),
        if (review.spentLabour > 0)
          line(context.tr('Labour'), review.earnedLabour, review.spentLabour),
        if (productivity != null)
          Padding(
            padding: const EdgeInsets.only(top: Space.sm),
            child: Text(
              context.tr(
                "Crews' productivity: {pct}% of the estimate's pace "
                '(earned labour ÷ labour spent).',
                {'pct': formatNumber(productivity.roundToDouble())},
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        if (review.percentComplete < 20 && productivity != null)
          Text(
            context.tr(
              'Early figures are rough: wait until about a fifth of the '
              'work is done.',
            ),
            style: muted,
          ),
        if (suggested != null && (suggested - current).abs() >= 1)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                context.read<ProjectsController>().updateCosts(
                  project.id,
                  project.costs.copyWith(productivityPct: suggested),
                );
                showMessage(
                  context,
                  context.tr('The estimate now uses {pct}% productivity.', {
                    'pct': formatNumber(suggested),
                  }),
                );
              },
              icon: const Icon(Icons.speed_outlined),
              label: Text(
                context.tr('Use {pct}% productivity for this estimate', {
                  'pct': formatNumber(suggested),
                }),
              ),
            ),
          ),
      ],
    );
  }
}

final _pesos = NumberFormat('#,##0', 'en_US');

/// [value] in whole pesos, `₱1,234` or `−₱1,234`, for narrow tables.
String _wholePesos(double value) =>
    '${value < -0.5 ? '−' : ''}₱${_pesos.format(value.abs().round())}';

/// The name of cash-flow month [m]: the signing, or "Month 3 · Jan 4".
String _monthName(BuildContext context, CashFlowMonth m) {
  if (m.month == 0) return context.tr('Signing');
  final name = context.tr('Month {n}', {'n': m.month});
  final from = m.from;
  return from == null
      ? name
      : '$name · ${DateFormat('MMM d', 'en_US').format(from)}';
}

class _CashFlowCard extends StatelessWidget {
  const _CashFlowCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flow = cashFlow(project);
    final terms = project.contract.terms;
    final small = tabular(theme.textTheme.bodySmall);
    final head = theme.textTheme.labelMedium;
    Widget cell(String text, {TextStyle? style, bool right = true}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: style ?? small,
      ),
    );
    return _Panel(
      icon: Icons.savings_outlined,
      title: context.tr('Cash flow'),
      subtitle: context.tr(
        'Money out and in month by month, before VAT: materials bought as '
        'each task starts, labour as the work is done and site costs every '
        'month, against the downpayment and the monthly billings, paid '
        '{days} days later less the downpayment recouped, the retention '
        'and the tax withheld.',
        {'days': formatNumber(terms.paymentDays)},
      ),
      children: [
        if (flow.months.isEmpty)
          Text(context.tr('Add estimates to see a cash flow.'))
        else ...[
          KeyValueLine(
            context.tr('Peak cash need (working capital)'),
            formatMoney(flow.peakNeed),
            emphasize: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
          ),
          Text(
            flow.peakMonth == null
                ? context.tr(
                    'The downpayment and billings cover the costs all along.',
                  )
                : context.tr(
                    'Lowest in month {n}: have this much ready, or ask for a '
                    'larger downpayment or faster payment.',
                    {'n': flow.peakMonth!},
                  ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Semantics(
            label: context.tr('Cash flow by month'),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(),
                1: FixedColumnWidth(80),
                2: FixedColumnWidth(80),
                3: FixedColumnWidth(84),
              },
              children: [
                TableRow(
                  children: [
                    cell(context.tr('Month'), style: head, right: false),
                    cell(context.tr('Out'), style: head),
                    cell(context.tr('In'), style: head),
                    cell(context.tr('Running total'), style: head),
                  ],
                ),
                for (final m in flow.months)
                  TableRow(
                    children: [
                      cell(_monthName(context, m), right: false),
                      cell(_wholePesos(m.costs)),
                      cell(_wholePesos(m.received)),
                      cell(
                        _wholePesos(m.cumulative),
                        style: small?.copyWith(
                          color: m.cumulative < 0
                              ? theme.colorScheme.error
                              : null,
                          fontWeight: m.month == flow.peakMonth
                              ? FontWeight.w700
                              : null,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => downloadCashFlow(context, project),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(context.tr('Download cash flow')),
            ),
          ),
        ],
      ],
    );
  }
}

/// When to buy each material: when it is first needed and when to order
/// it, given the usual lead times.
class _PurchaseCard extends StatefulWidget {
  const _PurchaseCard({required this.project});

  final Project project;

  @override
  State<_PurchaseCard> createState() => _PurchaseCardState();
}

class _PurchaseCardState extends State<_PurchaseCard> {
  static const _shown = 8;
  var _all = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = purchaseSchedule(widget.project);
    final visible = _all ? lines : lines.take(_shown);
    String week(double day) =>
        context.tr('week {n}', {'n': (day / workDaysPerWeek).floor() + 1});
    return _Panel(
      icon: Icons.local_shipping_outlined,
      title: context.tr('Purchase schedule'),
      subtitle: context.tr(
        'When each material is first needed, from the schedule, and when to '
        'order it given usual lead times: stock items 3–7 days, long-span '
        'roofing and tiles 7–14, plumbing fixtures up to 14, doors and '
        'windows made to measure 21–30. Ask your suppliers.',
      ),
      children: [
        if (lines.isEmpty)
          Text(context.tr('Add estimates to see when to buy.'))
        else ...[
          if (widget.project.contract.startDate == null)
            Text(
              context.tr('Set a start date to see the dates.'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          for (final l in visible)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l.material.label} · '
                    '${formatNumber(l.material.quantity)} ${l.material.unit}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    l.needed == null
                        ? context.tr(
                            'Needed {week} for {phase} · order {days} days '
                            'before',
                            {
                              'week': week(l.neededDay),
                              'phase': context.tr(l.phase),
                              'days': l.leadMax,
                            },
                          )
                        : context.tr(
                            'Order by {order} · needed {needed} for {phase}',
                            {
                              'order': DateFormat(
                                'MMM d',
                                'en_US',
                              ).format(l.orderBy!),
                              'needed': DateFormat(
                                'MMM d',
                                'en_US',
                              ).format(l.needed!),
                              'phase': context.tr(l.phase),
                            },
                          ),
                    style: tabular(
                      theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              if (lines.length > _shown)
                TextButton(
                  onPressed: () => setState(() => _all = !_all),
                  child: Text(
                    _all
                        ? context.tr('Show fewer')
                        : context.tr('Show all {n}', {'n': lines.length}),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () =>
                    downloadPurchaseSchedule(context, widget.project),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(context.tr('Download purchase schedule')),
              ),
            ],
          ),
        ],
      ],
    );
  }
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
                s.withholding > 0
                    ? context.tr(
                        '{pct}% complete · net due {amount} · you receive '
                        '{received} after {taxes} withheld',
                        {
                          'pct': formatNumber(
                            (s.percentComplete * 10).round() / 10,
                          ),
                          'amount': formatMoney(s.netDue),
                          'received': formatMoney(s.received),
                          'taxes': formatMoney(s.withholding),
                        },
                      )
                    : context.tr('{pct}% complete · net due {amount}', {
                        'pct': formatNumber(
                          (s.percentComplete * 10).round() / 10,
                        ),
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
        if (reviewActuals(project) case final r?) _Actuals(project, r),
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
