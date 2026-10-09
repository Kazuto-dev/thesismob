import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../materials/catalog.dart';
import '../../router.dart';
import '../../state/estimates_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _clear(BuildContext context) {
    final controller = context.read<EstimatesController>();
    final removed = controller.clearHistory();
    showMessage(
      context,
      'History cleared.',
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => controller.restoreHistory(removed),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.select<EstimatesController, List<Estimate>>(
      (c) => c.history,
    );
    return PageTitle(
      title: 'History',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          actions: [
            if (history.isNotEmpty)
              IconButton(
                tooltip: 'Clear history',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: () => _clear(context),
              ),
          ],
        ),
        body: history.isEmpty
            ? EmptyState(
                icon: Icons.history,
                title: 'No calculations yet',
                message:
                    'Every estimate you calculate is kept here, so you can '
                    'reopen and adjust it later.',
                action: FilledButton.tonal(
                  onPressed: () => context.go(Routes.home),
                  child: const Text('Start an estimate'),
                ),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  ContentWidth(
                    maxWidth: 720,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _grouped(context, history),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  List<Widget> _grouped(BuildContext context, List<Estimate> history) {
    final children = <Widget>[];
    DateTime? day;
    for (final e in history) {
      final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      if (d != day) {
        day = d;
        children.add(
          SectionHeader(e.createdAt.year < 2000 ? 'Earlier' : formatDate(d)),
        );
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _HistoryTile(estimate: e),
        ),
      );
    }
    return children;
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.estimate});

  final Estimate estimate;

  @override
  Widget build(BuildContext context) {
    final e = estimate;
    final time = e.createdAt.year < 2000
        ? null
        : formatDateTime(e.createdAt).split(' · ').last;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(e.label),
        subtitle: Text([formatQuantity(e.quantity, e.unit), ?time].join(' · ')),
        trailing: Text(
          formatMoney(e.total),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        onTap: () => _showDetails(context, e),
      ),
    );
  }

  void _showDetails(BuildContext context, Estimate e) {
    final controller = context.read<EstimatesController>();
    final spec = materialById(e.materialId);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        Widget line(String label, String value) => MergeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        );
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(e.label, style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: 12),
              line('Quantity', formatQuantity(e.quantity, e.unit)),
              if (e.area != null) line('Area', formatArea(e.area!)),
              line('Price per ${e.unit.singular}', formatMoney(e.unitPrice)),
              line('Total cost', formatMoney(e.total)),
              if (e.createdAt.year >= 2000)
                line('Calculated', formatDateTime(e.createdAt)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (spec != null)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        context.go(Routes.material(spec, fromEstimate: e.id));
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Open in calculator'),
                    ),
                  OutlinedButton.icon(
                    onPressed: controller.isInSummary(e.id)
                        ? null
                        : () {
                            controller.addToSummary(e);
                            Navigator.of(sheetContext).pop();
                            showMessage(
                              context,
                              'Added ${e.label} to the summary.',
                            );
                          },
                    icon: const Icon(Icons.add),
                    label: Text(
                      controller.isInSummary(e.id)
                          ? 'In summary'
                          : 'Add to summary',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      final removed = controller.removeFromHistory(e.id);
                      if (removed == null) return;
                      showMessage(
                        context,
                        'Deleted ${e.label}.',
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () => controller.restoreToHistory(
                            removed.index,
                            removed.estimate,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
