import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/sheets_export_service.dart';
import '../../router.dart';
import '../../state/appearance_controller.dart';
import '../../state/sheet_settings_controller.dart';

/// Google Sheets connection, appearance, help and app information.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageTitle(
      title: 'Settings',
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomClearance(context)),
            child: const ContentWidth(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    title: 'Settings',
                    subtitle: 'Google Sheets, appearance and help',
                  ),
                  _SheetsSection(),
                  SizedBox(height: Space.lg),
                  _AppearanceSection(),
                  SizedBox(height: Space.lg),
                  _AboutSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A titled settings card with an icon.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconTile(icon: icon, size: 40),
                const SizedBox(width: Space.md),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: Space.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SheetsSection extends StatefulWidget {
  const _SheetsSection();

  @override
  State<_SheetsSection> createState() => _SheetsSectionState();
}

class _SheetsSectionState extends State<_SheetsSection> {
  final _formKey = GlobalKey<FormState>();
  late final _spreadsheet = TextEditingController(
    text: context.read<SheetSettingsController>().settings?.spreadsheetId,
  );
  late final _tab = TextEditingController(
    text: context.read<SheetSettingsController>().settings?.sheetName,
  );

  @override
  void dispose() {
    _spreadsheet.dispose();
    _tab.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final controller = context.read<SheetSettingsController>();
    final error = controller.save(
      spreadsheet: _spreadsheet.text,
      sheetName: _tab.text,
    );
    if (error != null) {
      showMessage(context, error);
      return;
    }
    // Show the normalised ID if a full link was pasted.
    _spreadsheet.text = controller.settings!.spreadsheetId;
    showMessage(
      context,
      'Saved. Estimates will go to the "${controller.settings!.sheetName}" tab.',
    );
  }

  void _remove() {
    context.read<SheetSettingsController>().clear();
    _spreadsheet.clear();
    _tab.clear();
    showMessage(context, 'Sheet details removed.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final controller = context.watch<SheetSettingsController>();
    final settings = controller.settings;
    final connected = settings != null;

    Widget step(int number, String title) => Padding(
      padding: const EdgeInsets.only(top: Space.xl, bottom: Space.sm),
      child: Row(
        children: [
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 13,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                '$number',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Semantics(
              header: true,
              label: 'Step $number: $title',
              excludeSemantics: true,
              child: Text(title, style: theme.textTheme.titleSmall),
            ),
          ),
        ],
      ),
    );

    return _Section(
      icon: Icons.table_chart_outlined,
      title: 'Google Sheets',
      trailing: _StatusChip(
        label: connected ? 'Connected' : 'Not set up',
        color: connected ? palette.success : scheme.onSurfaceVariant,
      ),
      children: [
        Text(
          'Send your estimates to a Google Sheet you own, to keep a record '
          'or share it with your contractor.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (!controller.isExportAvailable) ...[
          const SizedBox(height: Space.lg),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: scheme.onPrimaryContainer),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      "Sending to Google Sheets isn't set up for this build of "
                      'the app. You can still save your sheet details for '
                      'later.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (settings != null) ...[
          const SizedBox(height: Space.lg),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.sm,
                Space.sm,
                Space.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: palette.success),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sending to "${settings.sheetName}"',
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          'Spreadsheet …${settings.spreadsheetId.substring(settings.spreadsheetId.length - 6)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(onPressed: _remove, child: const Text('Remove')),
                ],
              ),
            ),
          ),
        ],
        step(1, 'Share your sheet with the app'),
        Text(
          'In Google Sheets, open Share and add this address as an Editor:',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: Space.sm),
        const _EmailBox(),
        step(2, 'Tell the app where to write'),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _spreadsheet,
                decoration: const InputDecoration(
                  labelText: 'Spreadsheet link or ID',
                  helperText:
                      'Paste the address of the sheet from your browser, or '
                      'just the ID inside it.',
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    SheetsExportService.normalizeSpreadsheetId(value ?? '') ==
                        null
                    ? 'That does not look like a spreadsheet link or ID.'
                    : null,
              ),
              const SizedBox(height: Space.lg),
              TextFormField(
                controller: _tab,
                decoration: const InputDecoration(
                  labelText: 'Sheet tab name',
                  helperText:
                      'The tab at the bottom of the spreadsheet, for example '
                      'Sheet1.',
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter the name of the tab.'
                    : null,
              ),
              const SizedBox(height: Space.xl),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton(onPressed: _save, child: const Text('Save')),
                  TextButton.icon(
                    onPressed: () => context.go(Routes.help),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Guide with pictures'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// The service account's address, with a copy button.
class _EmailBox extends StatelessWidget {
  const _EmailBox();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.lg,
          Space.sm,
          Space.xs,
          Space.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: SelectableText(
                breakable(SheetsExportService.serviceAccountEmail),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Copy email address',
              icon: const Icon(Icons.content_copy_outlined),
              onPressed: () async {
                await Clipboard.setData(
                  const ClipboardData(
                    text: SheetsExportService.serviceAccountEmail,
                  ),
                );
                if (context.mounted) {
                  showMessage(context, 'Email address copied.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceController>();
    return _Section(
      icon: Icons.palette_outlined,
      title: 'Appearance',
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Dark'),
              ),
            ],
            selected: {appearance.mode},
            onSelectionChanged: (s) => appearance.setMode(s.first),
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    Widget link(IconData icon, String label, VoidCallback onTap) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.sm),
      leading: Icon(icon),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
    return _Section(
      icon: Icons.help_outline,
      title: 'Help and about',
      children: [
        link(
          Icons.school_outlined,
          'How to use BuildQuantify',
          () => context.go(Routes.help),
        ),
        link(
          Icons.gavel_outlined,
          'Open-source licenses',
          () => showLicensePage(
            context: context,
            applicationName: 'BuildQuantify',
          ),
        ),
        const SizedBox(height: Space.md),
        Text(
          'BuildQuantify, developed by ARCONSTRUKT. Quantities follow '
          'common Philippine practice and are planning estimates; confirm '
          'with your supplier and engineer before buying.',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}
