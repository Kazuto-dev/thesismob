import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../data/project.dart';
import '../../data/rooms.dart';
import '../../materials/items_finishes.dart';
import '../../router.dart';
import '../../state/price_book_controller.dart';
import '../../state/projects_controller.dart';
import 'room_editor.dart';

/// Whether [project]'s finish estimates match its rooms.
bool _upToDate(BuildContext context, Project project) => roomFinishesUpToDate(
  project.rooms,
  project.items,
  priceOf: context.read<PriceBookController>().priceOf,
);

/// Makes or updates the finish estimates of [project] from its rooms, with
/// an undo.
void updateFinishesFromRooms(BuildContext context, Project project) {
  final controller = context.read<ProjectsController>();
  final made = controller.updateRoomFinishes(
    project.id,
    context.read<PriceBookController>().priceOf,
  );
  final count = controller.byId(project.id)!.items.where((e) => e.fromRooms);
  showMessage(
    context,
    context.tr('Updated the finishes: {n} estimates from the rooms.', {
      'n': count.length,
    }),
    action: SnackBarAction(
      label: context.tr('Undo'),
      onPressed: () =>
          controller.restoreItems(made.before, projectId: project.id),
    ),
  );
  if (made.problems.isNotEmpty) {
    showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(context.tr('Some finishes were left out')),
        content: Text(made.problems.join('\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: Text(context.tr('OK')),
          ),
        ],
      ),
    );
  }
}

