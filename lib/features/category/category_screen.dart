import 'package:material_ui/material_ui.dart';

import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../materials/catalog.dart';
import '../../materials/material_spec.dart';
import '../common/tiles.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.category});

  final MaterialCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final materials = materialsIn(category);
    final colors = AppPalette.of(context).category(category);
    return PageTitle(
      title: category.label,
      child: Scaffold(
        appBar: AppBar(title: Text('${category.label} materials')),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomClearance(context)),
          child: ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Space.sm),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.container,
                    borderRadius: BorderRadius.circular(Radii.xl),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Space.xl),
                    child: Row(
                      children: [
                        IconTile.category(
                          category,
                          size: 64,
                          background: raisedSurface(theme.colorScheme),
                        ),
                        const SizedBox(width: Space.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.tagline,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colors.onContainer,
                                ),
                              ),
                              const SizedBox(height: Space.xs),
                              Text(
                                '${materials.length} calculators',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Space.xl),
                ResponsiveGrid(
                  columnsFor: (w) => w >= 640 ? 2 : 1,
                  children: [for (final m in materials) MaterialTile(spec: m)],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
