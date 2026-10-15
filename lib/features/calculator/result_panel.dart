import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../materials/material_spec.dart';

/// The estimate: quantity and cost on the brand panel, then how it was
/// worked out, what else the job needs, and the actions.
class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.spec,
    required this.result,
    required this.inSummary,
    required this.exporting,
    required this.onAddToSummary,
    required this.onExport,
  });

  final MaterialSpec spec;
  final CalcResult result;
  final bool inSummary;
  final bool exporting;
  final VoidCallback onAddToSummary;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final r = result;
    final compact = WindowSize.of(context) == WindowSize.compact;

    final add = FilledButton.icon(
      onPressed: inSummary ? null : onAddToSummary,
      icon: Icon(inSummary ? Icons.check : Icons.add),
      label: Text(inSummary ? 'Added to summary' : 'Add to summary'),
    );
    final export = OutlinedButton.icon(
      onPressed: exporting ? null : onExport,
      icon: exporting
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.table_chart_outlined),
      label: const Text('Send to Google Sheet'),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkPanel(
            borderRadius: BorderRadius.zero,
            child: Semantics(
              liveRegion: true,
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your estimate · ${r.label}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.onInkMuted,
                      ),
                    ),
                    const SizedBox(height: Space.md),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatQuantity(r.quantity, r.unit),
                        style: tabular(
                          theme.textTheme.displaySmall?.copyWith(
                            color: palette.onInk,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.lg),
                    Text(
                      'Total cost',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: palette.onInkMuted,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatMoney(r.total),
                        style: tabular(
                          theme.textTheme.headlineMedium?.copyWith(
                            color: palette.inkAccent,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'at ${formatMoney(r.unitPrice)} per ${r.unit.singular}',
                      style: tabular(
                        theme.textTheme.bodySmall?.copyWith(
                          color: palette.onInkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.lg,
              Space.xl,
              Space.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (r.details.isNotEmpty) ...[
                  _Heading("How it's worked out"),
                  for (final (i, d) in r.details.indexed) ...[
                    if (i > 0) const Divider(),
                    KeyValueLine(
                      d.label,
                      d.value,
                      emphasize: i == r.details.length - 1,
                    ),
                  ],
                ],
                if (r.companions.isNotEmpty) ...[
                  const SizedBox(height: Space.lg),
                  _Heading(
                    'Also needed',
                    caption: 'Planning quantities, not in the cost',
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.lg,
                        vertical: Space.xs,
                      ),
                      child: Column(
                        children: [
                          for (final c in r.companions)
                            KeyValueLine(c.label, c.value),
                        ],
                      ),
                    ),
                  ),
                ],
                if (r.note != null) ...[
                  const SizedBox(height: Space.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(
                          r.note!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: Space.xl),
                if (compact) ...[
                  add,
                  const SizedBox(height: Space.sm),
                  export,
                ] else
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: [add, export],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.caption});

  final String text;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(text, style: theme.textTheme.titleSmall),
          ),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: Space.sm),
              child: Text(
                caption!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown in place of the estimate until every input is filled in.
class ResultPending extends StatelessWidget {
  const ResultPending({
    super.key,
    required this.spec,
    required this.missing,
    this.error,
  });

  final MaterialSpec spec;
  final List<String> missing;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasError = error != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
          color: hasError ? scheme.error : scheme.outline,
          width: hasError ? 1.5 : 1,
        ),
        color: hasError ? scheme.errorContainer : scheme.surfaceContainerLow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasError ? Icons.error_outline : Icons.calculate_outlined,
                size: 32,
                color: hasError ? scheme.onErrorContainer : scheme.primary,
              ),
              const SizedBox(height: Space.md),
              Text(
                hasError ? 'Check your measurements' : 'Your estimate',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: hasError ? scheme.onErrorContainer : null,
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                hasError
                    ? '$error.'
                    : 'Enter ${_list(missing)} to see the estimate. It '
                          'updates as you type.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: hasError
                      ? scheme.onErrorContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _list(List<String> items) {
    if (items.isEmpty) return 'your measurements';
    final named = [for (final i in items) i.startsWith('price') ? 'the $i' : i];
    if (named.length == 1) return named.first;
    return '${named.sublist(0, named.length - 1).join(', ')} and '
        '${named.last}';
  }
}
