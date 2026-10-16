import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/project.dart';
import '../../data/revisions.dart';
import '../../state/projects_controller.dart';

/// `+₱1,200.00`, `−₱350.00` or `₱0.00`.
String _signed(double v) =>
    v == 0 ? formatMoney(0) : '${v < 0 ? '−' : '+'}${formatMoney(v.abs())}';

/// A project's saved estimate revisions: save the current estimate as the
/// next one, compare any two, and restore an earlier one.
class RevisionsScreen extends StatefulWidget {
  const RevisionsScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<RevisionsScreen> createState() => _RevisionsScreenState();
}

class _RevisionsScreenState extends State<RevisionsScreen> {
  /// The revision compared from; the latest when null.
  int? _from;

  /// The revision compared to; the current estimate when null.
  int? _to;
  final _compareKey = GlobalKey();

  ProjectsController get _controller => context.read<ProjectsController>();

  Future<void> _save(Project project) async {
    final next = nextRevisionNumber(project);
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(label: 'Rev $next'),
    );
    if (note == null || !mounted) return;
    _controller.saveRevision(project.id, note);
    setState(() => _from = null);
    showMessage(context, context.tr('Saved {rev}.', {'rev': 'Rev $next'}));
  }

  Future<void> _restore(Project project, EstimateRevision r) async {
    final alreadySaved = matchingRevision(project) != null;
    final saveFirst = await showDialog<bool>(
      context: context,
      builder: (_) => _RestoreDialog(revision: r, alreadySaved: alreadySaved),
    );
    if (saveFirst == null || !mounted) return;
    final controller = _controller;
    final items = project.items;
    final costs = project.costs;
    if (saveFirst) {
      controller.saveRevision(
        project.id,
        context.tr('Before restoring {rev}', {'rev': r.label}),
      );
    }
    controller.setEstimate(project.id, items: r.items, costs: r.costs);
    showMessage(
      context,
      context.tr('Restored {rev}.', {'rev': r.label}),
      action: SnackBarAction(
        label: context.tr('Undo'),
        onPressed: () =>
            controller.setEstimate(project.id, items: items, costs: costs),
      ),
    );
  }

  void _delete(Project project, EstimateRevision r) {
    final controller = _controller;
    controller.updateRevisions(
      project.id,
      (list) => List.unmodifiable([
        for (final x in list)
          if (x.number != r.number) x,
      ]),
    );
    setState(() {
      if (_from == r.number) _from = null;
      if (_to == r.number) _to = null;
    });
    showMessage(
      context,
      context.tr('Deleted {rev}.', {'rev': r.label}),
      action: SnackBarAction(
        label: context.tr('Undo'),
        onPressed: () => controller.updateRevisions(
          project.id,
          (list) => List.unmodifiable(
            <EstimateRevision>[...list, r]
              ..sort((a, b) => a.number.compareTo(b.number)),
          ),
        ),
      ),
    );
  }

  void _compareWithCurrent(EstimateRevision r) {
    setState(() {
      _from = r.number;
      _to = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _compareKey.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final project = context.watch<ProjectsController>().byId(widget.projectId);
    final title = context.tr('Estimate revisions');
    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EmptyState(
          icon: Icons.history,
          title: context.tr('This project was deleted.'),
          message: context.tr('Go back to choose another project.'),
        ),
      );
    }
    final theme = Theme.of(context);
    final revisions = project.revisions;
    final same = matchingRevision(project);
    final b = project.breakdown;
    final status = revisions.isEmpty
        ? context.tr('Not saved as a revision yet.')
        : same != null
        ? context.tr('The same as {rev}.', {'rev': same.label})
        : context.tr('Changed since {rev}.', {'rev': revisions.last.label});

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
                    'Save the estimate as a revision before you change it, '
                    'such as when the client changes the plans. The last '
                    '{max} revisions are kept with the project.',
                    {'max': maxRevisions},
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Space.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            context.tr('Current estimate'),
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: Space.xs),
                        Text(
                          status,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        KeyValueLine(
                          context.tr('Direct cost'),
                          formatMoney(b.direct),
                          padding: const EdgeInsets.only(top: Space.md),
                        ),
                        KeyValueLine(
                          context.tr(
                            project.costs.isContractorBid
                                ? 'Total contract price'
                                : 'Project budget',
                          ),
                          formatMoney(b.total),
                          emphasize: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        const SizedBox(height: Space.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            onPressed: project.items.isEmpty
                                ? null
                                : () => _save(project),
                            icon: const Icon(Icons.save_outlined),
                            label: Text(context.tr('Save as a revision')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (revisions.isNotEmpty) ...[
                  const SizedBox(height: Space.lg),
                  _CompareCard(
                    key: _compareKey,
                    project: project,
                    from: _from,
                    to: _to,
                    onChanged: (from, to) => setState(() {
                      _from = from;
                      _to = to;
                    }),
                  ),
                ],
                SectionHeader(
                  context.tr('Saved revisions'),
                  padding: const EdgeInsets.fromLTRB(0, Space.xl, 0, Space.sm),
                ),
                if (revisions.isEmpty)
                  Text(
                    context.tr('No revisions yet.'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                for (final r in revisions.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.sm),
                    child: _RevisionTile(
                      revision: r,
                      total: r.applyTo(project).breakdown.total,
                      onCompare: () => _compareWithCurrent(r),
                      onRestore: () => _restore(project, r),
                      onDelete: () => _delete(project, r),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RevisionTile extends StatelessWidget {
  const _RevisionTile({
    required this.revision,
    required this.total,
    required this.onCompare,
    required this.onRestore,
    required this.onDelete,
  });

  final EstimateRevision revision;
  final double total;
  final VoidCallback onCompare;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = revision;
    final count = r.items.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, 0, Space.md),
        child: Row(
          children: [
            Expanded(
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.note.isEmpty ? r.label : '${r.label} – ${r.note}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatDateTime(r.date)} · '
                      '${context.tr(count == 1 ? '1 item' : '{n} items', {'n': count})}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMoney(total),
                      style: tabular(theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
            MenuAnchor(
              builder: (context, controller, _) => IconButton(
                tooltip: context.tr('Actions for {rev}', {'rev': r.label}),
                icon: const Icon(Icons.more_vert),
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.compare_arrows),
                  onPressed: onCompare,
                  child: Text(context.tr('Compare with the current estimate')),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.restore),
                  onPressed: onRestore,
                  child: Text(context.tr('Restore')),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  child: Text(context.tr('Delete')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Two estimates side by side: totals, items added, removed and changed,
/// and cost settings.
class _CompareCard extends StatelessWidget {
  const _CompareCard({
    super.key,
    required this.project,
    required this.from,
    required this.to,
    required this.onChanged,
  });

  final Project project;
  final int? from;
  final int? to;
  final void Function(int? from, int? to) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final revisions = project.revisions;
    EstimateRevision? byNumber(int? n) =>
        revisions.where((r) => r.number == n).firstOrNull;
    final base = byNumber(from) ?? revisions.last;
    final target = byNumber(to);
    final before = base.applyTo(project);
    final after = target?.applyTo(project) ?? project;
    final afterLabel = target?.label ?? context.tr('Current estimate');
    final c = EstimateComparison.of(before, after);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    String percent(double change, double of) => of == 0
        ? ''
        : ' (${change < 0 ? '−' : '+'}'
              '${formatNumber((change.abs() / of * 1000).round() / 10)}%)';

    Widget line(String label, String value, {bool strong = false}) =>
        KeyValueLine(
          label,
          value,
          emphasize: strong,
          padding: const EdgeInsets.symmetric(vertical: 4),
        );

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: Space.md),
      child: Text(text, style: theme.textTheme.labelLarge),
    );

    String title(ItemChange i) => (i.after ?? i.before)!.title;

    final picker = Wrap(
      spacing: Space.md,
      runSpacing: Space.md,
      children: [
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int>(
            key: ValueKey('from-${base.number}'),
            initialValue: base.number,
            isExpanded: true,
            decoration: InputDecoration(labelText: context.tr('From')),
            items: [
              for (final r in revisions.reversed)
                DropdownMenuItem(value: r.number, child: Text(r.label)),
            ],
            onChanged: (v) => onChanged(v, to),
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<int>(
            key: ValueKey('to-${target?.number ?? 0}'),
            initialValue: target?.number ?? 0,
            isExpanded: true,
            decoration: InputDecoration(labelText: context.tr('To')),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text(context.tr('Current estimate')),
              ),
              for (final r in revisions.reversed)
                DropdownMenuItem(value: r.number, child: Text(r.label)),
            ],
            onChanged: (v) => onChanged(from, v == 0 ? null : v),
          ),
        ),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                context.tr('Compare'),
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: Space.md),
            picker,
            const SizedBox(height: Space.md),
            if (base.number == target?.number)
              Text(context.tr('Choose two different estimates.'), style: muted)
            else ...[
              line(
                context.tr('{rev} total', {'rev': base.label}),
                formatMoney(before.breakdown.total),
              ),
              line(
                context.tr('{rev} total', {'rev': afterLabel}),
                formatMoney(after.breakdown.total),
              ),
              line(
                context.tr('Change in total'),
                '${_signed(c.totalChange)}'
                '${percent(c.totalChange, before.breakdown.total)}',
                strong: true,
              ),
              line(
                context.tr('Change in direct cost'),
                '${_signed(c.directChange)}'
                '${percent(c.directChange, before.breakdown.direct)}',
              ),
              if (c.isSame)
                Padding(
                  padding: const EdgeInsets.only(top: Space.sm),
                  child: Text(context.tr('No differences.'), style: muted),
                ),
              if (c.added.isNotEmpty) ...[
                heading(context.tr('Items added')),
                for (final i in c.added) line(title(i), _signed(i.afterAmount)),
              ],
              if (c.removed.isNotEmpty) ...[
                heading(context.tr('Items removed')),
                for (final i in c.removed)
                  line(title(i), _signed(-i.beforeAmount)),
              ],
              if (c.changed.isNotEmpty) ...[
                heading(context.tr('Items changed')),
                for (final i in c.changed)
                  line(
                    i.before!.quantity == i.after!.quantity
                        ? title(i)
                        : '${title(i)}: '
                              '${formatQuantity(i.before!.quantity, i.before!.unit)}'
                              ' → '
                              '${formatQuantity(i.after!.quantity, i.after!.unit)}',
                    '${formatMoney(i.beforeAmount)} → '
                    '${formatMoney(i.afterAmount)}',
                  ),
              ],
              if (c.repriced != 0 || c.generalChange != 0) ...[
                heading(context.tr('Other changes in direct cost')),
                if (c.repriced != 0)
                  line(
                    context.tr('Unchanged items, repriced by the settings'),
                    _signed(c.repriced),
                  ),
                if (c.generalChange != 0)
                  line(
                    context.tr('General requirements and hauling'),
                    _signed(c.generalChange),
                  ),
              ],
              if (c.settings.isNotEmpty) ...[
                heading(context.tr('Cost settings changed')),
                for (final s in c.settings)
                  line(
                    context.tr(s.label),
                    '${context.tr(s.before)} → ${context.tr(s.after)}',
                  ),
              ],
              const SizedBox(height: Space.sm),
              Text(
                context.tr(
                  'Item amounts are direct costs: materials, labour, tools '
                  'and equipment.',
                ),
                style: muted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Asks what changed in a new revision.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.label});

  final String label;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _save() => Navigator.of(context).pop(_note.text.trim());

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('Save {rev}', {'rev': widget.label})),
    content: SizedBox(
      width: 400,
      child: TextField(
        controller: _note,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: [LengthLimitingTextInputFormatter(200)],
        decoration: InputDecoration(
          labelText: context.tr('What changed'),
          hintText: context.tr('Client removed the second bathroom'),
        ),
        onSubmitted: (_) => _save(),
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

/// Confirms restoring a revision, offering to save the current estimate
/// first. Pops whether to save it, or null to cancel.
class _RestoreDialog extends StatefulWidget {
  const _RestoreDialog({required this.revision, required this.alreadySaved});

  final EstimateRevision revision;

  /// Whether the current estimate is already the same as a revision.
  final bool alreadySaved;

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  late var _saveFirst = !widget.alreadySaved;

  @override
  Widget build(BuildContext context) {
    final rev = widget.revision.label;
    return AlertDialog(
      title: Text(context.tr('Restore {rev}?', {'rev': rev})),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(
                "The project's items and cost settings are replaced with "
                "{rev}'s. Its details, contract, quotes and revisions stay.",
                {'rev': rev},
              ),
            ),
            const SizedBox(height: Space.sm),
            CheckboxListTile(
              value: _saveFirst,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                context.tr('Save the current estimate as a revision first'),
              ),
              onChanged: (v) => setState(() => _saveFirst = v ?? false),
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
          onPressed: () => Navigator.of(context).pop(_saveFirst),
          child: Text(context.tr('Restore')),
        ),
      ],
    );
  }
}
