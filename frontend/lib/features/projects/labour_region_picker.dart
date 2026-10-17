import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/labour_regions.dart';
import '../../data/project.dart';
import '../../materials/work_items.dart';
import '../../state/price_book_controller.dart';
import '../../state/projects_controller.dart';

/// Asks which region's market labour rates [project] pays and fills them
/// into its daily rates, keeping the equipment rates.
Future<void> pickLabourRegion(BuildContext context, Project project) async {
  final controller = context.read<ProjectsController>();
  final costs = controller.byId(project.id)?.costs ?? project.costs;
  final matching = [
    for (final r in LabourRegion.values)
      if (r.matches(costs.dailyRates)) r,
  ];
  final fromPriceBook = LabourRegion.forPriceRegion(
    context.read<PriceBookController>().region,
  );
  final initial = matching.contains(fromPriceBook)
      ? fromPriceBook
      : matching.isNotEmpty
      ? matching.first
      : fromPriceBook;
  final picked = await showDialog<LabourRegion>(
    context: context,
    builder: (_) => _RegionDialog(initial: initial),
  );
  if (picked == null || !context.mounted) return;
  final now = controller.byId(project.id)?.costs ?? costs;
  controller.updateCosts(
    project.id,
    now.copyWith(rates: picked.applyTo(now.rates)),
  );
  showMessage(
    context,
    context.tr('Labour rates set for {region}.', {
      'region': context.tr(picked.label),
    }),
  );
}

class _RegionDialog extends StatefulWidget {
  const _RegionDialog({required this.initial});

  final LabourRegion? initial;

  @override
  State<_RegionDialog> createState() => _RegionDialogState();
}

class _RegionDialogState extends State<_RegionDialog> {
  late LabourRegion? _region = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return AlertDialog(
      title: Text(context.tr('Rates for region')),
      contentPadding: const EdgeInsets.only(top: Space.md),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.xl),
              child: Text(
                context.tr(
                  'Market rates from each region\'s minimum wage for '
                  'non-agriculture work, with 13th-month pay and SSS, '
                  'PhilHealth and Pag-IBIG. Equipment rates stay as they '
                  'are.',
                ),
                style: muted,
              ),
            ),
            const SizedBox(height: Space.sm),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final r in LabourRegion.values)
                    _RegionTile(
                      region: r,
                      selected: r == _region,
                      onTap: () => setState(() => _region = r),
                    ),
                ],
              ),
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
          onPressed: _region == null
              ? null
              : () => Navigator.of(context).pop(_region),
          child: Text(context.tr('Use these rates')),
        ),
      ],
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({
    required this.region,
    required this.selected,
    required this.onTap,
  });

  final LabourRegion region;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rates = region.rates;
    final next = region.next;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: ListTile(
        selected: selected,
        onTap: onTap,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
        ),
        title: Text(context.tr(region.label)),
        subtitle: Text(
          [
            context.tr('Minimum {wage} from {date} ({order})', {
              'wage': formatMoney(region.minimumWage),
              'date': region.since,
              'order': region.wageOrder,
            }),
            if (next != null)
              context.tr('rises to {wage} on {date}', {
                'wage': formatMoney(next.$1),
                'date': next.$2,
              }),
            context.tr(
              'Foreman {foreman}, skilled {skilled}, helper {helper}',
              {
                'foreman': formatMoney(rates[DailyRates.foreman]!),
                'skilled': formatMoney(rates[DailyRates.skilled]!),
                'helper': formatMoney(rates[DailyRates.helper]!),
              },
            ),
          ].join('\n'),
        ),
        isThreeLine: true,
      ),
    );
  }
}
