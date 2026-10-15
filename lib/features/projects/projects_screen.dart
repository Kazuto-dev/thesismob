import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/project.dart';
import '../../router.dart';
import '../../state/projects_controller.dart';
import 'project_actions.dart';
import 'project_picker.dart';

/// Every project, most recently changed first.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProjectsController>();
    final projects = controller.projects;
    final activeId = controller.active.id;
    final wide = WindowSize.of(context) != WindowSize.compact;
    return PageTitle(
      title: 'Projects',
      child: Scaffold(
        appBar: AppBar(title: const Text('Projects')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final created = await createProject(context);
            if (created != null && context.mounted) {
              context.go(Routes.project);
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('New project'),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: Space.sm,
            bottom: bottomClearance(context) + 72,
          ),
          child: ContentWidth(
            maxWidth: 1040,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Keep each house, renovation or bid separate. Estimates go '
                  'to the active project.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.lg),
                ResponsiveGrid(
                  columnsFor: (w) => wide ? (w / 320).floor().clamp(1, 3) : 1,
                  children: [
                    for (final p in projects)
                      _ProjectCard(project: p, active: p.id == activeId),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.active});

  final Project project;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = project;
    final details = [
      if (p.client.isNotEmpty) p.client,
      if (p.location.isNotEmpty) p.location,
    ].join(' · ');
    return Semantics(
      button: true,
      selected: active,
      child: TapCard(
        color: active ? scheme.primaryContainer : null,
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.md,
          Space.xs,
          Space.lg,
        ),
        onTap: () {
          context.read<ProjectsController>().setActive(p.id);
          context.go(Routes.project);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (active)
                  Padding(
                    padding: const EdgeInsets.only(left: Space.sm),
                    child: Chip(
                      label: const Text('Active'),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: scheme.primary),
                    ),
                  ),
                MenuAnchor(
                  builder: (context, c, _) => IconButton(
                    tooltip: 'Actions for ${p.name}',
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => c.isOpen ? c.close() : c.open(),
                  ),
                  menuChildren: [
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.copy_all_outlined),
                      onPressed: () => duplicateProject(context, p),
                      child: const Text('Duplicate'),
                    ),
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.delete_outline),
                      onPressed: () => confirmDeleteProject(context, p),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            if (details.isNotEmpty)
              Text(
                details,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: Space.md),
            Text(
              formatMoney(p.breakdown.total),
              style: tabular(theme.textTheme.headlineSmall),
            ),
            Text(
              '${p.items.length == 1 ? '1 item' : '${p.items.length} items'}'
              ' · ${p.costs.isContractorBid ? 'Contractor bid' : 'Owner budget'}'
              ' · ${formatDate(p.updatedAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
