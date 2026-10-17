import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/i18n.dart';
import '../../core/format.dart';
import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/account.dart';
import '../../data/api_client.dart';
import '../../export/files.dart';
import '../../export/project_documents.dart';
import '../../router.dart';
import '../../state/account_controller.dart';
import '../../state/appearance_controller.dart';
import '../../state/estimates_controller.dart';
import '../../state/google_account_controller.dart';
import '../../state/install_controller.dart';
import '../../state/price_book_controller.dart';
import '../../state/profile_controller.dart';
import '../../state/projects_controller.dart';
import '../common/google_button.dart';
import '../common/plan_lock.dart';
import '../shell/install_offer.dart';
import 'plan_section.dart';

/// The plan, business profile, backups, Google Sheets, appearance and help.
/// Prices have their own tab.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageTitle(
      title: context.tr('Settings'),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomClearance(context)),
            child: ContentWidth(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(
                    title: context.tr('Settings'),
                    subtitle: context.tr(
                      'Your plan, backups, Google Sheets and help',
                    ),
                  ),
                  _PlanSlot(),
                  _InstallSlot(),
                  _ProfileSection(),
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

/// The plan card with the space after it, or nothing when the app has no
/// server.
class _PlanSlot extends StatelessWidget {
  const _PlanSlot();

  @override
  Widget build(BuildContext context) =>
      context.watch<AccountController>().isConfigured
      ? const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlanSection(),
            SizedBox(height: Space.lg),
            _CompanySection(),
            SizedBox(height: Space.lg),
          ],
        )
      : const SizedBox.shrink();
}

/// The user's company on Enterprise: its members and their roles. On
/// other plans it is locked and says what Enterprise adds.
class _CompanySection extends StatelessWidget {
  const _CompanySection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = watchPlanLocked(context, AppPlan.enterprise);
    final status = context.watch<AccountController>().status;
    return _Section(
      icon: Icons.groups_outlined,
      title: context.tr('Company'),
      children: [
        Text(
          locked
              ? context.tr(
                  'Shared projects, one company price book and roles for '
                  'your team come with Enterprise.',
                )
              : context.tr('{org}, as {role}.', {
                  'org': status?.organization ?? '',
                  'role': context.tr(status?.orgRole ?? 'member'),
                }),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Space.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () {
              if (unlockOrAsk(context, AppPlan.enterprise, 'Team members')) {
                showDialog<void>(
                  context: context,
                  builder: (_) => const _MembersDialog(),
                );
              }
            },
            icon: locked
                ? const PlanLockIcon(AppPlan.enterprise)
                : const Icon(Icons.badge_outlined),
            label: Text(context.tr('Team members')),
          ),
        ),
      ],
    );
  }
}

/// The company's members and invitations, with their roles.
class _MembersDialog extends StatefulWidget {
  const _MembersDialog();

  @override
  State<_MembersDialog> createState() => _MembersDialogState();
}

class _MembersDialogState extends State<_MembersDialog> {
  late final _company = context.read<AccountController>().company();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(context.tr('Team members')),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: FutureBuilder(
          future: _company,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final e = snapshot.error;
              return Text(
                e is ApiException
                    ? e.message
                    : context.tr("Couldn't load the team."),
              );
            }
            final company = snapshot.data;
            if (company == null) {
              return const Center(child: CircularProgressIndicator());
            }
            String text(Object? v) => v is String ? v : '';
            final people = <(String, String, String)>[
              for (final m in company['members'] as List? ?? const [])
                if (m is Map)
                  (text(m['name']), text(m['email']), text(m['role'])),
              for (final i in company['invitations'] as List? ?? const [])
                if (i is Map) ('', text(i['email']), text(i['role'])),
            ];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('{n} of {seats} seats used', {
                    'n': people.length,
                    'seats': company['seats'] is int
                        ? company['seats'] as int
                        : people.length,
                  }),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                for (final (name, email, role) in people)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(name.isEmpty ? email : name),
                    subtitle: name.isEmpty ? null : Text(email),
                    trailing: Text(context.tr(role.isEmpty ? 'member' : role)),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Close')),
        ),
      ],
    );
  }
}

/// Installing the app on the home screen, on phones and tablets that have
/// not yet, with the space after it.
class _InstallSlot extends StatelessWidget {
  const _InstallSlot();

