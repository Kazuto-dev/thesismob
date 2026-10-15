import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/layout.dart';
import '../../core/theme.dart';
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
  _Step(
    'Pick a category on the Estimate tab, then a material. You can also '
    'search, in English or Filipino, for example "yero" or "gripo".',
  ),
  _Step(
    'Enter the measurements in metres. The price is filled in from your '
    'price book; type your supplier\'s price to use it instead. Options such '
    'as block size or bar spacing start with the usual choice.',
  ),
  _Step(
    'The estimate appears as you type: the quantity to buy, every other '
    'material the job needs (cement, sand, bars, fittings…) with its price, '
    'and how it was worked out. "Definitions" and "How it\'s calculated" '
    'explain every input and formula.',
  ),
  _Step(
    'Choose "Add to" your project. The Project tab groups the estimates by '
    'trade as a bill of quantities, merges them into one shopping list, and '
    'adds labour, contingency and, for a bid, overhead, profit and VAT.',
  ),
  _Step(
    'Download the project as a PDF or an Excel (CSV) file to send to a '
    'client, a supplier or your team.',
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
    "Type the app's email address (shown below and in Settings), keep it "
        'as Editor, and tap Send.',
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
    'In Settings, paste the link (or just the ID between /d/ and /edit), '
        'enter the name of the tab and select Save.',
    'assets/images/help/step_09.webp',
    'A spreadsheet link with the ID part highlighted.',
  ),
];

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    Widget paragraph(String text) =>
        Text(text, style: theme.textTheme.bodyLarge?.copyWith(color: muted));
    return PageTitle(
      title: 'Help',
      child: Scaffold(
        appBar: AppBar(title: const Text('How to use BuildQuantify')),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomClearance(context)),
          child: ContentWidth(
            maxWidth: 880,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Space.sm),
                paragraph(
                  'BuildQuantify works out how much construction material to '
                  'buy and what it costs. It works offline; you only need a '
                  'connection to send estimates to Google Sheets.',
                ),
                const SectionHeader('Make an estimate'),
                for (final (i, s) in _estimateSteps.indexed)
                  _StepTile(number: i + 1, step: s),
                const SectionHeader('Projects, history and prices'),
                paragraph(
                  'Keep each house, renovation or bid as its own project and '
                  'switch between them from the Project tab. History keeps '
                  'the latest result from each visit to a calculator, up to '
                  '100. Settings → Price book holds the suggested prices; '
                  'set your own and choose your region there.',
                ),
                const SectionHeader('Your data'),
                paragraph(
                  'Projects, prices and history are saved in this browser '
                  'only, and clearing your browsing data removes them. Use '
                  'Settings → Backup and restore to keep a copy or move it to '
                  'another device.',
                ),
                const SectionHeader('Send estimates to Google Sheets'),
                paragraph(
                  'Share your spreadsheet with this address as an Editor:',
                ),
                const SizedBox(height: Space.sm),
                Card(
                  child: ListTile(
                    title: SelectableText(
                      breakable(SheetsExportService.serviceAccountEmail),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: IconButton(
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
                  ),
                ),
                const SizedBox(height: Space.lg),
                ResponsiveGrid(
                  columnsFor: (w) => w >= 700 ? 2 : 1,
                  gap: Space.lg,
                  children: [
                    for (final (i, s) in _sheetSteps.indexed)
                      _PictureStep(number: i + 1, step: s),
                  ],
                ),
                const SizedBox(height: Space.xl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => context.go(Routes.settings),
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Open Settings'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepNumber extends StatelessWidget {
  const _StepNumber(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppPalette.of(context);
    return Semantics(
      label: 'Step $number',
      excludeSemantics: true,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: palette.brand,
        child: Text(
          '$number',
          style: theme.textTheme.labelLarge?.copyWith(
            color: palette.onBrand,
            fontWeight: FontWeight.w800,
          ),
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
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepNumber(number),
          const SizedBox(width: Space.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(step.text, style: theme.textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}

class _PictureStep extends StatelessWidget {
  const _PictureStep({required this.number, required this.step});

  final int number;
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StepNumber(number),
                  const SizedBox(height: Space.md),
                  Text(step.text, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            if (step.image != null) ...[
              const SizedBox(width: Space.lg),
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.md),
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
    );
  }
}
