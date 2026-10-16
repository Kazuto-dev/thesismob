import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/unit_prices.dart';

/// A work item's detailed unit price analysis: the materials, the crew and
/// equipment for the measured quantity, and what one unit costs.
class UnitPriceCard extends StatelessWidget {
  const UnitPriceCard({super.key, required this.analysis});

  final WorkAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final a = analysis;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final quantity = a.unit.isEmpty
        ? formatNumber(a.quantity)
        : '${formatNumber(a.quantity)} ${a.unit}';

    Widget line(String label, double amount, {bool strong = false}) =>
        KeyValueLine(
          label,
          formatMoney(amount),
          emphasize: strong,
          padding: const EdgeInsets.symmetric(vertical: 4),
        );

    Widget detail(String text) => Padding(
      padding: const EdgeInsets.only(left: Space.md, bottom: 2),
      child: Text(text, style: tabular(muted)),
    );

    // A Material, not a coloured box, so the tile's tap highlight shows.
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(Radii.md),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          expandedAlignment: Alignment.centerLeft,
          tilePadding: const EdgeInsets.symmetric(horizontal: Space.md),
          childrenPadding: const EdgeInsets.fromLTRB(
            Space.md,
            0,
            Space.md,
            Space.md,
          ),
          title: Text(
            a.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            a.unit.isEmpty
                ? '$quantity · ${formatMoney(a.directCost)}'
                : '$quantity · ${formatMoney(a.unitCost)} / ${a.unit}',
            style: tabular(muted),
          ),
          children: [
            line(context.tr('Materials'), a.materialCost),
            for (final m in a.materials)
              detail(
                '${m.label}: ${formatNumber(m.quantity)} ${m.unit} × '
                '${formatMoney(m.unitPrice)}',
              ),
            line(context.tr('Labour'), a.labourCost),
            for (final l in a.labour)
              detail(
                l.days == 0
                    ? l.label
                    : '${formatNumber(l.count)} ${context.tr(l.label).toLowerCase()} × '
                          '${formatNumber(_round(l.days))} '
                          '${context.tr('days')} × ${formatMoney(l.rate)}',
              ),
            if (a.toolsCost > 0)
              line(
                context.tr('Minor tools, {pct}% of labour', {
                  'pct': formatNumber(a.toolsPct),
                }),
                a.toolsCost,
              ),
            if (a.equipmentCost > 0) ...[
              line(context.tr('Equipment rental'), a.equipmentCost),
              for (final l in a.equipment)
                detail(
                  '${context.tr(l.label)} × ${formatNumber(_round(l.days * l.count))} '
                  '${context.tr('days')} × ${formatMoney(l.rate)}',
                ),
            ],
            const Divider(),
            line(context.tr('Direct cost'), a.directCost, strong: true),
            if (a.unit.isNotEmpty)
              line(
                context.tr('Direct cost per {unit}', {'unit': a.unit}),
                a.unitCost,
              ),
            if (a.markupPct > 0 || a.vatPct > 0) ...[
              line(
                context.tr('Markups, {pct}%', {
                  'pct': formatNumber(a.markupPct),
                }),
                a.markups,
              ),
              if (a.vat > 0)
                line(
                  context.tr('VAT, {pct}%', {'pct': formatNumber(a.vatPct)}),
                  a.vat,
                ),
              if (a.unit.isNotEmpty)
                line(
                  context.tr('Unit price per {unit}', {'unit': a.unit}),
                  a.unitPrice,
                  strong: true,
                ),
            ],
          ],
        ),
      ),
    );
  }

  static double _round(double v) => (v * 100).roundToDouble() / 100;
}
