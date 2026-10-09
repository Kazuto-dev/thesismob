import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/layout.dart';
import '../../core/widgets.dart';
import '../../data/sheets_export_service.dart';
import '../../router.dart';

class _Step {
  const _Step(this.text, [this.image, this.imageLabel]);

  final String text;
  final String? image;
  final String? imageLabel;
}

const _estimateSteps = [
  _Step('Choose a category on the Estimate tab, then the material.'),
  _Step(
    'Enter the measurements in metres and the store price. Every field '
    'explains what is missing if a value is not valid.',
  ),
  _Step(
    'Select Calculate. You get the quantity to buy, the total cost and how it '
    'was worked out. "Definitions" and "How it\'s calculated" explain each '
    'input and formula.',
  ),
  _Step(
    'Choose "Add to summary" to build a bill of materials. The Summary tab '
    'adds up everything you added.',
  ),
];

const _sheetSteps = [
  _Step(
    'Open or create a spreadsheet in the Google Sheets app.',
    'assets/images/help/step_01.webp',
    'An empty spreadsheet open in the Google Sheets app.',
  ),
  _Step(
    'Tap the More menu (three dots) in the top-right corner.',
    'assets/images/help/step_02.webp',
    'The More menu button highlighted in the top-right corner.',
  ),
  _Step(
    'Choose "Share & export", then "Share".',
    'assets/images/help/step_03.webp',
    'The Share & export menu with Share highlighted.',
  ),
  _Step(
    'Tap the Add people icon.',
    'assets/images/help/step_04.webp',
    'The Manage access screen with the Add people icon highlighted.',
  ),
  _Step(
    "Type the app's email address (shown on the Sheet tab), keep it as "
        'Editor, and tap Send.',
    'assets/images/help/step_06.webp',
    'The Share screen with the email entered and the Send button highlighted.',
  ),
  _Step(
    "The app's account now appears under People with access as an Editor.",
    'assets/images/help/step_05.webp',
    'People with access listing the app account as Editor.',
  ),
  _Step(
    'Copy the link to the spreadsheet: More, "Share & export", "Copy link".',
    'assets/images/help/step_08.webp',
    'The Share & export menu with Copy link highlighted.',
  ),
  _Step(
    'Paste the link on the Sheet tab of BuildQuantify, or just the ID, which '
        'is the part between /d/ and /edit. Then enter the name of the tab and '
        'select Save.',
    'assets/images/help/step_09.webp',
    'A spreadsheet link with the ID part highlighted.',
  ),
];

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageTitle(
      title: 'Help',
      child: Scaffold(
        appBar: AppBar(title: const Text('Help')),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            ContentWidth(
              maxWidth: 760,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'BuildQuantify estimates how much of a construction '
                    'material you need and what it costs. It works offline; '
                    'you only need a connection to send estimates to Google '
                    'Sheets.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SectionHeader('Make an estimate'),
                  for (final (i, s) in _estimateSteps.indexed)
                    _StepTile(number: i + 1, step: s),
                  const SectionHeader('History and Summary'),
                  Text(
                    'History keeps your last 100 calculations. Open one to '
                    'change its inputs in the calculator. The Summary only '
                    'contains what you chose to add, and removing an item '
                    'can be undone.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SectionHeader('Your data'),
                  Text(
                    'Estimates and sheet details are saved in this browser '
                    'only. Clearing your browsing data removes them.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SectionHeader('Send estimates to Google Sheets'),
                  Text(
                    'Share your spreadsheet with this email address as an '
                    'Editor:',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      title: const SelectableText(
                        SheetsExportService.serviceAccountEmail,
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
                  const SizedBox(height: 8),
                  for (final (i, s) in _sheetSteps.indexed)
                    _StepTile(number: i + 1, step: s),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: () => context.go(Routes.sheet),
                      icon: const Icon(Icons.table_chart_outlined),
                      label: const Text('Open the Sheet tab'),
                    ),
                  ),
                  const SectionHeader('About'),
                  Text(
                    'BuildQuantify, developed by ARCONSTRUKT.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => showLicensePage(
                        context: context,
                        applicationName: 'BuildQuantify',
                      ),
                      child: const Text('Open-source licenses'),
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

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.step});

  final int number;
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Step $number',
            excludeSemantics: true,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '$number',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(step.text, style: theme.textTheme.bodyLarge),
                ),
                if (step.image != null) ...[
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        step.image!,
                        semanticLabel: step.imageLabel,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
