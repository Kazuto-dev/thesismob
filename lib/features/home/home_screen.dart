import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../materials/catalog.dart';
import '../../materials/material_spec.dart';
import '../../router.dart';
import '../../state/estimates_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageTitle(
      title: null,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _BrandHeader(),
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SummaryShortcut(),
                    const SectionHeader('Choose a category'),
                    _CategoryGrid(categories: MaterialCategory.values),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Short viewports (phones in landscape) get a slimmer header.
    final short = MediaQuery.sizeOf(context).height < 560;
    final mark = ExcludeSemantics(
      child: Image.asset(
        'assets/images/brand/house.png',
        height: short ? 44 : 88,
        color: Brand.onBrand,
      ),
    );
    final title = Column(
      crossAxisAlignment: short
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Semantics(
          header: true,
          child: Text(
            'BuildQuantify',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Brand.onBrand,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          'Estimate construction materials and costs',
          textAlign: short ? TextAlign.start : TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(color: Brand.onBrand),
        ),
      ],
    );

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: Brand.brandGradient),
      child: SafeArea(
        bottom: false,
        child: ContentWidth(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: short ? 12 : 28),
            child: Stack(
              children: [
                if (short)
                  Row(
                    children: [
                      mark,
                      const SizedBox(width: 16),
                      Expanded(child: title),
                      const SizedBox(width: 48),
                    ],
                  )
                else
                  Center(
                    child: Column(
                      children: [mark, const SizedBox(height: 12), title],
                    ),
                  ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    tooltip: 'Help',
                    color: Brand.onBrand,
                    icon: const Icon(Icons.help_outline),
                    onPressed: () => context.go(Routes.help),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the running summary total once the user has added something.
class _SummaryShortcut extends StatelessWidget {
  const _SummaryShortcut();

  @override
  Widget build(BuildContext context) {
    final (count, total) = context.select<EstimatesController, (int, double)>(
      (c) => (c.summary.length, c.summaryTotal),
    );
    if (count == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Card(
        color: theme.colorScheme.primaryContainer,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Icon(
            Icons.receipt_long,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          title: Text('Summary: ${formatMoney(total)}'),
          subtitle: Text(count == 1 ? '1 item' : '$count items'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(Routes.summary),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<MaterialCategory> categories;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        // Two or four columns: three would leave the fourth card alone.
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        final rows = <Widget>[];
        for (var i = 0; i < categories.length; i += columns) {
          final slice = categories.skip(i).take(columns).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) const SizedBox(width: gap),
                    Expanded(
                      child: j < slice.length
                          ? _CategoryCard(category: slice[j])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
          rows.add(const SizedBox(height: gap));
        }
        return Column(children: rows);
      },
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({required this.category});

  final MaterialCategory category;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = widget.category;
    final count = materialsIn(category).length;
    return Semantics(
      button: true,
      label: '${category.label}, $count calculators',
      excludeSemantics: true,
      onTap: () => context.go(Routes.category(category)),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: _focused
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: _focused ? 3 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => context.go(Routes.category(category)),
          onFocusChange: (f) => setState(() => _focused = f),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/categories/${category.name}.png',
                  height: 72,
                  excludeFromSemantics: true,
                ),
                const SizedBox(height: 12),
                Text(
                  category.label,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  category.tagline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
