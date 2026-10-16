import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/project.dart';
import '../../data/quotes.dart';
import '../../state/projects_controller.dart';

/// `+₱1,200.00`, `−₱350.00` or `₱0.00`.
String _signed(double v) =>
    v == 0 ? formatMoney(0) : '${v < 0 ? '−' : '+'}${formatMoney(v.abs())}';

/// `Oct 2, 2026`
final _shortDate = DateFormat('MMM d, y', 'en_US');

String _scopeTitle(BuildContext context, BidScope s) => s.letter.isEmpty
    ? context.tr(s.label)
    : '${s.letter}. ${context.tr(s.label)}';

/// Quotes from bidders and subcontractors, each compared with the app's
/// estimate for the same scope, with the lowest and the awarded one marked.
class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  /// Compare with the estimate including markups and VAT, or with the
  /// direct cost.
  var _withMarkups = true;

  Future<void> _edit(Project project, [BidQuote? quote]) async {
    final saved = await showDialog<BidQuote>(
      context: context,
      builder: (_) => _QuoteDialog(project: project, quote: quote),
    );
    if (saved == null || !mounted) return;
    context.read<ProjectsController>().updateQuotes(
      project.id,
      (list) => List.unmodifiable(
        quote == null
            ? [...list, saved]
            : [for (final q in list) q.id == saved.id ? saved : q],
      ),
    );
  }

  void _award(Project project, BidQuote quote) => context
      .read<ProjectsController>()
      .updateQuotes(project.id, (list) => awardQuote(list, quote.id));

  void _delete(Project project, BidQuote quote) {
    final controller = context.read<ProjectsController>();
    final index = project.quotes.indexWhere((q) => q.id == quote.id);
    controller.updateQuotes(
      project.id,
      (list) => List.unmodifiable([
        for (final q in list)
          if (q.id != quote.id) q,
      ]),
    );
    showMessage(
      context,
      context.tr('Deleted the quote from {bidder}.', {'bidder': quote.bidder}),
      action: SnackBarAction(
        label: context.tr('Undo'),
        onPressed: () => controller.updateQuotes(
          project.id,
          (list) => List.unmodifiable(
            [...list]..insert(index.clamp(0, list.length), quote),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = context.watch<ProjectsController>().byId(widget.projectId);
    final title = context.tr('Quotes from bidders');
    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EmptyState(
          icon: Icons.compare_arrows,
          title: context.tr('This project was deleted.'),
          message: context.tr('Go back to choose another project.'),
        ),
      );
    }
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final groups = compareQuotes(project, withMarkups: _withMarkups);
    final today = DateTime.now();

    return PageTitle(
      title: '$title · ${project.name}',
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomClearance(context)),
          child: ContentWidth(
            maxWidth: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Space.lg),
                Text(
                  context.tr(
                    'Record the prices you get from contractors and '
                    'subcontractors, and compare each with the estimate for '
                    'the same scope.',
                  ),
                  style: muted,
                ),
                const SizedBox(height: Space.lg),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text(context.tr('With markups and VAT')),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(context.tr('Direct cost')),
                    ),
                  ],
                  selected: {_withMarkups},
                  onSelectionChanged: (s) =>
                      setState(() => _withMarkups = s.first),
                ),
                const SizedBox(height: Space.sm),
                Text(
                  context.tr(
                    _withMarkups
                        ? 'Compared with the estimate with its share of '
                              'contingency, markups and VAT, as for '
                              'contractors bidding to the owner.'
                        : 'Compared with the direct cost of the work, as for '
                              'subcontractors whose price becomes your cost.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => _edit(project),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('Add a quote')),
                  ),
                ),
                const SizedBox(height: Space.lg),
                if (groups.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Space.xl),
                      child: Column(
                        children: [
                          Icon(
                            Icons.request_quote_outlined,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: Space.md),
                          Text(
                            context.tr('No quotes yet'),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: Space.xs),
                          Text(
                            context.tr(
                              'Send the bill of quantities for bidders from '
                              'the project menu, then add the prices that '
                              'come back.',
                            ),
                            textAlign: TextAlign.center,
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                for (final g in groups) ...[
                  _ScopeCard(
                    group: g,
                    today: today,
                    onEdit: (q) => _edit(project, q),
                    onAward: (q) => _award(project, q),
                    onDelete: (q) => _delete(project, q),
                  ),
                  const SizedBox(height: Space.lg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The quotes for one scope against its estimate.
class _ScopeCard extends StatelessWidget {
  const _ScopeCard({
    required this.group,
    required this.today,
    required this.onEdit,
    required this.onAward,
    required this.onDelete,
  });

  final ScopeQuotes group;
  final DateTime today;
  final ValueChanged<BidQuote> onEdit;
  final ValueChanged<BidQuote> onAward;
  final ValueChanged<BidQuote> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final several = group.quotes.length > 1;

    Widget flag(String text, IconData icon, Color color) => Padding(
      padding: const EdgeInsets.only(top: Space.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, 0, Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: Space.lg),
              child: MergeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          _scopeTitle(context, group.scope),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(context.tr('Estimate'), style: muted),
                        Text(
                          formatMoney(group.estimate),
                          style: tabular(theme.textTheme.titleSmall),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.sm),
            for (final (i, c) in group.quotes.indexed) ...[
              if (i > 0) const Divider(height: Space.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => onEdit(c.quote),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _QuoteSummary(
                          check: c,
                          today: today,
                          lowest: several && c.lowest,
                        ),
                      ),
                    ),
                  ),
                  MenuAnchor(
                    builder: (context, controller, _) => IconButton(
                      tooltip: context.tr('Actions for {bidder}', {
                        'bidder': c.quote.bidder,
                      }),
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => controller.isOpen
                          ? controller.close()
                          : controller.open(),
                    ),
                    menuChildren: [
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.edit_outlined),
                        onPressed: () => onEdit(c.quote),
                        child: Text(context.tr('Edit')),
                      ),
                      MenuItemButton(
                        leadingIcon: Icon(
                          c.quote.awarded
                              ? Icons.remove_done
                              : Icons.emoji_events_outlined,
                        ),
                        onPressed: () => onAward(c.quote),
                        child: Text(
                          context.tr(
                            c.quote.awarded
                                ? 'Take back the award'
                                : 'Mark as awarded',
                          ),
                        ),
                      ),
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.delete_outline),
                        onPressed: () => onDelete(c.quote),
                        child: Text(context.tr('Delete')),
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: Space.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (c.farBelow)
                      flag(
                        context.tr(
                          'More than {pct}% below the estimate: check that '
                          'nothing in the scope was missed.',
                          {'pct': formatNumber(farBelowPct)},
                        ),
                        Icons.warning_amber_rounded,
                        AppPalette.of(context).warning,
                      ),
                    if (c.quote.isExpiredOn(today))
                      flag(
                        context.tr('The price expired on {date}.', {
                          'date': _shortDate.format(c.quote.validUntil),
                        }),
                        Icons.event_busy_outlined,
                        scheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A quote's bidder, price, difference from the estimate and notes.
class _QuoteSummary extends StatelessWidget {
  const _QuoteSummary({
    required this.check,
    required this.today,
    required this.lowest,
  });

  final QuoteCheck check;
  final DateTime today;
  final bool lowest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final q = check.quote;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final difference = check.percent == null
        ? _signed(check.difference)
        : '${_signed(check.difference)} '
              '(${check.percent! > 0
                  ? '+'
                  : check.percent! < 0
                  ? '−'
                  : ''}'
              '${formatNumber(check.percent!.abs())}%)';

    Widget badge(String text, Color background, Color foreground) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(color: foreground),
      ),
    );

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  q.bidder.isEmpty ? context.tr('Unnamed bidder') : q.bidder,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: Space.md),
              Text(
                formatMoney(q.amount),
                style: tabular(theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  context.tr('{date} · valid until {until}', {
                    'date': _shortDate.format(q.date),
                    'until': _shortDate.format(q.validUntil),
                  }),
                  style: muted,
                ),
              ),
              const SizedBox(width: Space.md),
              Text(
                difference,
                style: tabular(
                  muted?.copyWith(
                    color: check.farBelow ? scheme.error : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (q.awarded || lowest) ...[
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                if (q.awarded)
                  badge(
                    context.tr('Awarded'),
                    scheme.primary,
                    scheme.onPrimary,
                  ),
                if (lowest)
                  badge(
                    context.tr('Lowest'),
                    palette.success.withValues(alpha: 0.16),
                    scheme.onSurface,
                  ),
              ],
            ),
          ],
          if (q.inclusions.isNotEmpty) ...[
            const SizedBox(height: Space.xs),
            Text(
              context.tr('Includes: {text}', {'text': q.inclusions}),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
          ],
          if (q.exclusions.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              context.tr('Excludes: {text}', {'text': q.exclusions}),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
          ],
        ],
      ),
    );
  }
}

