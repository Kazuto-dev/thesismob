import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../materials/material_spec.dart';

/// The estimate: quantity and cost on the brand panel, every material the
/// job needs with its price, how the quantity was worked out, and the
/// actions.
class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.spec,
    required this.result,
    required this.estimate,
    required this.projectName,
    required this.inProject,
    required this.exporting,
    required this.onAdd,
    required this.onChangeProject,
    required this.onExport,
    required this.onSetPrice,
  });

  final MaterialSpec spec;
  final CalcResult result;

  /// The result priced with the price book.
  final Estimate estimate;
  final String projectName;
  final bool inProject;
  final bool exporting;
  final VoidCallback onAdd;
  final VoidCallback onChangeProject;
  final VoidCallback onExport;

  /// Changes the price book price of a companion material.
  final void Function(EstimateLine line) onSetPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final r = result;
    final e = estimate;
    final compact = WindowSize.of(context) == WindowSize.compact;
    final unpriced = e.companions.where((l) => l.unitPrice <= 0).length;

    final add = FilledButton.icon(
      onPressed: inProject ? null : onAdd,
      icon: Icon(inProject ? Icons.check : Icons.add),
      label: Text(
        inProject ? 'Added to $projectName' : 'Add to $projectName',
        overflow: TextOverflow.ellipsis,
      ),
    );
    final change = TextButton.icon(
      onPressed: onChangeProject,
      icon: const Icon(Icons.swap_horiz, size: 18),
      label: const Text('Change project'),
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
                      e.companions.isEmpty ? 'Total cost' : 'Materials total',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: palette.onInkMuted,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatMoney(e.grandTotal),
                        style: tabular(
                          theme.textTheme.headlineMedium?.copyWith(
                            color: palette.inkAccent,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      e.companions.isEmpty
                          ? 'at ${formatMoney(r.unitPrice)} per '
                                '${r.unit.singular}'
                          : '${formatMoney(e.total)} ${r.unit.plural} + '
                                '${formatMoney(e.companionsTotal)} other '
                                'materials',
                      style: tabular(
                        theme.textTheme.bodySmall?.copyWith(
                          color: palette.onInkMuted,
                        ),
                      ),
                    ),
                    Text(
                      'Materials only. Labour and markups are added in the '
                      'project budget.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.onInkMuted,
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
                if (e.companions.isNotEmpty) ...[
                  _Heading(
                    'Materials for this job',
                    caption: unpriced > 0
                        ? '$unpriced ${unpriced == 1 ? 'item has' : 'items have'} '
                              'no price yet. Tap a line to set one.'
                        : 'Priced from your price book. Tap a line to change '
                              'its price.',
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Column(
                      children: [
                        _MaterialLine(
                          name: r.label,
                          amount: formatQuantity(r.quantity, r.unit),
                          unitPrice: r.unitPrice,
                          total: e.total,
                        ),
                        for (final l in e.companions) ...[
                          const Divider(height: 1, indent: Space.lg),
                          _MaterialLine(
                            name: l.label,
                            amount: '${formatNumber(l.quantity)} ${l.unit}',
                            unitPrice: l.unitPrice,
                            total: l.total,
                            onTap:
                                l.itemKey == 'pvc_fittings' ||
                                    l.itemKey == 'conduit_fittings'
                                ? null
                                : () => onSetPrice(l),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                ],
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
                  change,
                  const SizedBox(height: Space.xs),
                  export,
                ] else
                  Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [add, export, change],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One material with its quantity, unit price and amount.
class _MaterialLine extends StatelessWidget {
  const _MaterialLine({
    required this.name,
    required this.amount,
    required this.unitPrice,
    required this.total,
    this.onTap,
  });

  final String name;
  final String amount;
  final double unitPrice;
  final double total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final missing = unitPrice <= 0;
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  missing
                      ? '$amount · no price yet'
                      : '$amount × '
                            '${formatMoney(unitPrice)}',
                  style: tabular(
                    theme.textTheme.bodySmall?.copyWith(
                      color: missing ? scheme.error : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.md),
          if (missing && onTap != null)
            Text(
              'Set price',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
              ),
            )
          else
            Text(
              formatMoney(total),
              style: tabular(
                theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return MergeSemantics(child: row);
    return Semantics(
      button: true,
      hint: 'Change price',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: row,
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
