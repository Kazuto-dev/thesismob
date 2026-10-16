import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/checklists.dart';
import '../../data/checks.dart';
import '../../router.dart';
import '../projects/project_picker.dart';

/// A rough budget for a house from its floor area, before anything is
/// measured: a range by finish level, and how it usually splits by trade.
class QuickBudgetScreen extends StatefulWidget {
  const QuickBudgetScreen({super.key});

  @override
  State<QuickBudgetScreen> createState() => _QuickBudgetScreenState();
}

class _QuickBudgetScreenState extends State<QuickBudgetScreen> {
  final _area = TextEditingController(text: '80');
  int _storeys = 1;
  FinishLevel _level = FinishLevel.standard;

  @override
  void initState() {
    super.initState();
    _area.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    final area = double.tryParse(_area.text.trim()) ?? 0;
    final budget = area > 0 && area <= 100000
        ? parametricBudget(area, _storeys, _level)
        : null;
    final mid = budget == null ? 0.0 : (budget.low + budget.high) / 2;
    return PageTitle(
      title: context.tr('Quick budget'),
      child: Scaffold(
        appBar: AppBar(title: Text(context.tr('Quick budget'))),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomClearance(context)),
          child: ContentWidth(
            maxWidth: 680,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr(
                    'A first idea of what a house costs from its floor area, '
                    'before anything is measured. Estimate the items to get '
                    'a real figure.',
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.xl),
                TextField(
                  controller: _area,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    const DecimalInputFormatter(),
                    LengthLimitingTextInputFormatter(7),
                  ],
                  style: tabular(theme.textTheme.bodyLarge),
                  decoration: InputDecoration(
                    labelText: context.tr('Floor area, all floors'),
                    suffixText: 'm²',
                  ),
                ),
                const SizedBox(height: Space.lg),
                Text(context.tr('Storeys'), style: theme.textTheme.labelLarge),
                const SizedBox(height: Space.sm),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1')),
                    ButtonSegment(value: 2, label: Text('2')),
                    ButtonSegment(value: 3, label: Text('3')),
                  ],
                  selected: {_storeys},
                  onSelectionChanged: (s) => setState(() => _storeys = s.first),
                ),
                const SizedBox(height: Space.lg),
                Text(context.tr('Finishes'), style: theme.textTheme.labelLarge),
                const SizedBox(height: Space.sm),
                SegmentedButton<FinishLevel>(
                  showSelectedIcon: false,
                  segments: [
                    for (final l in FinishLevel.values)
                      ButtonSegment(value: l, label: Text(context.tr(l.label))),
                  ],
                  selected: {_level},
                  onSelectionChanged: (s) => setState(() => _level = s.first),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  context.tr(_level.description),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.xl),
                if (budget != null)
                  InkPanel(
                    child: Builder(
                      builder: (context) {
                        final t = Theme.of(context);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              context.tr('About'),
                              style: t.textTheme.labelLarge?.copyWith(
                                color: palette.onInkMuted,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${formatMoney(budget.low)} – '
                                '${formatMoney(budget.high)}',
                                style: tabular(
                                  t.textTheme.headlineSmall?.copyWith(
                                    color: palette.inkAccent,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              context.tr(
                                '{low}–{high} a m², a contractor\'s price '
                                'with VAT in Metro Manila',
                                {
                                  'low': formatMoney(_level.low),
                                  'high': formatMoney(_level.high),
                                },
                              ),
                              style: t.textTheme.bodySmall?.copyWith(
                                color: palette.onInkMuted,
                              ),
                            ),
                            const SizedBox(height: Space.lg),
                            ProportionBar(
                              format: formatMoney,
                              parts: [
                                for (final (trade, share) in parametricSplit)
                                  (
                                    label: context.tr(
                                      trade?.label ?? 'General requirements',
                                    ),
                                    value: mid * share,
                                    color: palette.category(trade).chart,
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: Space.lg),
                Text(
                  context.tr(
                    'Ranges are typical for houses in late 2026 and vary with '
                    'the site, the design and the region. Use them for a '
                    'first conversation, never for a contract.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.xl),
                FilledButton.icon(
                  onPressed: () async {
                    final created = await createProject(
                      context,
                      checklist: houseChecklist,
                      floorArea: area > 0 ? area : null,
                    );
                    if (created != null && context.mounted) {
                      context.go(Routes.project);
                    }
                  },
                  icon: const Icon(Icons.house_outlined),
                  label: Text(context.tr('Estimate this house item by item')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
