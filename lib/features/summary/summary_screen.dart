import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../data/sheets_export_service.dart';
import '../../router.dart';
import '../../state/estimates_controller.dart';
import '../../state/sheet_settings_controller.dart';

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

  Future<void> _export(BuildContext context, List<Estimate> items) async {
    final result = await context.read<SheetSettingsController>().export(items);
    if (!context.mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final (items, total) = context
        .select<EstimatesController, (List<Estimate>, double)>(
          (c) => (c.summary, c.summaryTotal),
        );
    return PageTitle(
      title: 'Summary',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Summary'),
          actions: [
            if (items.isNotEmpty)
              IconButton(
                tooltip: 'Clear summary',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: () => _clear(context),
              ),
          ],
        ),
        body: items.isEmpty
            ? EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Your summary is empty',
                message:
                    'Calculate a material, then choose "Add to summary" to '
                    'build a bill of materials with a running total.',
                action: FilledButton.tonal(
                  onPressed: () => context.go(Routes.home),
                  child: const Text('Start an estimate'),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      children: [
                        ContentWidth(
                          child: LayoutBuilder(
                            builder: (context, constraints) =>
                                constraints.maxWidth >= 720
                                ? _SummaryTable(
                                    items: items,
                                    onRemove: (e) => _remove(context, e),
                                  )
                                : _SummaryList(
                                    items: items,
                                    onRemove: (e) => _remove(context, e),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TotalBar(
                    total: total,
                    count: items.length,
                    onExport: () => _export(context, items),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SummaryList extends StatelessWidget {
  const _SummaryList({required this.items, required this.onRemove});

  final List<Estimate> items;
  final void Function(Estimate) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final e in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: MergeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.label, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(
                              '${formatQuantity(e.quantity, e.unit)} × '
                              '${formatMoney(e.unitPrice)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatMoney(e.total),
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove ${e.label}',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => onRemove(e),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryTable extends StatelessWidget {
  const _SummaryTable({required this.items, required this.onRemove});

  final List<Estimate> items;
  final void Function(Estimate) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = theme.textTheme.titleSmall;
    final body = theme.textTheme.bodyLarge;

    Widget cell(
      String text, {
      TextStyle? style,
      bool numeric = false,
      bool wrap = false,
    }) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: style ?? body,
        softWrap: wrap,
        textAlign: numeric ? TextAlign.end : TextAlign.start,
      ),
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
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
            ),
            children: [
              cell('Material', style: heading),
              cell('Quantity', style: heading, numeric: true),
              cell('Area', style: heading, numeric: true),
              cell('Unit price', style: heading, numeric: true),
              cell('Total', style: heading, numeric: true),
              cell('Remove', style: heading),
            ],
          ),
          for (final e in items)
            TableRow(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              children: [
                cell(e.label, wrap: true),
                cell(formatQuantity(e.quantity, e.unit), numeric: true),
                cell(e.area == null ? '—' : formatArea(e.area!), numeric: true),
                cell(formatMoney(e.unitPrice), numeric: true),
                cell(
                  formatMoney(e.total),
                  numeric: true,
                  style: body?.copyWith(fontWeight: FontWeight.w600),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    tooltip: 'Remove ${e.label}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => onRemove(e),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({
    required this.total,
    required this.count,
    required this.onExport,
  });

  final double total;
  final int count;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exporting = context.select<SheetSettingsController, bool>(
      (c) => c.isExporting,
    );
    return Material(
      color: Colors.white,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        count == 1 ? 'Total, 1 item' : 'Total, $count items',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        formatMoney(total),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
