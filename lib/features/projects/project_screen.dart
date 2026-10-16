import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/checklists.dart';
import '../../data/project.dart';
import '../../export/project_documents.dart';
import '../../materials/items.dart';
import '../../materials/work_items.dart';
import '../../materials/material_spec.dart';
import '../../router.dart';
import '../../state/price_book_controller.dart';
import '../../state/projects_controller.dart';
import '../../state/google_account_controller.dart';
import '../common/price_dialog.dart';
import '../common/tiles.dart';
import 'bid_actions.dart';
import 'boq_grid.dart';
import 'checklist_card.dart';
import 'checks_card.dart';
import 'contract_tab.dart';
import 'fee_dialogs.dart';
import 'labour_region_picker.dart';
import 'material_picker.dart';
import 'project_actions.dart';
import 'project_items.dart';
import 'project_picker.dart';
import 'rooms_screen.dart';

enum _Tab { items, materials, budget, contract }

/// A project: its budget, the estimates grouped by trade as a bill of
/// quantities, the merged shopping list and the cost settings.
class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key, this.projectId});

  /// The project to show; the active one when null.
  final String? projectId;

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  _Tab _tab = _Tab.items;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProjectsController>();
    final project =
        (widget.projectId == null
            ? null
            : controller.byId(widget.projectId!)) ??
        controller.active;
    final wide = WindowSize.of(context) == WindowSize.expanded;
    final isActive = project.id == controller.active.id;
    final details = [
      if (project.client.isNotEmpty) project.client,
      if (project.location.isNotEmpty) project.location,
    ].join(' · ');

    final header = PageHeader(
      title: project.name,
      subtitle: details.isEmpty
          ? (isActive ? 'New estimates are added here' : null)
          : details,
      actions: [
        IconButton(
          tooltip: context.tr('All projects'),
          icon: const Icon(Icons.folder_copy_outlined),
          onPressed: () => context.go(Routes.projects),
        ),
        _ProjectMenu(project: project),
      ],
    );

    if (project.items.isEmpty &&
        (project.checklist.isNotEmpty || project.rooms.isNotEmpty)) {
      return PageTitle(
        title: project.name,
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomClearance(context)),
              child: ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    if (project.checklist.isNotEmpty)
                      ChecklistCard(project: project),
                    if (project.rooms.isNotEmpty) ...[
                      const SizedBox(height: Space.lg),
                      RoomsCard(project: project),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (project.items.isEmpty) {
      return PageTitle(
        title: project.name,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                ContentWidth(child: header),
                Expanded(
                  child: EmptyState(
                    icon: Icons.request_quote_outlined,
                    title: context.tr('No estimates yet'),
                    message:
                        'Work out a material, then choose "Add to '
                        '${project.name}". The project builds a bill of '
                        'quantities, a shopping list and a budget with labour '
                        'and markups.',
                    action: Wrap(
                      spacing: Space.sm,
                      runSpacing: Space.sm,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => showMaterialPicker(
                            context,
                            projectId: project.id,
                          ),
                          icon: const Icon(Icons.add),
                          label: Text(context.tr('Add an estimate')),
                        ),
                        OutlinedButton(
                          onPressed: () => context.go(Routes.rooms(project.id)),
                          child: Text(context.tr('Enter rooms')),
                        ),
                        OutlinedButton(
                          onPressed: () => context.go(Routes.projects),
                          child: Text(context.tr('All projects')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hero = _BudgetHero(project: project);
    final tabs = SegmentedButton<_Tab>(
      showSelectedIcon: false,
      segments: [
        ButtonSegment(
          value: _Tab.items,
          label: Text(context.tr('Items')),
          icon: wide ? const Icon(Icons.list_alt_outlined) : null,
        ),
        ButtonSegment(
          value: _Tab.materials,
          label: Text(context.tr('To buy')),
          icon: wide ? const Icon(Icons.shopping_cart_outlined) : null,
        ),
        if (!wide)
          ButtonSegment(value: _Tab.budget, label: Text(context.tr('Budget'))),
        ButtonSegment(
          value: _Tab.contract,
          label: Text(context.tr('Contract')),
          icon: wide ? const Icon(Icons.handshake_outlined) : null,
        ),
      ],
      selected: {wide && _tab == _Tab.budget ? _Tab.items : _tab},
      onSelectionChanged: (s) => setState(() => _tab = s.first),
    );
    final tab = wide && _tab == _Tab.budget ? _Tab.items : _tab;
    final body = switch (tab) {
      _Tab.items => _ItemsTab(project: project, grid: wide),
      _Tab.materials => _MaterialsTab(project: project),
      _Tab.budget => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BudgetEditor(
            key: ValueKey('budget-${project.id}'),
            project: project,
          ),
          const SizedBox(height: Space.lg),
          ChecksCard(project: project),
        ],
      ),
      _Tab.contract => ContractTab(
        key: ValueKey('contract-${project.id}'),
        project: project,
      ),
    };

    return PageTitle(
      title: project.name,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomClearance(context)),
            child: ContentWidth(
              maxWidth: wide ? 1240 : 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  if (!isActive) ...[
                    _NotActiveBanner(project: project),
                    const SizedBox(height: Space.lg),
                  ],
                  if (project.checklist.isNotEmpty) ...[
                    ChecklistCard(project: project),
                    const SizedBox(height: Space.lg),
                  ],
                  if (project.rooms.isNotEmpty) ...[
                    RoomsCard(project: project),
                    const SizedBox(height: Space.lg),
                  ],
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: tabs,
                              ),
                              const SizedBox(height: Space.lg),
                              body,
                            ],
                          ),
                        ),
                        const SizedBox(width: Space.xl),
                        SizedBox(
                          width: 400,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              hero,
                              const SizedBox(height: Space.lg),
                              _BudgetEditor(
                                key: ValueKey('budget-${project.id}'),
                                project: project,
                              ),
                              const SizedBox(height: Space.lg),
                              ChecksCard(project: project),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    hero,
                    const SizedBox(height: Space.xl),
                    SizedBox(width: double.infinity, child: tabs),
                    const SizedBox(height: Space.lg),
                    body,
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

class _NotActiveBanner extends StatelessWidget {
  const _NotActiveBanner({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.sm,
          Space.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.tr('New estimates go to another project.'),
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.read<ProjectsController>().setActive(project.id),
              child: Text(context.tr('Add estimates here')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectMenu extends StatelessWidget {
  const _ProjectMenu({required this.project});

  final Project project;

  Future<void> _edit(BuildContext context) async {
    final details = await showProjectDetailsDialog(context, project: project);
    if (details == null || !context.mounted) return;
    context.read<ProjectsController>().updateDetails(
      project.id,
      name: details.name,
      client: details.client,
      location: details.location,
      floorArea: details.floorArea ?? 0,
    );
  }

  void _clear(BuildContext context) {
    final controller = context.read<ProjectsController>();
    final removed = controller.clearItems(projectId: project.id);
    showMessage(
      context,
      'Removed all estimates from ${project.name}.',
      action: SnackBarAction(
        label: context.tr('Undo'),
        onPressed: () =>
            controller.restoreItems(removed, projectId: project.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = project.items.isNotEmpty;
    final saving = context.select<GoogleAccountController, bool>(
      (c) => c.isBusy,
    );
    return MenuAnchor(
      builder: (context, controller, _) => IconButton(
        tooltip: context.tr('Project actions'),
        icon: const Icon(Icons.more_vert),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: () => _edit(context),
          child: Text(context.tr('Edit details')),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.add),
          onPressed: () async {
            final created = await createProject(context);
            if (created != null && context.mounted) {
              context.go(Routes.project);
            }
          },
          child: Text(context.tr('New project')),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.copy_all_outlined),
          onPressed: () => duplicateProject(context, project),
          child: Text(context.tr('Duplicate')),
        ),
        if (project.checklist.isEmpty)
          SubmenuButton(
            leadingIcon: const Icon(Icons.checklist),
            menuChildren: [
              for (final t in checklistTemplates)
                MenuItemButton(
                  onPressed: () => context
                      .read<ProjectsController>()
                      .addChecklist(project.id, t.materials),
                  child: Text(
                    context.tr('{name} checklist', {
                      'name': context.tr(t.name),
                    }),
                  ),
                ),
            ],
            child: Text(context.tr('Add a checklist')),
          ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.meeting_room_outlined),
          onPressed: () => context.go(Routes.rooms(project.id)),
          child: Text(context.tr('Room schedule')),
        ),
        const Divider(),
        MenuItemButton(
          leadingIcon: const Icon(Icons.picture_as_pdf_outlined),
          onPressed: hasItems
              ? () => downloadProjectPdf(context, project)
              : null,
          child: Text(context.tr('Download PDF')),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.grid_on_outlined),
          onPressed: hasItems
              ? () => downloadProjectCsv(context, project)
              : null,
          child: Text(context.tr('Download for Excel (CSV)')),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.content_copy_outlined),
          onPressed: hasItems ? () => copyProjectText(context, project) : null,
          child: Text(context.tr('Copy as text')),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.table_chart_outlined),
          onPressed: hasItems && !saving
              ? () => saveProjectToSheets(context, project)
              : null,
          child: Text(
            project.sheetId == null
                ? 'Save to Google Sheets'
                : 'Update Google Sheet',
          ),
        ),
        if (project.sheetId != null)
          MenuItemButton(
            leadingIcon: const Icon(Icons.open_in_new),
            onPressed: () => openProjectSheet(project),
            child: Text(context.tr('Open in Google Sheets')),
          ),
        ...bidMenuItems(context, project),
        const Divider(),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_sweep_outlined),
          onPressed: hasItems ? () => _clear(context) : null,
          child: Text(context.tr('Remove all estimates')),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_outline),
          onPressed: () => confirmDeleteProject(context, project),
          child: Text(context.tr('Delete project')),
        ),
      ],
    );
  }
}

/// The project total on the brand panel, with how it splits.
class _BudgetHero extends StatelessWidget {
  const _BudgetHero({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final b = project.breakdown;
    final bid = project.costs.isContractorBid;
    final count = project.items.length;
    final markups = b.contingency + b.overhead + b.profit + b.vat;
    final google = context.watch<GoogleAccountController>();
    return InkPanel(
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final palette = AppPalette.of(context);
          Widget stat(String label, double value) => MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: palette.onInkMuted,
                  ),
                ),
                Text(
                  formatMoney(value),
                  style: tabular(
                    theme.textTheme.titleSmall?.copyWith(color: palette.onInk),
                  ),
                ),
              ],
            ),
          );
          final trades = [
            for (final (trade, _) in tradeSections)
              if ((b.materialsByTrade[trade] ?? 0) > 0)
                (
                  label: trade?.label ?? 'Other',
                  value: b.materialsByTrade[trade]!,
                  color: palette.category(trade).chart,
                ),
          ];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.tr(bid ? 'Total contract price' : 'Project budget')} · '
                      '${context.tr(count == 1 ? '1 item' : '{n} items', {'n': count})}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: palette.onInkMuted,
                      ),
                    ),
                    const SizedBox(height: Space.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatMoney(b.total),
                        style: tabular(
                          theme.textTheme.displaySmall?.copyWith(
                            color: palette.inkAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.lg),
              Wrap(
                spacing: Space.xl,
                runSpacing: Space.md,
                children: [
                  stat('Materials', b.materials),
                  stat('Labour and tools', b.labour + b.tools + b.hauling),
                  stat(bid ? 'Markups and VAT' : 'Contingency', markups),
                ],
              ),
              if (trades.length > 1) ...[
                const SizedBox(height: Space.xl),
                Semantics(
                  label: context.tr('Materials by trade'),
                  child: ProportionBar(format: formatMoney, parts: trades),
                ),
              ],
              const SizedBox(height: Space.xl),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: [
                  FilledButton.icon(
                    onPressed: () => downloadProjectPdf(context, project),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(context.tr('Download PDF')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => downloadProjectCsv(context, project),
                    icon: const Icon(Icons.grid_on_outlined),
                    label: Text(context.tr('Excel')),
                  ),
                  if (google.isConfigured)
                    OutlinedButton.icon(
                      onPressed: google.isBusy
                          ? null
                          : () => saveProjectToSheets(context, project),
                      icon: google.isBusy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.table_chart_outlined),
                      label: Text(
                        project.sheetId == null
                            ? 'Google Sheets'
                            : 'Update Google Sheet',
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The estimates by trade, as in a bill of quantities.
class _ItemsTab extends StatelessWidget {
  const _ItemsTab({required this.project, this.grid = false});

  final Project project;

  /// Shows the dense table used on wide screens.
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final add = OutlinedButton.icon(
      onPressed: () => showMaterialPicker(context, projectId: project.id),
      icon: const Icon(Icons.add),
      label: Text(context.tr('Add an estimate')),
    );
    if (grid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BoqGrid(project: project),
          const SizedBox(height: Space.lg),
          Align(alignment: Alignment.centerLeft, child: add),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in groupByTrade(project.items)) ...[
          SectionHeader(
            '${g.letter}. ${tradeLabel(g.trade)}',
            trailing: Text(
              formatMoney(
                g.items.fold<double>(0, (sum, e) => sum + e.grandTotal),
              ),
              style: tabular(theme.textTheme.titleSmall),
            ),
            padding: const EdgeInsets.fromLTRB(0, Space.md, 0, Space.sm),
          ),
          for (final (i, e) in g.items.indexed) ...[
            if (i > 0) const SizedBox(height: Space.sm),
            EstimateTile(
              estimate: e,
              onTap: () => showItemDetails(context, project, e),
              trailing: ItemMenu(
                project: project,
                estimate: e,
                first: i == 0,
                last: i == g.items.length - 1,
              ),
            ),
          ],
          const SizedBox(height: Space.md),
        ],
        const SizedBox(height: Space.sm),
        add,
      ],
    );
  }
}

/// Everything to buy, merged across estimates and grouped like a
/// hardware's price list.
class _MaterialsTab extends StatelessWidget {
  const _MaterialsTab({required this.project});

  final Project project;

  Future<void> _setPrice(BuildContext context, MaterialLine line) async {
    final item = itemByKey(line.key);
    final book = context.read<PriceBookController>();
    final quoted = await showQuoteDialog(
      context,
      title: line.label,
      unit: item?.unit ?? line.unit,
      initial: line.unitPrice,
      suggested: item == null
          ? 'Updates this project'
          : 'Updates this project and your price book',
      quote: item == null ? null : book.quoteOf(item.key),
    );
    if (quoted == null || !context.mounted) return;
    context.read<ProjectsController>().setPrice(
      project.id,
      line.key,
      quoted.price,
    );
    if (item != null) {
      book.setPrice(
        item.key,
        quoted.price,
        supplier: quoted.supplier,
        quotedOn: quoted.date,
      );
    }
  }

  Future<void> _copy(BuildContext context, List<MaterialLine> lines) async {
    final text = StringBuffer('${project.name}: materials to buy\n');
    ItemGroup? group;
    for (final l in lines) {
      if (l.group != group) {
        group = l.group;
        text.writeln('\n${group.label}');
      }
      text.writeln('• ${l.label}: ${formatNumber(l.quantity)} ${l.unit}');
    }
    await Clipboard.setData(ClipboardData(text: text.toString()));
    if (context.mounted) {
      showMessage(context, context.tr('Copied the shopping list.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lines = project.materials;
    final groups = <ItemGroup, List<MaterialLine>>{};
    for (final l in lines) {
      groups.putIfAbsent(l.group, () => []).add(l);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr(
                  'Every material merged across the estimates. Tap a line to '
                  'change its price.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: Space.sm),
            TextButton.icon(
              onPressed: () => _copy(context, lines),
              icon: const Icon(Icons.content_copy_outlined, size: 18),
              label: Text(context.tr('Copy list')),
            ),
          ],
        ),
        for (final MapEntry(key: group, value: members) in groups.entries) ...[
          SectionHeader(
            group.label,
            trailing: Text(
              formatMoney(members.fold<double>(0, (s, l) => s + l.amount)),
              style: tabular(theme.textTheme.titleSmall),
            ),
            padding: const EdgeInsets.fromLTRB(0, Space.lg, 0, Space.sm),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, l) in members.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: Space.lg),
                  Semantics(
                    button: true,
                    hint: context.tr('Change price'),
                    child: InkWell(
                      onTap: () => _setPrice(context, l),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.lg,
                          vertical: Space.md,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.label,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    l.amount <= 0
                                        ? '${formatNumber(l.quantity)} '
                                              '${l.unit} · no price yet'
                                        : '${formatNumber(l.quantity)} '
                                              '${l.unit} × '
                                              '${formatMoney(l.unitPrice)}',
                                    style: tabular(
                                      theme.textTheme.bodySmall?.copyWith(
                                        color: l.amount <= 0
                                            ? scheme.error
                                            : scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: Space.md),
                            Text(
                              l.amount <= 0
                                  ? 'Set price'
                                  : formatMoney(l.amount),
                              style: l.amount <= 0
                                  ? theme.textTheme.labelLarge?.copyWith(
                                      color: scheme.primary,
                                    )
                                  : tabular(
                                      theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: Space.lg),
        KeyValueLine(
          'Materials total',
          formatMoney(project.breakdown.materials),
          emphasize: true,
        ),
      ],
    );
  }
}

enum _Preset { owner, contractor, dpwh, custom }

/// Labour, markups and taxes on top of the materials, with presets for an
/// owner's budget, a private contractor's bid and a DPWH estimate.
class _BudgetEditor extends StatelessWidget {
  const _BudgetEditor({super.key, required this.project});

  final Project project;

  _Preset _presetOf(CostSettings c, double direct) {
    if (c == CostSettings.owner.keepingJobCosts(c)) return _Preset.owner;
    if (c == CostSettings.contractor.keepingJobCosts(c)) {
      return _Preset.contractor;
    }
    if (c == CostSettings.dpwh(direct, from: c)) return _Preset.dpwh;
    return _Preset.custom;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = project.costs;
    final b = project.breakdown;
    final controller = context.read<ProjectsController>();
    void update(CostSettings costs) =>
        controller.updateCosts(project.id, costs);
    final preset = _presetOf(c, b.materials + b.labour + b.hauling);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      context.tr('Budget'),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showGlossary(context),
                  icon: Icon(Icons.help_outline, size: 18),
                  label: Text(context.tr('What these mean')),
                ),
              ],
            ),
            SizedBox(height: Space.md),
            SegmentedButton<_Preset>(
              showSelectedIcon: false,
              emptySelectionAllowed: true,
              segments: [
                ButtonSegment(
                  value: _Preset.owner,
                  label: Text(context.tr('Owner')),
                ),
                ButtonSegment(
                  value: _Preset.contractor,
                  label: Text(context.tr('Contractor')),
                ),
                ButtonSegment(
                  value: _Preset.dpwh,
                  label: Text(context.tr('DPWH')),
                ),
              ],
              selected: {if (preset != _Preset.custom) preset},
              onSelectionChanged: (s) {
                if (s.isEmpty) return;
                switch (s.first) {
                  case _Preset.owner:
                    update(CostSettings.owner.keepingJobCosts(c));
                  case _Preset.contractor:
                    update(CostSettings.contractor.keepingJobCosts(c));
                  case _Preset.dpwh:
                    // Tools change the direct cost; size the bracket on
                    // materials, labour and hauling.
                    update(
                      CostSettings.dpwh(
                        b.materials + b.labour + b.hauling,
                        from: c,
                      ),
                    );
                  case _Preset.custom:
                    break;
                }
              },
            ),
            const SizedBox(height: Space.sm),
            Text(
              switch (preset) {
                _Preset.owner =>
                  'For an owner hiring workers directly: labour and a '
                      'contingency, no contractor markups.',
                _Preset.contractor =>
                  'A private contractor\'s quotation: minor tools, overhead, '
                      'profit and 12% VAT.',
                _Preset.dpwh =>
                  'DPWH practice (DO 197 s.2016): OCM and profit by project '
                      'size, 10% minor tools and 5% VAT.',
                _Preset.custom => 'Your own percentages.',
              },
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.lg),
            Text(context.tr('Labour'), style: theme.textTheme.labelLarge),
            const SizedBox(height: Space.sm),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<LabourMethod>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: LabourMethod.crews,
                    label: Text(context.tr('By crew output')),
                  ),
                  ButtonSegment(
                    value: LabourMethod.percent,
                    label: Text(context.tr('% of materials')),
                  ),
                ],
                selected: {c.labourMethod},
                onSelectionChanged: (s) =>
                    update(c.copyWith(labourMethod: s.first)),
              ),
            ),
            const SizedBox(height: Space.sm),
            Text(
              context.tr(
                c.labourMethod == LabourMethod.crews
                    ? 'Crew-days for each work item from usual daily outputs, '
                          'at the daily rates below. Each item\'s unit price '
                          'analysis shows the crew.'
                    : 'A planning rule of thumb, about 30–45% of materials '
                          'for houses. Use your own quotes when you have '
                          'them.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.md),
            if (c.labourMethod == LabourMethod.crews)
              _FieldPair(
                left: _NumberSetting(
                  label: context.tr('Crew productivity'),
                  suffix: '%',
                  value: c.productivityPct,
                  max: 300,
                  onChanged: (v) => update(
                    c.copyWith(productivityPct: v == null || v <= 0 ? 100 : v),
                  ),
                ),
                right: _NumberSetting(
                  label: context.tr('Minor tools'),
                  suffix: '% of labour',
                  value: c.toolsPct,
                  onChanged: (v) => update(c.copyWith(toolsPct: v)),
                ),
              )
            else
              _FieldPair(
                left: _NumberSetting(
                  label: context.tr('Labour'),
                  suffix: '% of materials',
                  value: c.labourPct,
                  onChanged: (v) => update(c.copyWith(labourPct: v)),
                ),
                right: _NumberSetting(
                  label: context.tr('Minor tools'),
                  suffix: '% of labour',
                  value: c.toolsPct,
                  onChanged: (v) => update(c.copyWith(toolsPct: v)),
                ),
              ),
            if (c.labourMethod == LabourMethod.crews)
              _Expander(
                title: context.tr('Daily rates'),
                subtitle: context.tr(
                  'Skilled {skilled}, helper {helper} a day',
                  {
                    'skilled': formatMoney(
                      c.dailyRates[DailyRates.skilled] ?? 0,
                    ),
                    'helper': formatMoney(c.dailyRates[DailyRates.helper] ?? 0),
                  },
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => pickLabourRegion(context, project),
                      icon: const Icon(Icons.place_outlined, size: 18),
                      label: Text(context.tr('Rates for region')),
                    ),
                  ),
                  for (final key in DailyRates.defaults.keys) ...[
                    _NumberSetting(
                      label: context.tr(DailyRates.labels[key]!),
                      prefix: '₱ ',
                      suffix: context.tr('a day'),
                      value: c.dailyRates[key],
                      max: 100000,
                      clearable: true,
                      onChanged: (v) {
                        if (v == null) return;
                        final rates = {...c.rates};
                        if (v == DailyRates.defaults[key]) {
                          rates.remove(key);
                        } else {
                          rates[key] = v;
                        }
                        update(c.copyWith(rates: rates));
                      },
                    ),
                    const SizedBox(height: Space.md),
                  ],
                  Text(
                    context.tr(
                      'Suggested rates are Metro Manila market rates for '
                      '2026, with meals and benefits. Enter what you pay.',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (c.rates.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => update(c.copyWith(rates: const {})),
                        child: Text(context.tr('Use the suggested rates')),
                      ),
                    ),
                ],
              )
            else
              _Expander(
                title: context.tr('Labour by trade'),
                subtitle: context.tr('Leave empty to use {pct}%', {
                  'pct': formatNumber(c.labourPct),
                }),
                children: [
                  for (final trade in MaterialCategory.values) ...[
                    _NumberSetting(
                      label: context.tr('{trade} labour', {
                        'trade': context.tr(trade.label),
                      }),
                      suffix: '% of materials',
                      value: c.labourByTrade[trade.name],
                      onChanged: (v) {
                        final map = {...c.labourByTrade};
                        if (v == null) {
                          map.remove(trade.name);
                        } else {
                          map[trade.name] = v;
                        }
                        update(c.copyWith(labourByTrade: map));
                      },
                      clearable: true,
                    ),
                    const SizedBox(height: Space.md),
                  ],
                ],
              ),
            const SizedBox(height: Space.sm),
            _FieldPair(
              left: _NumberSetting(
                label: context.tr('Hauling and delivery'),
                prefix: '₱ ',
                value: c.hauling,
                max: 100000000,
                onChanged: (v) => update(c.copyWith(hauling: v)),
              ),
              right: _NumberSetting(
                label: context.tr('Contingency'),
                suffix: '%',
                value: c.contingencyPct,
                onChanged: (v) => update(c.copyWith(contingencyPct: v)),
              ),
            ),
            _Expander(
              title: context.tr('General requirements'),
              subtitle: b.general > 0
                  ? formatMoney(b.general)
                  : context.tr('Mobilization, temporary facilities, permits…'),
              children: [
                for (final MapEntry(:key, :value)
                    in generalRequirements.entries) ...[
                  _NumberSetting(
                    label: context.tr(value),
                    prefix: '₱ ',
                    value: c.general[key],
                    max: 100000000,
                    clearable: true,
                    onChanged: (v) {
                      final general = {...c.general};
                      if (v == null || v == 0) {
                        general.remove(key);
                      } else {
                        general[key] = v;
                      }
                      update(c.copyWith(general: general));
                    },
                  ),
                  const SizedBox(height: Space.md),
                ],
                Text(
                  b.months > 0
                      ? context.tr('Per month, for {months} months', {
                          'months': formatNumber(b.months),
                        })
                      : context.tr('Per month'),
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: Space.xs),
                Text(
                  context.tr(
                    'These run as long as the job does: the schedule in the '
                    'Contract tab sets the months, so more crews cost less here.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Space.md),
                for (final MapEntry(:key, :value)
                    in timeRelatedRequirements.entries) ...[
                  _NumberSetting(
                    label: context.tr(value),
                    prefix: '₱ ',
                    suffix: context.tr('a month'),
                    value: c.monthly[key],
                    max: 10000000,
                    clearable: true,
                    onChanged: (v) {
                      final monthly = {...c.monthly};
                      if (v == null || v == 0) {
                        monthly.remove(key);
                      } else {
                        monthly[key] = v;
                      }
                      update(c.copyWith(monthly: monthly));
                    },
                  ),
                  const SizedBox(height: Space.md),
                ],
                Wrap(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        final work =
                            b.materials + b.labour + b.tools + b.equipment;
                        update(
                          c.copyWith(
                            general: suggestGeneralRequirements(work),
                            monthly: suggestMonthlyRequirements(work),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_fix_high, size: 18),
                      label: Text(context.tr('Suggest amounts')),
                    ),
                    TextButton.icon(
                      onPressed: () => showPermitFees(context, project),
                      icon: const Icon(Icons.approval_outlined, size: 18),
                      label: Text(context.tr('Work out permit fees')),
                    ),
                    TextButton.icon(
                      onPressed: () => showProfessionalFees(context, project),
                      icon: const Icon(Icons.architecture, size: 18),
                      label: Text(context.tr('Work out professional fees')),
                    ),
                  ],
                ),
                Text(
                  context.tr(
                    'Suggestions are about 4% of the direct cost once, plus '
                    'a share of an engineer, a watchman, utilities and '
                    'transport each month, as small builders usually spend '
                    'it. Professional fees are the owner\'s and left blank.',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.sm),
            _FieldPair(
              left: _NumberSetting(
                label: context.tr('Overhead (OCM)'),
                suffix: '%',
                value: c.overheadPct,
                onChanged: (v) => update(c.copyWith(overheadPct: v)),
              ),
              right: _NumberSetting(
                label: context.tr('Profit'),
                suffix: '%',
                value: c.profitPct,
                onChanged: (v) => update(c.copyWith(profitPct: v)),
              ),
            ),
            const SizedBox(height: Space.md),
            _FieldPair(
              left: _NumberSetting(
                label: context.tr('VAT'),
                suffix: '%',
                value: c.vatPct,
                onChanged: (v) => update(c.copyWith(vatPct: v)),
              ),
              right: _NumberSetting(
                label: context.tr('Price escalation'),
                suffix: '%',
                value: c.escalationPct,
                max: 100,
                onChanged: (v) => update(c.copyWith(escalationPct: v)),
              ),
            ),
            const SizedBox(height: Space.md),
            const Divider(),
            for (final (label, amount, strong: strong) in costLines(project))
              KeyValueLine(
                label,
                formatMoney(amount),
                emphasize: strong,
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
          ],
        ),
      ),
    );
  }
}

/// Budget terms in plain words.
const _glossary = [
  (
    'Labour',
    'What the workers cost: masons, carpenters, steelmen, electricians, '
        'plumbers and helpers. Here it is a share of the materials, a '
        'planning rule of thumb; use your crew\'s quote when you have it.',
  ),
  (
    'Minor tools',
    'Small tools and consumables used up on the job, such as trowels, '
        'saw blades and cutting discs, as a share of labour.',
  ),
  (
    'Hauling and delivery',
    'Trucking materials to the site and carting away debris.',
  ),
  ('Direct cost', 'Materials, labour, tools and hauling together.'),
  (
    'Contingency',
    'Money set aside for the unexpected: price increases, extra work and '
        'mistakes. 5–10% is usual for a house.',
  ),
  (
    'Overhead (OCM)',
    'A contractor\'s overhead, contingencies and miscellaneous costs: '
        'office, permits, insurance, bonds, supervision and the like.',
  ),
  ('Profit', 'What the contractor earns on the job.'),
  (
    'VAT',
    'Value-added tax. VAT-registered contractors charge 12% on their '
        'price; DPWH estimates use 5%.',
  ),
  (
    'DPWH',
    'The Department of Public Works and Highways. Its estimates follow '
        'Department Order 197 (2016), which sets overhead and profit by '
        'project size.',
  ),
];

void _showGlossary(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(Space.xl, Space.sm, Space.xl, Space.xl),
    child: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                context.tr('Budget terms'),
                style: theme.textTheme.titleLarge,
              ),
            ),
            for (final (term, meaning) in _glossary) ...[
              const SizedBox(height: Space.lg),
              Text(context.tr(term), style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(context.tr(meaning), style: theme.textTheme.bodyMedium),
            ],
          ],
        );
      },
    ),
  ),
);

