import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/layout.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../router.dart';

class _Step {
  const _Step(this.text);

  final String text;
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
    'Open a project and choose Google Sheets (or Settings → Sign in with '
    'Google).',
  ),
  _Step(
    'Pick your Google account and allow BuildQuantify to create files in '
    'your Drive. It can only open the spreadsheets it creates.',
  ),
  _Step(
    'The app makes "BuildQuantify – your project" in your Drive with three '
    'tabs: Bill of quantities, Materials and Budget. Choose Open to see it.',
  ),
  _Step(
    'After you change the project, choose Update Google Sheet to rewrite '
    'the same spreadsheet. Edit or share it in Google Sheets as usual.',
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
                  '100. The Prices tab holds the suggested prices; set your '
                  'own and choose your region there.',
                ),
                const SectionHeader('Your data'),
                paragraph(
                  'Projects, prices and history are saved in this browser '
                  'only, and clearing your browsing data removes them. Use '
                  'Settings → Backup and restore to keep a copy or move it to '
                  'another device.',
                ),
                const SectionHeader('Save to Google Sheets'),
                for (final (i, s) in _sheetSteps.indexed)
                  _StepTile(number: i + 1, step: s),
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
