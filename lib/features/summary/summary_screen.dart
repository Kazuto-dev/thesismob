import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../data/sheets_export_service.dart';
import '../../materials/catalog.dart';
import '../../materials/material_spec.dart';
import '../../router.dart';
import '../../state/estimates_controller.dart';
import '../../state/sheet_settings_controller.dart';
import '../common/tiles.dart';

/// Summary items of one category, in the order they were added.
typedef _Group = ({
  MaterialCategory? category,
  List<Estimate> items,
  double subtotal,
});

List<_Group> _groups(List<Estimate> items) {
  final groups = <_Group>[];
  for (final category in [...MaterialCategory.values, null]) {
    final members = [
      for (final e in items)
        if (categoryOf(e) == category) e,
    ];
    if (members.isEmpty) continue;
    final subtotal =
        (members.fold<double>(0, (sum, e) => sum + e.total) * 100)
            .roundToDouble() /
        100;
    groups.add((category: category, items: members, subtotal: subtotal));
  }
  return groups;
}

String _groupLabel(MaterialCategory? c) => c?.label ?? 'Other';

/// The summary as plain text, for pasting into a message or document.
String summaryText(List<Estimate> items, double total) {
  final buffer = StringBuffer('BuildQuantify bill of materials\n');
  for (final g in _groups(items)) {
    buffer.writeln('\n${_groupLabel(g.category)}');
    for (final e in g.items) {
      buffer.writeln(
        '• ${e.label}: ${formatQuantity(e.quantity, e.unit)} × '
        '${formatMoney(e.unitPrice)} = ${formatMoney(e.total)}',
      );
    }
  }
  buffer.write(
    '\nTotal (${items.length == 1 ? '1 item' : '${items.length} items'}): '
    '${formatMoney(total)}',
  );
  return buffer.toString();
}

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  void _remove(BuildContext context, Estimate e) {
    final controller = context.read<EstimatesController>();
    final removed = controller.removeFromSummary(e.id);
    if (removed == null) return;
    showMessage(
      context,
      'Removed ${e.label}.',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () =>
            controller.restoreToSummary(removed.index, removed.estimate),
      ),
    );
  }

  void _clear(BuildContext context) {
    final controller = context.read<EstimatesController>();
    final removed = controller.clearSummary();
    showMessage(
      context,
      'Summary cleared.',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => controller.restoreSummary(removed),
      ),
    );
  }

  Future<void> _copy(
    BuildContext context,
    List<Estimate> items,
    double total,
  ) async {
    await Clipboard.setData(ClipboardData(text: summaryText(items, total)));
    if (context.mounted) showMessage(context, 'Summary copied as text.');
  }

  Future<void> _export(BuildContext context, List<Estimate> items) async {
    final result = await context.read<SheetSettingsController>().export(items);
    if (!context.mounted) return;
    showMessage(
      context,
      result.message,
      action: result.status == SheetsExportStatus.missingSheetInfo
          ? SnackBarAction(
              label: 'Set up',
              onPressed: () => context.go(Routes.settings),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (items, total) = context
        .select<EstimatesController, (List<Estimate>, double)>(
          (c) => (c.summary, c.summaryTotal),
        );
    final wide = WindowSize.of(context) == WindowSize.expanded;

    final menu = MenuAnchor(
      builder: (context, controller, _) => IconButton(
        tooltip: 'More',
        icon: const Icon(Icons.more_vert),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.content_copy_outlined),
          onPressed: () => _copy(context, items, total),
          child: const Text('Copy as text'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_sweep_outlined),
          onPressed: () => _clear(context),
          child: const Text('Clear summary'),
        ),
      ],
    );

    final header = PageHeader(
      title: 'Summary',
      subtitle: 'Your bill of materials',
      actions: [if (items.isNotEmpty) menu],
    );

    if (items.isEmpty) {
      return PageTitle(
        title: 'Summary',
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                ContentWidth(child: header),
                Expanded(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Your summary is empty',
                    message:
                        'Work out a material, then choose "Add to summary" to '
                        'build a bill of materials with a running total.',
                    action: FilledButton(
                      onPressed: () => context.go(Routes.home),
                      child: const Text('Start an estimate'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final groups = _groups(items);
    final totalCard = _TotalCard(
      groups: groups,
      count: items.length,
      total: total,
      onExport: () => _export(context, items),
      onCopy: () => _copy(context, items, total),
    );

    return PageTitle(
      title: 'Summary',
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomClearance(context)),
            child: ContentWidth(
              maxWidth: wide ? 1200 : 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _SummaryTable(
                            groups: groups,
                            onRemove: (e) => _remove(context, e),
                          ),
                        ),
                        const SizedBox(width: Space.xl),
                        SizedBox(width: 360, child: totalCard),
                      ],
                    )
                  else ...[
                    totalCard,
                    for (final g in groups) ...[
                      SectionHeader(
                        _groupLabel(g.category),
                        trailing: Text(
                          formatMoney(g.subtotal),
                          style: tabular(
                            Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          Space.xl,
                          0,
                          Space.sm,
                        ),
                      ),
                      for (final (i, e) in g.items.indexed) ...[
                        if (i > 0) const SizedBox(height: Space.sm),
                        EstimateTile(
                          estimate: e,
                          onTap: () => _open(context, e),
                          trailing: IconButton(
                            tooltip: 'Remove ${e.label}',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _remove(context, e),
                          ),
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _open(BuildContext context, Estimate e) {
  final spec = materialById(e.materialId);
  if (spec != null) context.go(Routes.material(spec, fromEstimate: e.id));
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.groups,
    required this.count,
    required this.total,
    required this.onExport,
    required this.onCopy,
  });

  final List<_Group> groups;
  final int count;
  final double total;
  final VoidCallback onExport;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final exporting = context.select<SheetSettingsController, bool>(
      (c) => c.isExporting,
    );
    return InkPanel(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final palette = AppPalette.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1 ? 'Total, 1 item' : 'Total, $count items',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.onInkMuted,
                      ),
                    ),
                    const SizedBox(height: Space.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatMoney(total),
                        style: tabular(
                          theme.textTheme.displaySmall?.copyWith(
                            color: palette.inkAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (groups.length > 1) ...[
                const SizedBox(height: Space.xl),
                Semantics(
                  label: 'Cost by category',
                  child: ProportionBar(
                    format: formatMoney,
                    parts: [
                      for (final g in groups)
                        (
                          label: _groupLabel(g.category),
                          value: g.subtotal,
                          color: palette.category(g.category).chart,
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Space.xl),
              FilledButton.icon(
                onPressed: exporting ? null : onExport,
                icon: exporting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.table_chart_outlined),
                label: const Text('Send to Google Sheet'),
              ),
              const SizedBox(height: Space.sm),
              OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.content_copy_outlined),
                label: const Text('Copy as text'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryTable extends StatelessWidget {
  const _SummaryTable({required this.groups, required this.onRemove});

  final List<_Group> groups;
  final void Function(Estimate) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final heading = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final body = tabular(theme.textTheme.bodyMedium);

    Widget cell(
      Widget child, {
      bool numeric = false,
      EdgeInsets padding = const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
    }) => Padding(
      padding: padding,
      child: Align(
        alignment: numeric ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    );

    Widget text(String value, {TextStyle? style, bool numeric = false}) => cell(
      Text(
        value,
        style: style ?? body,
        textAlign: numeric ? TextAlign.end : TextAlign.start,
      ),
      numeric: numeric,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Table(
        // The material name takes the spare width; numbers never wrap.
        columnWidths: const {0: FlexColumnWidth()},
        defaultColumnWidth: const IntrinsicColumnWidth(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              text('MATERIAL', style: heading),
              text('QUANTITY', style: heading, numeric: true),
              text('UNIT PRICE', style: heading, numeric: true),
              text('TOTAL', style: heading, numeric: true),
              Semantics(label: 'Remove', child: const SizedBox(width: 56)),
            ],
          ),
          for (final g in groups) ...[
            TableRow(
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              children: [
                cell(
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppPalette.of(context)
                              .category(g.category)
                              .chart,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const SizedBox.square(dimension: 10),
                      ),
                      const SizedBox(width: Space.sm),
                      Text(
                        _groupLabel(g.category),
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.lg,
                    vertical: Space.sm,
                  ),
                ),
                const SizedBox.shrink(),
                const SizedBox.shrink(),
                text(
                  formatMoney(g.subtotal),
                  style: tabular(theme.textTheme.titleSmall),
                  numeric: true,
                ),
                const SizedBox.shrink(),
              ],
            ),
            for (final e in g.items)
              TableRow(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                children: [
                  cell(
                    InkWell(
                      onTap: () => _open(context, e),
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            if (materialById(e.materialId) case final spec?)
                              IconTile.material(spec, size: 36)
                            else
                              const IconTile(
                                icon: Icons.inventory_2_outlined,
                                size: 36,
                              ),
                            const SizedBox(width: Space.md),
                            Flexible(
                              child: Text(
                                e.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.lg,
                      vertical: Space.sm,
                    ),
                  ),
                  text(formatQuantity(e.quantity, e.unit), numeric: true),
                  text(formatMoney(e.unitPrice), numeric: true),
                  text(
                    formatMoney(e.total),
                    numeric: true,
                    style: body?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: Space.xs),
                    child: IconButton(
                      tooltip: 'Remove ${e.label}',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onRemove(e),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
