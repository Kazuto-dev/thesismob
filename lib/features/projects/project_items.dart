import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/estimate.dart';
import '../../data/project.dart';
import '../../data/rooms.dart';
import '../../data/unit_prices.dart';
import '../../materials/catalog.dart';
import '../../router.dart';
import 'unit_price_view.dart';
import '../../state/projects_controller.dart';

// What can be done to an item in a project, from its menu, its details
// sheet or the bill of quantities grid.

/// Opens the item in its calculator to change it.
void editItem(BuildContext context, Project project, Estimate e) {
  final spec = materialById(e.materialId);
  if (spec == null) return;
  context.go(Routes.material(spec, fromEstimate: e.id, inProject: project.id));
}

void duplicateItem(BuildContext context, Project project, Estimate e) {
  final controller = context.read<ProjectsController>();
  final copy = controller.duplicateItem(e.id, projectId: project.id);
  if (copy == null) return;
  showMessage(
    context,
    'Duplicated ${e.title}.',
    action: SnackBarAction(
      label: context.tr('Undo'),
      onPressed: () => controller.removeItem(copy.id, projectId: project.id),
    ),
  );
}

/// Moves the item up or down within its trade.
void moveItem(
  BuildContext context,
  Project project,
  Estimate e, {
  required bool up,
}) => context.read<ProjectsController>().moveItem(
  e.id,
  up: up,
  projectId: project.id,
  groupOf: (x) => materialById(x.materialId)?.category,
);

void removeItem(BuildContext context, Project project, Estimate e) {
  final controller = context.read<ProjectsController>();
  final removed = controller.removeItem(e.id, projectId: project.id);
  if (removed == null) return;
  showMessage(
    context,
    'Removed ${e.title}.',
    action: SnackBarAction(
      label: context.tr('Undo'),
      onPressed: () => controller.restoreItem(
        removed.index,
        removed.estimate,
        projectId: project.id,
      ),
    ),
  );
}

/// Asks for the item's name or mark and a note.
Future<void> labelItem(
  BuildContext context,
  Project project,
  Estimate e,
) async {
  final result = await showDialog<({String mark, String note})>(
    context: context,
    builder: (_) => _LabelDialog(estimate: e),
  );
  if (result == null || !context.mounted) return;
  context.read<ProjectsController>().labelItem(
    e.id,
    mark: result.mark,
    note: result.note,
    projectId: project.id,
  );
}

/// The item's materials and what can be done with it.
void showItemDetails(BuildContext context, Project project, Estimate e) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) {
      void then(void Function() action) {
        Navigator.of(sheet).pop();
        action();
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Space.xl,
          Space.sm,
          Space.xl,
          Space.xl,
        ),
        child: _ItemDetails(
          estimate: e,
          analyses: analyseEstimate(e, project.costs),
          onEdit: materialById(e.materialId) == null
              ? null
              : () => then(() => editItem(context, project, e)),
          onLabel: () => then(() => labelItem(context, project, e)),
          onDuplicate: () => then(() => duplicateItem(context, project, e)),
          onRemove: () => then(() => removeItem(context, project, e)),
        ),
      );
    },
  );
}

/// The actions on one item, as a menu button.
class ItemMenu extends StatelessWidget {
  const ItemMenu({
    super.key,
    required this.project,
    required this.estimate,
    this.first = false,
    this.last = false,
  });

  final Project project;
  final Estimate estimate;

  /// Whether the item is first or last in its trade, so cannot move
  /// further that way.
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final e = estimate;
    final canEdit = materialById(e.materialId) != null;
    return MenuAnchor(
      builder: (context, controller, _) => IconButton(
        tooltip: 'Actions for ${e.title}',
        icon: const Icon(Icons.more_vert),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: canEdit ? () => editItem(context, project, e) : null,
          child: Text(context.tr('Edit in calculator')),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.label_outline),
          onPressed: () => labelItem(context, project, e),
          child: Text(context.tr('Name and note')),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.copy_outlined),
          onPressed: () => duplicateItem(context, project, e),
          child: Text(context.tr('Duplicate')),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.arrow_upward),
          onPressed: first
              ? null
              : () => moveItem(context, project, e, up: true),
          child: Text(context.tr('Move up')),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.arrow_downward),
          onPressed: last
              ? null
              : () => moveItem(context, project, e, up: false),
          child: Text(context.tr('Move down')),
        ),
        const Divider(),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_outline),
          onPressed: () => removeItem(context, project, e),
          child: Text(context.tr('Remove')),
        ),
      ],
    );
  }
}

