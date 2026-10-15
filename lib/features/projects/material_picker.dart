import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../materials/catalog.dart';
import '../../materials/material_spec.dart';
import '../../router.dart';
import '../../state/projects_controller.dart';
import '../common/tiles.dart';

/// Lets the user pick a calculator for a new estimate in [projectId],
/// which becomes the project new estimates go to.
Future<void> showMaterialPicker(BuildContext context, {String? projectId}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        builder: (_, scroll) => _MaterialPicker(
          scroll: scroll,
          onPick: (spec) {
            final projects = context.read<ProjectsController>();
            if (projectId != null) projects.setActive(projectId);
            Navigator.of(sheet).pop();
            context.go(Routes.material(spec));
          },
        ),
      ),
    );

class _MaterialPicker extends StatefulWidget {
  const _MaterialPicker({required this.scroll, required this.onPick});

  final ScrollController scroll;
  final ValueChanged<MaterialSpec> onPick;

  @override
  State<_MaterialPicker> createState() => _MaterialPickerState();
}

class _MaterialPickerState extends State<_MaterialPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim();
    final groups = [
      for (final c in MaterialCategory.values)
        (
          category: c,
          specs: [
            for (final m in materialsIn(c))
              if (query.isEmpty || m.matches(query)) m,
          ],
        ),
    ].where((g) => g.specs.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.xl,
            Space.sm,
            Space.xl,
            Space.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  context.tr('Add an estimate'),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: Space.md),
              TextField(
                autofocus: false,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.tr('Search, e.g. footing, tiles, wire'),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? Center(
                  child: Text(
                    'No calculator matches "$query".',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView(
                  controller: widget.scroll,
                  padding: const EdgeInsets.fromLTRB(
                    Space.xl,
                    0,
                    Space.xl,
                    Space.xl,
                  ),
                  children: [
                    for (final g in groups) ...[
                      SectionHeader(
                        g.category.label,
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          Space.md,
                          0,
                          Space.sm,
                        ),
                      ),
                      for (final spec in g.specs) ...[
                        MaterialTile(
                          spec: spec,
                          onTap: () => widget.onPick(spec),
                        ),
                        const SizedBox(height: Space.sm),
                      ],
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
