import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../materials/catalog.dart';
import '../../materials/material_spec.dart';
import '../../router.dart';
import '../../state/estimates_controller.dart';
import '../../state/projects_controller.dart';
import '../common/tiles.dart';

/// Calculators most people start with.
const _popular = ['chb', 'paint', 'tiles', 'roof'];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      if (_search.text != _query) setState(() => _query = _search.text);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    return PageTitle(
      title: null,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomClearance(context)),
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Space.lg),
                  _Hero(search: _search),
                  if (searching)
                    _SearchResults(query: _query)
                  else ...[
                    const SectionHeader('Categories'),
                    const _CategoryGrid(),
                    const SectionHeader('Popular calculators'),
                    _MaterialGrid(
                      specs: [for (final id in _popular) materialById(id)!],
                    ),
                    const _Recent(),
                    const SizedBox(height: Space.xxl),
                    const _HelpCard(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.search});

  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final compact = WindowSize.of(context) == WindowSize.compact;
    final (name, count, total) = context
        .select<ProjectsController, (String, int, double)>(
          (c) =>
              (c.active.name, c.active.items.length, c.active.breakdown.total),
        );
    return InkPanel(
      padding: EdgeInsets.all(compact ? Space.xl : Space.xxl + Space.sm),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: BrandLockup(size: 32),
                ),
                const SizedBox(height: Space.xl),
              ],
              Semantics(
                header: true,
                child: Text(
                  'What are you building?',
                  style:
                      (compact
                              ? theme.textTheme.headlineMedium
                              : theme.textTheme.headlineLarge)
                          ?.copyWith(color: palette.onInk),
                ),
              ),
              const SizedBox(height: Space.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(
                  'Estimate how much material to buy and what it costs, '
                  'using sizes sold in the Philippines.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: palette.onInkMuted,
                  ),
                ),
              ),
              const SizedBox(height: Space.xl),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _SearchField(controller: search),
              ),
              if (count > 0) ...[
                const SizedBox(height: Space.xl),
                Divider(color: palette.inkLine.withValues(alpha: 0.3)),
                const SizedBox(height: Space.md),
                Row(
                  children: [
                    Expanded(
                      child: MergeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$name · ${count == 1 ? '1 item' : '$count items'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: palette.onInkMuted,
                              ),
                            ),
                            Text(
                              formatMoney(total),
                              style: tabular(
                                theme.textTheme.headlineSmall?.copyWith(
                                  color: palette.inkAccent,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go(Routes.project),
                      style: TextButton.styleFrom(
                        foregroundColor: palette.onInk,
                      ),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Open project'),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: palette.onInkMuted.withValues(alpha: 0.4)),
    );
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyLarge?.copyWith(color: palette.onInk),
        cursorColor: palette.inkAccent,
        decoration: InputDecoration(
          hintText: 'Search, e.g. paint or yero',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: palette.onInkMuted,
          ),
          filled: true,
          fillColor: palette.inkRaised,
          prefixIcon: Icon(Icons.search, color: palette.onInkMuted),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: Icon(Icons.close, color: palette.onInkMuted),
                  onPressed: controller.clear,
                ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: palette.inkAccent, width: 2),
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final results = [
      for (final m in allMaterials)
        if (m.matches(query)) m,
    ];
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          results.isEmpty
              ? 'No matches'
              : results.length == 1
              ? '1 material'
              : '${results.length} materials',
        ),
        if (results.isEmpty)
          Text(
            'Nothing matches "${query.trim()}". Try a material such as '
            'blocks, paint, tiles, wire or pipe.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          _MaterialGrid(specs: results, showCategory: true),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) => ResponsiveGrid(
    // Two or four columns: three would leave the fourth card alone.
    columnsFor: (w) => w >= 760 ? 4 : 2,
    children: [
      for (final c in MaterialCategory.values) _CategoryCard(category: c),
    ],
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final MaterialCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = materialsIn(category).length;
    return Semantics(
      button: true,
      label: '${category.label}, $count calculators',
      excludeSemantics: true,
      child: TapCard(
        padding: const EdgeInsets.all(Space.lg),
        onTap: () => context.go(Routes.category(category)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile.category(category, size: 52),
            const SizedBox(height: Space.lg),
            Text(category.label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              category.tagline,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Flexible(
                  child: Text(
                    '$count calculators',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: Space.xs),
                Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialGrid extends StatelessWidget {
  const _MaterialGrid({required this.specs, this.showCategory = false});

  final List<MaterialSpec> specs;
  final bool showCategory;

  @override
  Widget build(BuildContext context) => ResponsiveGrid(
    columnsFor: (w) => w >= 640 ? 2 : 1,
    children: [
      for (final s in specs) MaterialTile(spec: s, showCategory: showCategory),
    ],
  );
}

/// The last few calculations, to pick up where the user left off.
class _Recent extends StatelessWidget {
  const _Recent();

  @override
  Widget build(BuildContext context) {
    final recent = context.select<EstimatesController, List<Estimate>>(
      (c) => c.history.take(3).toList(),
    );
    if (recent.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Recent',
          trailing: TextButton(
            onPressed: () => context.go(Routes.history),
            child: const Text('See all'),
          ),
        ),
        for (final (i, e) in recent.indexed) ...[
          if (i > 0) const SizedBox(height: Space.sm),
          EstimateTile(
            estimate: e,
            subtitle: e.createdAt.year < 2000
                ? formatQuantity(e.quantity, e.unit)
                : '${formatQuantity(e.quantity, e.unit)} · '
                      '${formatDateTime(e.createdAt)}',
            onTap: () {
              final spec = materialById(e.materialId);
              context.go(
                spec == null
                    ? Routes.history
                    : Routes.material(spec, fromEstimate: e.id),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TapCard(
      color: theme.colorScheme.surfaceContainer,
      onTap: () => context.go(Routes.help),
      child: Row(
        children: [
          IconTile(icon: Icons.lightbulb_outline, size: 44, category: null),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New here?', style: theme.textTheme.titleSmall),
                Text(
                  'See how estimates work and how to send them to Google '
                  'Sheets.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