class _ItemDetails extends StatelessWidget {
  const _ItemDetails({
    required this.estimate,
    required this.analyses,
    required this.onEdit,
    required this.onLabel,
    required this.onDuplicate,
    required this.onRemove,
  });

  final Estimate estimate;

  /// The unit price analysis of each work item in the estimate.
  final List<WorkAnalysis> analyses;
  final VoidCallback? onEdit;
  final VoidCallback onLabel;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = estimate;
    final spec = materialById(e.materialId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (spec != null)
              IconTile.material(spec, size: 48)
            else
              const IconTile(icon: Icons.inventory_2_outlined, size: 48),
            const SizedBox(width: Space.md),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(e.title, style: theme.textTheme.titleLarge),
              ),
            ),
          ],
        ),
        if (e.note != null) ...[
          const SizedBox(height: Space.md),
          Text(
            e.note!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (e.fromRooms) ...[
          const SizedBox(height: Space.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.meeting_room_outlined,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  context.tr(
                    'Made from the room schedule. Its measurements are '
                    'replaced when you update finishes from rooms; options '
                    'and prices you set in the calculator are kept.',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: Space.lg),
        KeyValueLine(
          '${e.label}, ${formatQuantity(e.quantity, e.unit)} × '
          '${formatMoney(e.unitPrice)}',
          formatMoney(e.total),
        ),
        for (final l in e.companions) ...[
          const Divider(),
          KeyValueLine(
            '${l.label}, ${formatNumber(l.quantity)} ${l.unit} × '
            '${formatMoney(l.unitPrice)}',
            formatMoney(l.total),
          ),
        ],
        const Divider(),
        KeyValueLine(
          context.tr('Materials total'),
          formatMoney(e.grandTotal),
          emphasize: true,
        ),
        if (analyses.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          Semantics(
            header: true,
            child: Text(
              context.tr('Unit price analysis'),
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: Space.xs),
          Text(
            context.tr(
              'Each work item with its materials, crew and equipment. Tap '
              'one to see how its unit cost is built up.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          for (final a in analyses) ...[
            const SizedBox(height: Space.sm),
            UnitPriceCard(analysis: a),
          ],
        ],
        const SizedBox(height: Space.xl),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            if (onEdit != null)
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.tr('Edit')),
              ),
            OutlinedButton.icon(
              onPressed: onLabel,
              icon: const Icon(Icons.label_outline),
              label: Text(context.tr('Name and note')),
            ),
            OutlinedButton.icon(
              onPressed: onDuplicate,
              icon: const Icon(Icons.copy_outlined),
              label: Text(context.tr('Duplicate')),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
              label: Text(context.tr('Remove')),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabelDialog extends StatefulWidget {
  const _LabelDialog({required this.estimate});

  final Estimate estimate;

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
  late final _mark = TextEditingController(text: widget.estimate.mark);
  late final _note = TextEditingController(text: widget.estimate.note);

  @override
  void dispose() {
    _mark.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() =>
      Navigator.of(context).pop((mark: _mark.text, note: _note.text));

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.estimate.label),
    scrollable: true,
    content: SizedBox(
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _mark,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            decoration: InputDecoration(
              labelText: context.tr('Name or mark'),
              hintText: context.tr('F1, Kitchen wall, 2nd floor slab'),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: Space.lg),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(200)],
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: context.tr('Note'),
              hintText: context.tr(
                'Where it is, what it includes, what to check',
              ),
              helperText: context.tr('Printed in the bill of quantities'),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(onPressed: _save, child: Text(context.tr('Save'))),
    ],
  );
}
