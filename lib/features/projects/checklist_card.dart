import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/project.dart';
import '../../materials/catalog.dart';
import '../../materials/material_spec.dart';
import '../../router.dart';
import '../../state/projects_controller.dart';

/// The calculators a project's job needs, what is done and what is next.
class ChecklistCard extends StatefulWidget {
  const ChecklistCard({super.key, required this.project});

  final Project project;

  @override
  State<ChecklistCard> createState() => _ChecklistCardState();
}

class _ChecklistCardState extends State<ChecklistCard> {
  /// Entries shown before "Show all".
  static const _next = 3;

  bool _all = false;

  void _estimate(MaterialSpec spec) {
    context.read<ProjectsController>().setActive(widget.project.id);
    context.go(Routes.material(spec));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = widget.project;
    final controller = context.read<ProjectsController>();
    final entries = [for (final id in p.checklist) ?materialById(id)];
    final needed = entries.where((s) => !p.notNeeded.contains(s.id)).length;
    final done = entries.where((s) => p.isEstimated(s.id)).length;
    final toDo = [
      for (final s in entries)
        if (!p.isEstimated(s.id) && !p.notNeeded.contains(s.id)) s,
    ];
    final shown = _all ? entries : toDo.take(_next).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.md,
          Space.sm,
          Space.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Checklist',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        toDo.isEmpty
                            ? 'All $needed done'
                            : '$done of $needed done · next: '
                                  '${toDo.first.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                MenuAnchor(
                  builder: (context, menu, _) => IconButton(
                    tooltip: 'Checklist actions',
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => menu.isOpen ? menu.close() : menu.open(),
                  ),
                  menuChildren: [
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.playlist_remove),
                      onPressed: () => controller.removeChecklist(p.id),
                      child: const Text('Remove checklist'),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: Space.sm, top: Space.sm),
              child: Semantics(
                label: '$done of $needed done',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.sm),
                  child: LinearProgressIndicator(
                    value: needed == 0 ? 1 : done / needed,
                    minHeight: 6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.sm),
            for (final spec in shown)
              _Entry(
                spec: spec,
                done: p.isEstimated(spec.id),
                notNeeded: p.notNeeded.contains(spec.id),
                onEstimate: () => _estimate(spec),
                onNeeded: (needed) =>
                    controller.setNeeded(p.id, spec.id, needed: needed),
              ),
            if (entries.length > _next || _all)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _all = !_all),
                  child: Text(
                    _all ? 'Show what is next' : 'Show all ${entries.length}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.spec,
    required this.done,
    required this.notNeeded,
    required this.onEstimate,
    required this.onNeeded,
  });

  final MaterialSpec spec;
  final bool done;
  final bool notNeeded;
  final VoidCallback onEstimate;
  final ValueChanged<bool> onNeeded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final status = done
        ? 'Estimated'
        : notNeeded
        ? 'Not needed'
        : spec.blurb;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Row(
        children: [
          if (done)
            Icon(Icons.check_circle, color: palette.success, size: 28)
          else
            Opacity(
              opacity: notNeeded ? 0.5 : 1,
              child: IconTile.material(spec, size: 36),
            ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: notNeeded ? TextDecoration.lineThrough : null,
                    color: notNeeded ? scheme.onSurfaceVariant : null,
                  ),
                ),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!done && !notNeeded) ...[
            TextButton(onPressed: onEstimate, child: const Text('Estimate')),
            IconButton(
              tooltip: '${spec.name} not needed',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => onNeeded(false),
            ),
          ] else if (notNeeded)
            TextButton(
              onPressed: () => onNeeded(true),
              child: const Text('Needed'),
            )
          else
            TextButton(onPressed: onEstimate, child: const Text('Add more')),
        ],
      ),
    );
  }
}