/// A project's room schedule: each room once, the totals, and the button
/// that turns the rooms into finish estimates.
class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key, required this.projectId});

  final String projectId;

  static List<String> _levels(List<Room> rooms) => [
    ...{
      for (final r in rooms)
        if (r.level.trim().isNotEmpty) r.level.trim(),
    },
  ];

  Future<void> _add(BuildContext context, Project project) async {
    final room = await editRoom(context, levels: _levels(project.rooms));
    if (room == null || !context.mounted) return;
    context.read<ProjectsController>().setRooms(project.id, [
      ...project.rooms,
      room,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProjectsController>();
    context.watch<PriceBookController>();
    final project = controller.byId(projectId);
    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Rooms'))),
        body: EmptyState(
          icon: Icons.meeting_room_outlined,
          title: context.tr('Project not found'),
          message: context.tr('It may have been deleted.'),
        ),
      );
    }
    final theme = Theme.of(context);
    final wide = WindowSize.of(context) != WindowSize.compact;
    final levels = <String, List<Room>>{};
    for (final r in project.rooms) {
      (levels[r.level.trim().toLowerCase()] ??= []).add(r);
    }
    return PageTitle(
      title: '${context.tr('Rooms')} · ${project.name}',
      child: Scaffold(
        appBar: AppBar(title: Text(context.tr('Rooms'))),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _add(context, project),
          icon: const Icon(Icons.add),
          label: Text(context.tr('Add a room')),
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
                  context.tr(
                    'Enter each room of {project} once. Rooms on the same '
                    'level that share a finish become one estimate, made '
                    'with that finish\'s calculator.',
                    {'project': project.name},
                  ),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.lg),
                _Summary(project: project),
                if (project.rooms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.xxl),
                    child: Text(
                      context.tr(
                        'No rooms yet. Add the first one: its size, doors '
                        'and windows, and the finishes of its floor, walls '
                        'and ceiling.',
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                for (final rooms in levels.values) ...[
                  SectionHeader(
                    rooms.first.level.trim().isEmpty
                        ? context.tr('No level')
                        : rooms.first.level.trim(),
                    trailing: Text(
                      formatArea(roomTotals(rooms).floor),
                      style: tabular(theme.textTheme.titleSmall),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      Space.xl,
                      0,
                      Space.sm,
                    ),
                  ),
                  ResponsiveGrid(
                    columnsFor: (w) => wide ? (w / 360).floor().clamp(1, 3) : 1,
                    children: [
                      for (final r in rooms)
                        _RoomCard(project: project, room: r),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The rooms' totals and whether the finish estimates are up to date.
class _Summary extends StatelessWidget {
  const _Summary({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = roomTotals(project.rooms);
    final made = project.items.where((e) => e.fromRooms).length;
    final upToDate = _upToDate(context, project);
    final status = project.rooms.isEmpty && made == 0
        ? 'Add rooms, then make their finish estimates here.'
        : upToDate
        ? 'The {n} finish estimates match the rooms.'
        : made == 0
        ? 'The rooms have no finish estimates yet.'
        : 'The rooms changed since the finishes were last updated.';
    const line = EdgeInsets.symmetric(vertical: 4);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeyValueLine(
              context.tr('Rooms'),
              '${project.rooms.length}',
              padding: line,
            ),
            KeyValueLine(
              context.tr('Floor area'),
              formatArea(totals.floor),
              emphasize: true,
              padding: line,
            ),
            KeyValueLine(
              context.tr('Walls, less doors and windows'),
              formatArea(totals.walls),
              padding: line,
            ),
            KeyValueLine(
              context.tr('Ceilings'),
              formatArea(totals.ceilings),
              padding: line,
            ),
            KeyValueLine(
              context.tr('Skirting'),
              formatLength(totals.skirting),
              padding: line,
            ),
            const Divider(height: Space.xl),
            Row(
              children: [
                Icon(
                  upToDate ? Icons.check_circle_outline : Icons.update,
                  size: 20,
                  color: upToDate
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    context.tr(status, {'n': made}),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                FilledButton.icon(
                  onPressed: upToDate
                      ? null
                      : () => updateFinishesFromRooms(context, project),
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: Text(context.tr('Update finishes from rooms')),
                ),
                OutlinedButton(
                  onPressed: () => context.go(Routes.projectById(project.id)),
                  child: Text(context.tr('Back to the project')),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Text(
              context.tr(
                'Your own estimates are never changed. In a finish estimate, '
                'the measurements come from the rooms; options and prices you '
                'set in its calculator are kept.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _tile(String id) =>
    tileSizes.where((t) => t.id == id).firstOrNull?.label ?? id;

/// One room: its size and finishes, with its actions.
class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.project, required this.room});

  final Project project;
  final Room room;

  ProjectsController _controller(BuildContext context) =>
      context.read<ProjectsController>();

  Future<void> _edit(BuildContext context) async {
    final edited = await editRoom(
      context,
      room: room,
      levels: RoomsScreen._levels(project.rooms),
    );
    if (edited == null || !context.mounted) return;
    final rooms = _controller(context).byId(project.id)?.rooms ?? const [];
    _controller(context).setRooms(project.id, [
      for (final r in rooms) r.id == room.id ? edited : r,
    ]);
  }

  void _duplicate(BuildContext context) {
    final rooms = _controller(context).byId(project.id)?.rooms ?? const [];
    final index = rooms.indexWhere((r) => r.id == room.id);
    final copy = room.copyWith(
      id: Estimate.newId(DateTime.now()),
      name: context.tr('{name} (copy)', {'name': room.name}),
    );
    _controller(context)
        .setRooms(project.id, [...rooms]..insert(index + 1, copy));
  }

  void _delete(BuildContext context) {
    final controller = _controller(context);
    final rooms = controller.byId(project.id)?.rooms ?? const <Room>[];
    controller.setRooms(project.id, [
      for (final r in rooms)
        if (r.id != room.id) r,
    ]);
    showMessage(
      context,
      context.tr('Deleted {name}.', {'name': room.name}),
      action: SnackBarAction(
        label: context.tr('Undo'),
        onPressed: () => controller.setRooms(project.id, rooms),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = room;
    final size = r.isRectangle
        ? '${formatNumber(r.length!)} × ${formatLength(r.width!)}'
        : context.tr('Other shape');
    final finishes = [
      switch (r.floor) {
        FloorFinish.none => null,
        FloorFinish.tiles => context.tr('Floor: tiles {size}', {
          'size': _tile(r.floorTile),
        }),
        final f => '${context.tr('Floor')}: ${context.tr(f.label)}',
      },
      switch (r.wall) {
        WallFinish.none => null,
        WallFinish.paint => context.tr('Walls: paint'),
        WallFinish.tiles =>
          r.tiledFullHeight
              ? context.tr('Walls: tiles {size}, full height', {
                  'size': _tile(r.wallTile),
                })
              : context.tr('Walls: tiles {size} to {height}, paint above', {
                  'size': _tile(r.wallTile),
                  'height': formatLength(r.tiledHeight),
                }),
      },
      switch ((r.ceiling, r.paintCeiling)) {
        (CeilingFinish.none, false) => null,
        (CeilingFinish.none, true) => context.tr('Ceiling: paint'),
        (final c, final painted) =>
          '${context.tr('Ceiling')}: ${context.tr(c.label)}'
              '${painted ? ', ${context.tr('painted')}' : ''}',
      },
      if (r.lights > 0 || r.outlets > 0)
        context.tr('{lights} lights, {outlets} outlets', {
          'lights': r.lights,
          'outlets': r.outlets,
        }),
    ].nonNulls;
    return Semantics(
      button: true,
      child: TapCard(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.md,
          Space.xs,
          Space.md,
        ),
        onTap: () => _edit(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name.isEmpty ? context.tr('Unnamed room') : r.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$size · ${formatArea(r.floorArea)} · '
                    '${context.tr('{height} high', {'height': formatLength(r.height)})}',
                    style: tabular(
                      theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.xs),
                  for (final f in finishes)
                    Text(f, style: theme.textTheme.bodySmall),
                  if (r.perimeterGuessed)
                    Text(
                      context.tr('Wall length taken as a square room'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            MenuAnchor(
              builder: (context, menu, _) => IconButton(
                tooltip: context.tr('Actions for {name}', {'name': r.name}),
                icon: const Icon(Icons.more_vert),
                onPressed: () => menu.isOpen ? menu.close() : menu.open(),
              ),
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.edit_outlined),
                  onPressed: () => _edit(context),
                  child: Text(context.tr('Edit')),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.copy_outlined),
                  onPressed: () => _duplicate(context),
                  child: Text(context.tr('Duplicate')),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context),
                  child: Text(context.tr('Delete')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The room schedule on the project screen: how many rooms, their floor
/// area, and whether the finish estimates match them.
class RoomsCard extends StatelessWidget {
  const RoomsCard({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    context.watch<PriceBookController>();
    final upToDate = _upToDate(context, project);
    final totals = roomTotals(project.rooms);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.md,
          Space.md,
          Space.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.meeting_room_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          context.tr('Rooms'),
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        [
                          project.rooms.length == 1
                              ? context.tr('1 room')
                              : context.tr('{n} rooms', {
                                  'n': project.rooms.length,
                                }),
                          formatArea(totals.floor),
                          context.tr(
                            upToDate
                                ? 'Finishes up to date'
                                : 'Finishes need updating',
                          ),
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              alignment: WrapAlignment.end,
              children: [
                if (!upToDate)
                  FilledButton(
                    onPressed: () => updateFinishesFromRooms(context, project),
                    child: Text(context.tr('Update finishes')),
                  ),
                OutlinedButton(
                  onPressed: () => context.go(Routes.rooms(project.id)),
                  child: Text(context.tr('Open rooms')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
