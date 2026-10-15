import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../materials/catalog.dart';
import '../../router.dart';
import '../../state/estimates_controller.dart';
import '../common/tiles.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// Entry shown in the detail pane on wide screens.
  String? _selectedId;

  void _clear() {
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

  void _showSheet(Estimate e) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
        child: HistoryDetails(
          estimate: e,
          onDone: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.select<EstimatesController, List<Estimate>>(
      (c) => c.history,
    );
    final wide = WindowSize.of(context) == WindowSize.expanded;
    final header = PageHeader(
      title: 'History',
      subtitle: 'Your last 100 calculations, newest first',
      actions: [
        if (history.isNotEmpty)
          IconButton(
            tooltip: 'Clear history',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _clear,
          ),
      ],
    );

    if (history.isEmpty) {
      return PageTitle(
        title: 'History',
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                ContentWidth(child: header),
                Expanded(
                  child: EmptyState(
                    icon: Icons.history,
                    title: 'No calculations yet',
                    message:
                        'Every estimate you work out is kept here, so you can '
                        'reopen and adjust it later.',
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

    final selected =
        history.where((e) => e.id == _selectedId).firstOrNull ?? history.first;
    final list = _HistoryList(
      history: history,
      selectedId: wide ? selected.id : null,
      onTap: (e) => wide ? setState(() => _selectedId = e.id) : _showSheet(e),
    );

    return PageTitle(
      title: 'History',
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: wide
              ? ContentWidth(
                  maxWidth: 1200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(
                                  bottom: Space.xxxl,
                                ),
                                child: list,
                              ),
                            ),
                            const SizedBox(width: Space.xl),
                            Expanded(
                              flex: 4,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(
                                  top: Space.xxl + Space.md,
                                  bottom: Space.xxxl,
                                ),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(Space.xl),
                                    child: HistoryDetails(
                                      key: ValueKey(selected.id),
                                      estimate: selected,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomClearance(context)),
                  child: ContentWidth(
                    maxWidth: 760,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [header, list],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.history,
    required this.selectedId,
    required this.onTap,
  });

  final List<Estimate> history;
  final String? selectedId;
  final void Function(Estimate) onTap;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    DateTime? day;
    for (final e in history) {
      final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      if (d != day) {
        day = d;
        children.add(
          SectionHeader(
            e.createdAt.year < 2000 ? 'Earlier' : _dayLabel(d),
            padding: EdgeInsets.fromLTRB(
              0,
              children.isEmpty ? Space.sm : Space.xl,
              0,
              Space.sm,
            ),
          ),
        );
      } else {
        children.add(const SizedBox(height: Space.sm));
      }
      final time = e.createdAt.year < 2000 ? null : formatTime(e.createdAt);
      children.add(
        EstimateTile(
          estimate: e,
          selected: e.id == selectedId,
          subtitle: [formatQuantity(e.quantity, e.unit), ?time].join(' · '),
          onTap: () => onTap(e),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return formatDate(day);
  }
}

/// Everything about one history entry, with what can be done with it.
class HistoryDetails extends StatelessWidget {
  const HistoryDetails({super.key, required this.estimate, this.onDone});

  final Estimate estimate;

  /// Closes the containing sheet after an action, when there is one.
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = estimate;
    final spec = materialById(e.materialId);
    final controller = context.watch<EstimatesController>();
    final inSummary = controller.isInSummary(e.id);

    final inputs = <(String, String)>[
      if (spec != null) ...[
        for (final f in spec.numbers)
          if (e.inputs[f.id] case final v?)
            (
              f.label,
              f.isPrice
                  ? formatMoney(v)
                  : '${formatNumber(v)}${f.unit == null ? '' : ' ${f.unit}'}',
            ),
        for (final c in spec.choices)
          if (c.option(e.choices[c.id]) case final o?) (c.label, o.label),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (spec != null)
              IconTile.material(spec, size: 48)
            else
              const IconTile(icon: Icons.inventory_2_outlined, size: 48),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(e.label, style: theme.textTheme.titleLarge),
                  ),
                  Text(
                    spec?.name ?? 'Imported from an earlier version',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.lg),
        KeyValueLine('Quantity', formatQuantity(e.quantity, e.unit)),
        const Divider(),
        if (e.area != null) ...[
          KeyValueLine('Area', formatArea(e.area!)),
          const Divider(),
        ],
        KeyValueLine('Price per ${e.unit.singular}', formatMoney(e.unitPrice)),
        const Divider(),
        KeyValueLine('Total cost', formatMoney(e.total), emphasize: true),
        if (e.createdAt.year >= 2000) ...[
          const Divider(),
          KeyValueLine('Worked out', formatDateTime(e.createdAt)),
        ],
        if (inputs.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          Text('Inputs', style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xs),
          for (final (label, value) in inputs)
            KeyValueLine(
              label,
              value,
              padding: const EdgeInsets.symmetric(vertical: 6),
            ),
        ],
        const SizedBox(height: Space.xl),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            if (spec != null)
              FilledButton.icon(
                onPressed: () {
                  onDone?.call();
                  context.go(Routes.material(spec, fromEstimate: e.id));
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Open in calculator'),
              ),
            OutlinedButton.icon(
              onPressed: inSummary
                  ? null
                  : () {
                      controller.addToSummary(e);
                      onDone?.call();
                      showMessage(context, 'Added ${e.label} to the summary.');
                    },
              icon: Icon(inSummary ? Icons.check : Icons.add),
              label: Text(inSummary ? 'In summary' : 'Add to summary'),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: () {
                onDone?.call();
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
    );
  }
}
