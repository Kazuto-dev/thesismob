import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../data/estimate.dart';
import '../../materials/material_spec.dart';

/// The estimate produced by a calculation, with the actions that use it.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.estimate,
    required this.result,
    required this.stale,
    required this.inSummary,
    required this.exporting,
    required this.onAddToSummary,
    required this.onExport,
  });

  final Estimate estimate;
  final CalcResult result;

  /// The inputs changed after this result was calculated.
  final bool stale;
  final bool inSummary;
  final bool exporting;
  final VoidCallback onAddToSummary;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(estimate.label, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total cost',
                      style: theme.textTheme.labelLarge?.copyWith(color: muted),
                    ),
                    Text(
                      formatMoney(estimate.total),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: stale ? muted : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Line(
              'Quantity',
              formatQuantity(estimate.quantity, estimate.unit),
              emphasize: true,
            ),
            if (estimate.area != null)
              _Line('Area', formatArea(estimate.area!)),
            _Line(
              'Price per ${estimate.unit.singular}',
              formatMoney(estimate.unitPrice),
            ),
            for (final d in result.details) _Line(d.label, d.value),
            if (stale) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your inputs changed. Calculate again to update this '
                      'estimate.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: stale || inSummary ? null : onAddToSummary,
                  icon: Icon(inSummary ? Icons.check : Icons.add),
                  label: Text(
                    inSummary ? 'Added to summary' : 'Add to summary',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: stale || exporting ? null : onExport,
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
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: emphasize
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown beside the form on wide screens before the first calculation.
class ResultPlaceholder extends StatelessWidget {
  const ResultPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.calculate_outlined,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Fill in the measurements and select Calculate. The estimate '
              'appears here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
