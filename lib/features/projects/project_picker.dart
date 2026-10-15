import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/project.dart';
import '../../state/projects_controller.dart';

/// What the user typed into the project details dialog.
typedef ProjectDetails = ({
  String name,
  String client,
  String location,
  bool contractor,
});

/// Asks for a project's name, client and location. With no [project] it
/// creates one and also asks whether it is a contractor's bid.
Future<ProjectDetails?> showProjectDetailsDialog(
  BuildContext context, {
  Project? project,
}) => showDialog<ProjectDetails>(
  context: context,
  builder: (_) => _ProjectDetailsDialog(project: project),
);

class _ProjectDetailsDialog extends StatefulWidget {
  const _ProjectDetailsDialog({this.project});

  final Project? project;

  @override
  State<_ProjectDetailsDialog> createState() => _ProjectDetailsDialogState();
}

class _ProjectDetailsDialogState extends State<_ProjectDetailsDialog> {
  late final _name = TextEditingController(text: widget.project?.name);
  late final _client = TextEditingController(text: widget.project?.client);
  late final _location = TextEditingController(text: widget.project?.location);
  bool _contractor = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _client.dispose();
    _location.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the project a name');
      return;
    }
    Navigator.of(context).pop((
      name: name,
      client: _client.text.trim(),
      location: _location.text.trim(),
      contractor: _contractor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final creating = widget.project == null;
    return AlertDialog(
      title: Text(creating ? 'New project' : 'Project details'),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 80,
              decoration: InputDecoration(
                labelText: 'Project name',
                hintText: 'Santos residence',
                errorText: _error,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _client,
              textCapitalization: TextCapitalization.words,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Client',
                helperText: 'Optional',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: Space.sm),
            TextField(
              controller: _location,
              textCapitalization: TextCapitalization.words,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Lot 4, Antipolo, Rizal',
                helperText: 'Optional',
              ),
              onSubmitted: (_) => _save(),
            ),
            if (creating) ...[
              const SizedBox(height: Space.md),
              Text(
                'Budget style',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: Space.sm),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('Owner budget')),
                  ButtonSegment(value: true, label: Text('Contractor bid')),
                ],
                selected: {_contractor},
                onSelectionChanged: (s) =>
                    setState(() => _contractor = s.first),
              ),
              const SizedBox(height: Space.xs),
              Text(
                _contractor
                    ? 'Adds minor tools, overhead, profit and 12% VAT. You '
                          'can change these later.'
                    : 'Materials, labour and a 10% contingency. You can '
                          'change these later.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(creating ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}

/// Creates a project from the details dialog and makes it active.
Future<Project?> createProject(BuildContext context) async {
  final details = await showProjectDetailsDialog(context);
  if (details == null || !context.mounted) return null;
  return context.read<ProjectsController>().create(
    details.name,
    client: details.client,
    location: details.location,
    costs: details.contractor ? CostSettings.contractor : CostSettings.owner,
  );
}

/// Lets the user choose which project new estimates go into.
Future<void> showProjectPicker(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ProjectPicker(),
    );

class _ProjectPicker extends StatelessWidget {
  const _ProjectPicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<ProjectsController>();
    final activeId = controller.active.id;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.sm,
              Space.xl,
              Space.sm,
            ),
            child: Semantics(
              header: true,
              child: Text(
                'Add estimates to',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in controller.projects)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Space.xl,
                    ),
                    leading: Icon(
                      p.id == activeId
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: p.id == activeId
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    title: Text(p.name),
                    subtitle: Text(
                      '${p.items.length == 1 ? '1 item' : '${p.items.length} items'}'
                      ' · ${formatMoney(p.breakdown.total)}',
                      style: tabular(theme.textTheme.bodySmall),
                    ),
                    selected: p.id == activeId,
                    onTap: () {
                      controller.setActive(p.id);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: OutlinedButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final created = await createProject(context);
                if (created != null) navigator.pop();
              },
              icon: const Icon(Icons.add),
              label: const Text('New project'),
            ),
          ),
        ],
      ),
    );
  }
}
