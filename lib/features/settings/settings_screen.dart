import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../export/files.dart';
import '../../export/project_documents.dart';
import '../../router.dart';
import '../../state/appearance_controller.dart';
import '../../state/estimates_controller.dart';
import '../../state/google_account_controller.dart';
import '../../state/price_book_controller.dart';
import '../../state/projects_controller.dart';
import '../common/google_button.dart';

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
                    subtitle: 'Prices, backups, Google Sheets and help',
                  ),
                  _PricesSection(),
                  SizedBox(height: Space.lg),
                  _BackupSection(),
                  SizedBox(height: Space.lg),
                  _GoogleSection(),
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

class _GoogleSection extends StatelessWidget {
  const _GoogleSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final google = context.watch<GoogleAccountController>();
    final account = google.account;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    Future<void> signIn() async {
      final result = await google.signIn();
      if (context.mounted) showMessage(context, result.message);
    }

    return _Section(
      icon: Icons.table_chart_outlined,
      title: 'Google Sheets',
      trailing: _StatusChip(
        label: !google.isConfigured
            ? 'Not set up'
            : account == null
            ? 'Signed out'
            : 'Signed in',
        color: account != null && google.isConfigured
            ? palette.success
            : scheme.onSurfaceVariant,
      ),
      children: [
        Text(
          'Sign in with Google to save projects as spreadsheets in your own '
          'Google Drive: the bill of quantities, the materials to buy and the '
          'budget, each on its own tab.',
          style: muted,
        ),
        const SizedBox(height: Space.lg),
        if (!google.isConfigured)
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
                      "Google sign-in isn't set up for this build of the app. "
                      'You can still download projects as PDF or Excel.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (account == null)
          Align(
            alignment: Alignment.centerLeft,
            child: GoogleSignInButton(busy: google.isBusy, onPressed: signIn),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.lg,
                Space.md,
                Space.sm,
                Space.md,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Text(account.displayName.characters.first),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.displayName,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (account.name.isNotEmpty)
                          Text(
                            account.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: google.isBusy
                        ? null
                        : () async {
                            await google.signOut();
                            if (context.mounted) {
                              showMessage(context, 'Signed out of Google.');
                            }
                          },
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: Space.lg),
        Text(
          'To save, open a project and choose Google Sheets. Saving again '
          'updates the same spreadsheet. BuildQuantify can only open the '
          "spreadsheets it creates; it can't see your other files.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
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

class _PricesSection extends StatelessWidget {
  const _PricesSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = context.watch<PriceBookController>();
    final mine = book.custom.length;
    return _Section(
      icon: Icons.sell_outlined,
      title: 'Price book',
      children: [
        Text(
          'Suggested prices for ${book.region.label}. '
          '${mine == 0 ? 'You have not set any prices of your own.' : 'You set $mine ${mine == 1 ? 'price' : 'prices'} of your own.'}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Space.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () => context.go(Routes.prices),
            icon: const Icon(Icons.edit_note),
            label: const Text('Open price book'),
          ),
        ),
      ],
    );
  }
}

class _BackupSection extends StatelessWidget {
  const _BackupSection();

  Future<void> _download(BuildContext context) async {
    final projects = context.read<ProjectsController>().projects;
    final text = backupJson(
      projects: projects,
      prices: context.read<PriceBookController>().custom,
      history: context.read<EstimatesController>().history,
    );
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final saved = await saveFile(
      'buildquantify-backup-$date.json',
      Uint8List.fromList(utf8.encode(text)),
      'application/json',
    );
    if (!context.mounted) return;
    showMessage(
      context,
      saved
          ? 'Downloaded a backup of ${projects.length} '
                '${projects.length == 1 ? 'project' : 'projects'}.'
          : "Downloads aren't supported here.",
    );
  }

  Future<void> _restore(BuildContext context) async {
    final text = await pickTextFile(accept: '.json,application/json');
    if (text == null || !context.mounted) return;
    final Backup backup;
    try {
      backup = parseBackup(text);
    } on FormatException catch (e) {
      showMessage(context, e.message);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Text(
          'It has ${backup.projects.length} projects, '
          '${backup.prices.length} prices and ${backup.history.length} '
          'history entries. Projects you already have are kept; your prices '
          'are replaced by the backup\'s where both have one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final added = context.read<ProjectsController>().import(backup.projects);
    final book = context.read<PriceBookController>();
    book.restore({...book.custom, ...backup.prices});
    context.read<EstimatesController>().importHistory(backup.history);
    showMessage(
      context,
      'Restored ${formatCount(added, 'project')} and '
      '${formatCount(backup.prices.length, 'price')}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Section(
      icon: Icons.backup_outlined,
      title: 'Backup and restore',
      children: [
        Text(
          'Your projects, prices and history are saved in this browser only. '
          'Download a backup to keep them safe or to move them to another '
          'device.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Space.lg),
        Wrap(
          spacing: Space.sm,
          runSpacing: Space.sm,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => _download(context),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download backup'),
            ),
            OutlinedButton.icon(
              onPressed: () => _restore(context),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Restore from file'),
            ),
          ],
        ),
      ],
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
      title: 'Appearance and units',
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
        const SizedBox(height: Space.lg),
        Text(
          'Measure lengths in',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: Space.sm),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<LengthUnit>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: LengthUnit.metres, label: Text('Metres')),
              ButtonSegment(value: LengthUnit.feet, label: Text('Feet')),
            ],
            selected: {appearance.lengthUnit},
            onSelectionChanged: (s) => appearance.setLengthUnit(s.first),
          ),
        ),
        const SizedBox(height: Space.sm),
        Text(
          'Calculators take lengths in feet when you choose feet. Results, '
          'documents and prices stay metric, as suppliers sell them.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
