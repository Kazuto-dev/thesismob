import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../materials/catalog.dart';
import '../../materials/material_spec.dart';
import '../../router.dart';
import '../../state/appearance_controller.dart';
import '../../state/experience.dart';
import '../../state/estimates_controller.dart';
import '../../data/checklists.dart';
import '../../state/projects_controller.dart';
import '../../state/tips_controller.dart';
import '../common/tiles.dart';
import '../projects/project_picker.dart';

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
                    const _ExperienceQuestion(),
                    const _GetStarted(),
                    SectionHeader(context.tr('Categories')),
                    const _CategoryGrid(),
                    SectionHeader(
                      context.tr(
                        context.plainWords
                            ? 'Common jobs around the house'
                            : 'Popular calculators',
                      ),
                    ),
                    _MaterialGrid(
                      specs: [for (final id in _popular) materialById(id)!],
                    ),
                    const _Recent(),
                    const SizedBox(height: Space.xxl),
                    const _QuickBudgetCard(),
                    const SizedBox(height: Space.md),
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
                  context.tr('What are you building?'),
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
                  context.tr(
                    'Estimate how much material to buy and what it costs, '
                    'using sizes sold in the Philippines.',
                  ),
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
                      label: Text(context.tr('Open project')),
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
          hintText: context.tr('Search, e.g. paint or yero'),
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: palette.onInkMuted,
          ),
          filled: true,
          fillColor: palette.inkRaised,
          prefixIcon: Icon(Icons.search, color: palette.onInkMuted),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: context.tr('Clear search'),
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
              ? context.tr('No matches')
              : context.tr(
                  results.length == 1 ? '1 material' : '{n} materials',
                  {'n': results.length},
                ),
        ),
        if (results.isEmpty)
          Text(
            context.tr(
              'Nothing matches "{query}". Try a material such as blocks, '
              'paint, tiles, wire or pipe.',
              {'query': query.trim()},
            ),
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
    final label = context.categoryLabel(category);
    return Semantics(
      button: true,
      label: '$label, $count calculators',
      excludeSemantics: true,
      child: TapCard(
        padding: const EdgeInsets.all(Space.lg),
        onTap: () => context.go(Routes.category(category)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile.category(category, size: 52),
            const SizedBox(height: Space.lg),
            Text(label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              context.categoryTagline(category),
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
                    context.tr('{n} calculators', {'n': count}),
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
          context.tr('Recent'),
          trailing: TextButton(
            onPressed: () => context.go(Routes.history),
            child: Text(context.tr('See all')),
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

/// Asks once, on the Homeowners Edition, whether the user knows
/// construction, so calculators can be named in everyday words for
/// beginners. Settings can change the answer later.
class _ExperienceQuestion extends StatelessWidget {
  const _ExperienceQuestion();

  @override
  Widget build(BuildContext context) {
    final answered = context.select<AppearanceController, bool>(
      (a) => a.experience != null,
    );
    if (answered || !context.asksExperience) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    void answer(Experience e) =>
        context.read<AppearanceController>().setExperience(e);
    return Padding(
      padding: const EdgeInsets.only(top: Space.xl),
      child: Card(
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  context.tr('Do you know construction?'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                context.tr(
                  "If you're new to it, calculators are named by the job, "
                  'such as "Build a block wall", with a line on what each '
                  'one works out. You can change this in Settings.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: Space.md),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  FilledButton(
                    onPressed: () => answer(Experience.beginner),
                    child: Text(context.tr("I'm new to this")),
                  ),
                  OutlinedButton(
                    onPressed: () => answer(Experience.experienced),
                    child: Text(context.tr('I know construction')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three steps for someone who has not estimated anything yet, and a
/// quick way into a house project with its checklist.
class _GetStarted extends StatelessWidget {
  const _GetStarted();

  static const _steps = [
    (Icons.calculate_outlined, 'Pick a calculator and type your measurements'),
    (Icons.add_task, 'Add the result to a project'),
    (Icons.picture_as_pdf_outlined, 'Download a PDF or save to Google Sheets'),
  ];

  @override
  Widget build(BuildContext context) {
    final fresh = context.select<EstimatesController, bool>(
      (c) => c.history.isEmpty,
    );
    final empty = context.select<ProjectsController, bool>(
      (c) => c.projects.every((p) => p.items.isEmpty && p.checklist.isEmpty),
    );
    final (dismissed, pinned) = context.select<TipsController, (bool, bool)>(
      (c) => (
        c.isDismissed(TipsController.getStarted),
        c.isPinned(TipsController.getStarted),
      ),
    );
    // One card at a time: the experience question comes first.
    final asking =
        context.asksExperience &&
        context.select<AppearanceController, bool>((a) => a.experience == null);
    // Reopened from Settings, it shows even once the steps are done.
    if (dismissed || asking || !(pinned || fresh && empty)) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: Space.xl),
      child: Card(
        color: scheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(Space.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  context.tr('Get started'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: Space.md),
              for (final (i, (icon, text)) in _steps.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        child: Text(
                          '${i + 1}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: Space.md),
                      Icon(icon, size: 20, color: scheme.onPrimaryContainer),
                      const SizedBox(width: Space.sm),
                      Expanded(
                        child: Text(
                          context.tr(text),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  FilledButton.icon(
                    onPressed: () async {
                      final created = await createProject(
                        context,
                        checklist: houseChecklist,
                      );
                      if (created != null && context.mounted) {
                        context.go(Routes.project);
                      }
                    },
                    icon: const Icon(Icons.house_outlined),
                    label: Text(context.tr('Plan a house')),
                  ),
                  TextButton(
                    onPressed: () => context.read<TipsController>().dismiss(
                      TipsController.getStarted,
                    ),
                    child: Text(context.tr('Not now')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickBudgetCard extends StatelessWidget {
  const _QuickBudgetCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TapCard(
      color: theme.colorScheme.surfaceContainer,
      onTap: () => context.go(Routes.quickBudget),
      child: Row(
        children: [
          IconTile(icon: Icons.speed_outlined, size: 44, category: null),
          const SizedBox(width: Space.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Quick budget by floor area'),
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  context.tr(
                    'A first idea of what a house costs, before measuring '
                    'anything.',
                  ),
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
                Text(
                  context.tr('New here?'),
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  context.tr(
                    'See how estimates work and how to send them to Google '
                    'Sheets.',
                  ),
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