  @override
  Widget build(BuildContext context) {
    final install = context.watch<InstallController>();
    if (!install.isAvailable) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          icon: Icons.install_mobile,
          title: context.tr('Install the app'),
          children: [
            Text(
              context.tr(
                'Put BuildQuantify on your home screen so it opens like an '
                'app, without the browser, and works offline.',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => showInstallSheet(context),
                icon: const Icon(Icons.add_to_home_screen),
                label: Text(
                  context.tr(install.canInstall ? 'Install' : 'How to install'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.lg),
      ],
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

/// The business details printed on quotations and billings.
class _ProfileSection extends StatelessWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.watch<ProfileController>().profile;
    return _Section(
      icon: Icons.storefront_outlined,
      title: context.tr('Business profile'),
      children: [
        Text(
          p.isEmpty
              ? context.tr(
                  'Your business name and contact details, printed on '
                  'quotations and progress billings.',
                )
              : [
                  p.name,
                  p.address,
                  p.phone,
                  p.email,
                ].where((t) => t.isNotEmpty).join(' · '),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Space.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () => _edit(context, p),
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              context.tr(p.isEmpty ? 'Add your details' : 'Edit details'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, BusinessProfile p) async {
    final updated = await showDialog<BusinessProfile>(
      context: context,
      builder: (_) => _ProfileDialog(profile: p),
    );
    if (updated != null && context.mounted) {
      context.read<ProfileController>().update(updated);
    }
  }
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({required this.profile});

  final BusinessProfile profile;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  static const _labels = {
    'name': 'Business or contractor name',
    'address': 'Address',
    'phone': 'Phone',
    'email': 'Email',
    'tin': 'TIN',
    'preparedBy': 'Prepared by (name and position)',
  };

  late final _fields = {
    'name': TextEditingController(text: widget.profile.name),
    'address': TextEditingController(text: widget.profile.address),
    'phone': TextEditingController(text: widget.profile.phone),
    'email': TextEditingController(text: widget.profile.email),
    'tin': TextEditingController(text: widget.profile.tin),
    'preparedBy': TextEditingController(text: widget.profile.preparedBy),
  };

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    String v(String k) => _fields[k]!.text.trim();
    Navigator.of(context).pop(
      BusinessProfile(
        name: v('name'),
        address: v('address'),
        phone: v('phone'),
        email: v('email'),
        tin: v('tin'),
        preparedBy: v('preparedBy'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('Business profile')),
    scrollable: true,
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final MapEntry(:key, :value) in _fields.entries) ...[
            TextField(
              controller: value,
              textCapitalization: key == 'email'
                  ? TextCapitalization.none
                  : TextCapitalization.words,
              keyboardType: key == 'email'
                  ? TextInputType.emailAddress
                  : key == 'phone'
                  ? TextInputType.phone
                  : TextInputType.text,
              decoration: InputDecoration(labelText: context.tr(_labels[key]!)),
            ),
            const SizedBox(height: Space.md),
          ],
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
      title: context.tr('Google Sheets'),
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
          context.tr(
            'Sign in with Google to save projects as spreadsheets in your own '
            'Google Drive: the bill of quantities, the materials to buy and the '
            'budget, each on its own tab.',
          ),
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
                              showMessage(
                                context,
                                context.tr('Signed out of Google.'),
                              );
                            }
                          },
                    child: Text(context.tr('Sign out')),
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

class _BackupSection extends StatelessWidget {
  const _BackupSection();

  Future<void> _download(BuildContext context) async {
    final projects = context.read<ProjectsController>().projects;
    final text = backupJson(
      projects: projects,
      prices: context.read<PriceBookController>().custom,
      quotes: context.read<PriceBookController>().quotes,
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

  String _json(BuildContext context) => backupJson(
    projects: context.read<ProjectsController>().projects,
    prices: context.read<PriceBookController>().custom,
    quotes: context.read<PriceBookController>().quotes,
    history: context.read<EstimatesController>().history,
  );

  Future<void> _backUpToDrive(BuildContext context) async {
    // Straight from the tap, so Google's window may open.
    final result = await context.read<GoogleAccountController>().backUp(
      _json(context),
    );
    if (context.mounted) showMessage(context, result.message);
  }

  Future<void> _restoreFromDrive(BuildContext context) async {
    final backup = await context.read<GoogleAccountController>().fetchBackup();
    if (!context.mounted) return;
    final content = backup.content;
    if (content == null) {
      showMessage(context, backup.result.message);
      return;
    }
    await _restoreText(context, content);
  }

  Future<void> _restore(BuildContext context) async {
    final text = await pickTextFile(accept: '.json,application/json');
    if (text == null || !context.mounted) return;
    await _restoreText(context, text);
  }

  Future<void> _restoreText(BuildContext context, String text) async {
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
        title: Text(context.tr('Restore this backup?')),
        content: Text(
          'It has ${backup.projects.length} projects, '
          '${backup.prices.length} prices and ${backup.history.length} '
          'history entries. Projects you already have are kept; your prices '
          'are replaced by the backup\'s where both have one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.tr('Restore')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final added = context.read<ProjectsController>().import(backup.projects);
    final book = context.read<PriceBookController>();
    book.restore(
      {...book.custom, ...backup.prices},
      quotes: {
        for (final MapEntry(:key, :value) in book.quotes.entries)
          if (!backup.prices.containsKey(key)) key: value,
        ...backup.quotes,
      },
    );
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
    final google = context.watch<GoogleAccountController>();
    return _Section(
      icon: Icons.backup_outlined,
      title: context.tr('Backup and restore'),
      children: [
        Text(
          context.tr(
            'Your projects, prices and history are saved in this browser only. '
            'Download a backup to keep them safe or to move them to another '
            'device.',
          ),
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
              label: Text(context.tr('Download backup')),
            ),
            OutlinedButton.icon(
              onPressed: () => _restore(context),
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(context.tr('Restore from file')),
            ),
          ],
        ),
        if (google.isConfigured) ...[
          const SizedBox(height: Space.xl),
          Text(context.tr('Google Drive'), style: theme.textTheme.titleSmall),
          const SizedBox(height: Space.xs),
          Text(
            !google.isSignedIn
                ? 'Sign in with Google above to keep a backup in your own '
                      'Google Drive.'
                : google.lastBackup == null
                ? 'Keep a backup in your Google Drive, as '
                      '"BuildQuantify backup.json", to restore on any device.'
                : 'Last backed up ${formatDateTime(google.lastBackup!.toLocal())}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (google.isSignedIn) ...[
            const SizedBox(height: Space.md),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                FilledButton.tonalIcon(
                  onPressed: google.isBusy
                      ? null
                      : () => _backUpToDrive(context),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(context.tr('Back up to Drive')),
                ),
                OutlinedButton.icon(
                  onPressed: google.isBusy
                      ? null
                      : () => _restoreFromDrive(context),
                  icon: Icon(Icons.cloud_download_outlined),
                  label: Text(context.tr('Restore from Drive')),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: google.autoBackup,
              onChanged: google.setAutoBackup,
              title: Text(context.tr('Back up automatically')),
              subtitle: Text(
                context.tr(
                  'Saves changes to Drive within a minute, for an hour after '
                  'each sign-in or backup',
                ),
              ),
            ),
          ],
        ],
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
      title: context.tr('Appearance and units'),
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text(context.tr('System')),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text(context.tr('Light')),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text(context.tr('Dark')),
              ),
            ],
            selected: {appearance.mode},
            onSelectionChanged: (s) => appearance.setMode(s.first),
          ),
        ),
        const SizedBox(height: Space.lg),
        Text(
          context.tr('Language'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: Space.sm),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<AppLanguage>(
            showSelectedIcon: false,
            segments: [
              for (final l in AppLanguage.values)
                ButtonSegment(value: l, label: Text(l.label)),
            ],
            selected: {appearance.language},
            onSelectionChanged: (s) => appearance.setLanguage(s.first),
          ),
        ),
        const SizedBox(height: Space.sm),
        Text(
          context.tr(
            'Help, definitions and documents stay in English, the language '
            'of plans and specifications.',
          ),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: Space.lg),
        Text(
          context.tr('Measure lengths in'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(height: Space.sm),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<LengthUnit>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: LengthUnit.metres,
                label: Text(context.tr('Metres')),
              ),
              ButtonSegment(
                value: LengthUnit.feet,
                label: Text(context.tr('Feet')),
              ),
            ],
            selected: {appearance.lengthUnit},
            onSelectionChanged: (s) => appearance.setLengthUnit(s.first),
          ),
        ),
        const SizedBox(height: Space.sm),
        Text(
          context.tr(
            'Calculators take lengths in feet when you choose feet. Results, '
            'documents and prices stay metric, as suppliers sell them.',
          ),
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
      title: context.tr('Help and about'),
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
          context.tr(
            'BuildQuantify, developed by ARCONSTRUKT. Quantities follow '
            'common Philippine practice and are planning estimates; confirm '
            'with your supplier and engineer before buying.',
          ),
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}
