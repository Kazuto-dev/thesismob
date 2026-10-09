import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/layout.dart';
import '../../core/widgets.dart';
import '../../data/sheets_export_service.dart';
import '../../router.dart';
import '../../state/sheet_settings_controller.dart';

/// Where to send estimates in Google Sheets.
class SheetScreen extends StatefulWidget {
  const SheetScreen({super.key});

  @override
  State<SheetScreen> createState() => _SheetScreenState();
}

class _SheetScreenState extends State<SheetScreen> {
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
    final controller = context.watch<SheetSettingsController>();
    final settings = controller.settings;
    return PageTitle(
      title: 'Google Sheet',
      child: Scaffold(
        appBar: AppBar(title: const Text('Google Sheet')),
        body: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 32),
          children: [
            ContentWidth(
              maxWidth: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/brand/sheet.png',
                        width: 56,
                        excludeFromSemantics: true,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Send your estimates to a Google Sheet you own, to '
                          'keep a record or share it.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                  if (!controller.isExportAvailable) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: theme.colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Sending to Google Sheets isn't set up for this "
                                'build of the app. You can still save your '
                                'sheet details for later.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SectionHeader('1. Share your sheet with the app'),
                  Text(
                    'In Google Sheets, open Share and add this email address '
                    'as an Editor:',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      title: SelectableText(
                        SheetsExportService.serviceAccountEmail,
                        style: theme.textTheme.bodyLarge,
                      ),
                      trailing: IconButton(
                        tooltip: 'Copy email address',
                        icon: const Icon(Icons.copy),
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
                    ),
                  ),
                  const SectionHeader('2. Tell the app where to write'),
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
                                'Paste the address of the sheet from your '
                                'browser, or just the ID inside it.',
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              SheetsExportService.normalizeSpreadsheetId(
                                    value ?? '',
                                  ) ==
                                  null
                              ? 'That does not look like a spreadsheet link or ID.'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _tab,
                          decoration: const InputDecoration(
                            labelText: 'Sheet tab name',
                            helperText:
                                'The tab at the bottom of the spreadsheet, for '
                                'example Sheet1.',
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _save(),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Enter the name of the tab.'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _save,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ),
                  if (settings != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: theme.colorScheme.surfaceContainerLow,
                      child: ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text('Sending to "${settings.sheetName}"'),
                        subtitle: Text(
                          'Spreadsheet …${settings.spreadsheetId.substring(settings.spreadsheetId.length - 6)}',
                        ),
                        trailing: TextButton(
                          onPressed: _remove,
                          child: const Text('Remove'),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.go(Routes.help),
                      icon: const Icon(Icons.help_outline),
                      label: const Text('Step-by-step guide with pictures'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
