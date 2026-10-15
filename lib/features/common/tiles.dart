import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../materials/catalog.dart';
import '../../materials/material_spec.dart';
import '../../router.dart';

/// A calculator in a list: its icon, name and what it estimates.
class MaterialTile extends StatelessWidget {
  const MaterialTile({
    super.key,
    required this.spec,
    this.showCategory = false,
    this.onTap,
  });

  final MaterialSpec spec;

  /// Names the category too, for search results that mix categories.
  final bool showCategory;

  /// Defaults to opening the calculator.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: TapCard(
        padding: const EdgeInsets.all(Space.md),
        onTap: onTap ?? () => context.go(Routes.material(spec)),
        child: Row(
          children: [
            IconTile.material(spec, size: 52),
            const SizedBox(width: Space.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spec.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    showCategory
                        ? '${spec.category.label} · ${spec.blurb}'
                        : spec.blurb,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// A saved estimate in a list: material icon, label, quantity and total.
class EstimateTile extends StatelessWidget {
  const EstimateTile({
    super.key,
    required this.estimate,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.selected = false,
  });

  final Estimate estimate;
  final VoidCallback onTap;

  /// Defaults to the quantity and unit price.
  final String? subtitle;
  final Widget? trailing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = estimate;
    final spec = materialById(e.materialId);
    return Semantics(
      button: true,
      selected: selected,
      child: TapCard(
        color: selected ? theme.colorScheme.primaryContainer : null,
        padding: EdgeInsets.fromLTRB(
          Space.md,
          Space.md,
          trailing == null ? Space.lg : Space.xs,
          Space.md,
        ),
        onTap: onTap,
        child: Row(
          children: [
            if (spec != null)
              IconTile.material(spec, size: 44)
            else
              const IconTile(icon: Icons.inventory_2_outlined, size: 44),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle ?? estimateSummary(e),
                    style: tabular(
                      theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (e.note != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        e.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: Space.md),
            Text(
              formatMoney(e.grandTotal),
              style: tabular(theme.textTheme.titleSmall),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// The quantity and price of an estimate's main material, and how many
/// other materials come with it.
String estimateSummary(Estimate e) {
  final others = e.companions.length;
  return '${formatQuantity(e.quantity, e.unit)} × ${formatMoney(e.unitPrice)}'
      '${others == 0 ? '' : ' + $others other material${others == 1 ? '' : 's'}'}';
}

/// The category an estimate belongs to, or null for imported entries.
MaterialCategory? categoryOf(Estimate e) =>
    materialById(e.materialId)?.category;