/// A collapsible group of settings with a summary.
class _Expander extends StatelessWidget {
  const _Expander({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: Space.md),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        children: children,
      ),
    );
  }
}

class _FieldPair extends StatelessWidget {
  const _FieldPair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      const SizedBox(width: Space.md),
      Expanded(child: right),
    ],
  );
}

/// A number setting that saves as the user types.
class _NumberSetting extends StatefulWidget {
  const _NumberSetting({
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.prefix,
    this.max = 1000,
    this.clearable = false,
  });

  final String label;
  final double? value;
  final String? suffix;
  final String? prefix;
  final double max;

  /// Whether an empty field means "not set" (null) rather than 0.
  final bool clearable;
  final ValueChanged<double?> onChanged;

  @override
  State<_NumberSetting> createState() => _NumberSettingState();
}

class _NumberSettingState extends State<_NumberSetting> {
  late final _controller = TextEditingController(text: _text(widget.value));
  String? _error;

  static String _text(double? v) => v == null
      ? ''
      : v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toString();

  @override
  void didUpdateWidget(_NumberSetting old) {
    super.didUpdateWidget(old);
    final typed = double.tryParse(_controller.text.trim());
    final shown = _controller.text.trim().isEmpty && !widget.clearable
        ? 0.0
        : typed;
    if (shown != widget.value) _controller.text = _text(widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      setState(() => _error = null);
      widget.onChanged(widget.clearable ? null : 0);
      return;
    }
    final v = double.tryParse(text);
    if (v == null || v < 0 || v > widget.max) {
      setState(() => _error = 'Enter 0 to ${formatNumber(widget.max)}');
      return;
    }
    setState(() => _error = null);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      const DecimalInputFormatter(),
      LengthLimitingTextInputFormatter(12),
    ],
    style: tabular(Theme.of(context).textTheme.bodyLarge),
    decoration: InputDecoration(
      labelText: widget.label,
      suffixText: widget.suffix,
      prefixText: widget.prefix,
      errorText: _error,
      isDense: true,
    ),
    onChanged: _changed,
  );
}
