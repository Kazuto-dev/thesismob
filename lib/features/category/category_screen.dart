import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/layout.dart';
import '../../core/widgets.dart';
import '../../materials/catalog.dart';
import '../../materials/material_spec.dart';
import '../../router.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.category});

  final MaterialCategory category;

  @override
  Widget build(BuildContext context) {
    final materials = materialsIn(category);
    return PageTitle(
      title: category.label,
      child: Scaffold(
        appBar: AppBar(title: Text('${category.label} materials')),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            ContentWidth(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                    child: Text(
                      category.tagline,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  for (final m in materials) ...[
                    _MaterialTile(spec: m),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.spec});

  final MaterialSpec spec;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: SizedBox.square(
              dimension: 48,
              child: Image.asset(spec.image, excludeFromSemantics: true),
            ),
            title: Text(spec.name),
            subtitle: Text(spec.blurb),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.material(spec)),
          ),
        ),
      ),
    );
  }
}