/// Adds or edits a quote.
class _QuoteDialog extends StatefulWidget {
  const _QuoteDialog({required this.project, this.quote});

  final Project project;
  final BidQuote? quote;

  @override
  State<_QuoteDialog> createState() => _QuoteDialogState();
}

class _QuoteDialogState extends State<_QuoteDialog> {
  late final _bidder = TextEditingController(text: widget.quote?.bidder);
  late final _amount = TextEditingController(
    text: widget.quote == null
        ? ''
        : formatNumber(widget.quote!.amount).replaceAll(',', ''),
  );
  late final _days = TextEditingController(
    text: '${widget.quote?.validityDays ?? 30}',
  );
  late final _inclusions = TextEditingController(
    text: widget.quote?.inclusions,
  );
  late final _exclusions = TextEditingController(
    text: widget.quote?.exclusions,
  );
  late var _scope = bidScope(widget.quote?.scope ?? wholeJob).key;
  late var _date = widget.quote?.date ?? DateTime.now();
  var _tried = false;

  @override
  void dispose() {
    for (final c in [_bidder, _amount, _days, _inclusions, _exclusions]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _price {
    final v = double.tryParse(_amount.text.trim());
    return v != null && v > 0 ? v : null;
  }

  void _save() {
    final bidder = _bidder.text.trim();
    final price = _price;
    if (bidder.isEmpty || price == null) {
      setState(() => _tried = true);
      return;
    }
    final q =
        widget.quote ??
        BidQuote(id: BidQuote.newId(), bidder: '', amount: 0, date: _date);
    Navigator.of(context).pop(
      q.copyWith(
        bidder: bidder,
        amount: price,
        date: _date,
        scope: _scope,
        validityDays: int.tryParse(_days.text.trim()) ?? 30,
        inclusions: _inclusions.text.trim(),
        exclusions: _exclusions.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scopes = [
      ...scopesOf(widget.project),
      if (!scopesOf(widget.project).any((s) => s.key == _scope))
        bidScope(_scope),
    ];
    final estimate = scopeEstimate(widget.project, _scope);
    return AlertDialog(
      title: Text(
        context.tr(widget.quote == null ? 'Add a quote' : 'Edit the quote'),
      ),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _bidder,
              autofocus: widget.quote == null,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [LengthLimitingTextInputFormatter(120)],
              decoration: InputDecoration(
                labelText: context.tr('Bidder or subcontractor'),
                errorText: _tried && _bidder.text.trim().isEmpty
                    ? context.tr('Enter a name')
                    : null,
              ),
            ),
            const SizedBox(height: Space.md),
            DropdownButtonFormField<String>(
              initialValue: _scope,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.tr('Scope'),
                helperText: context.tr('Estimate for this scope: {amount}', {
                  'amount': formatMoney(estimate),
                }),
              ),
              items: [
                for (final s in scopes)
                  DropdownMenuItem(
                    value: s.key,
                    child: Text(
                      _scopeTitle(context, s),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _scope = v ?? _scope),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                const DecimalInputFormatter(),
                LengthLimitingTextInputFormatter(13),
              ],
              decoration: InputDecoration(
                labelText: context.tr('Quoted price'),
                prefixText: '₱ ',
                errorText: _tried && _price == null
                    ? context.tr('Enter the price')
                    : null,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
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
                    label: Text(
                      _shortDate.format(_date),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: Space.md),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _days,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      labelText: context.tr('Valid for'),
                      suffixText: context.tr('days'),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _inclusions,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.tr('Inclusions'),
                hintText: context.tr('Materials, labour, scaffolding'),
              ),
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _exclusions,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.tr('Exclusions and notes'),
                hintText: context.tr('Permits, tiles supplied by the owner'),
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              context.tr(
                'Write down what each bidder leaves out, so quotes are '
                'compared on the same scope.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
}
