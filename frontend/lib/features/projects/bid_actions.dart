import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/project.dart';
import '../../data/quotes.dart';
import '../../export/bid_documents.dart';
import '../../export/files.dart';
// Loaded on first use, like the bill of quantities PDF.
import '../../export/bid_pdf.dart' deferred as bid_pdf;
import 'quotes_screen.dart';
import 'revisions_screen.dart';

/// The project menu's entries for estimate revisions, the bill of
/// quantities for bidders and quotes from bidders.
List<Widget> bidMenuItems(BuildContext context, Project project) => [
  const Divider(),
  MenuItemButton(
    leadingIcon: const Icon(Icons.history),
    onPressed: () => openRevisions(context, project),
    child: Text(context.tr('Estimate revisions')),
  ),
  MenuItemButton(
    leadingIcon: const Icon(Icons.assignment_outlined),
    onPressed: project.items.isEmpty
        ? null
        : () => showBidBoqDialog(context, project),
    child: Text(context.tr(bidBoqTitle)),
  ),
  MenuItemButton(
    leadingIcon: const Icon(Icons.compare_arrows),
    onPressed: () => openQuotes(context, project),
    child: Text(context.tr('Compare quotes')),
  ),
];

/// Opens the project's saved estimate revisions.
Future<void> openRevisions(BuildContext context, Project project) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RevisionsScreen(projectId: project.id),
      ),
    );

/// Opens the quotes from bidders, compared with the estimate.
Future<void> openQuotes(BuildContext context, Project project) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuotesScreen(projectId: project.id),
      ),
    );

/// Asks which scope to send to bidders, then downloads its bill of
/// quantities as a PDF or CSV file.
Future<void> showBidBoqDialog(BuildContext context, Project project) async {
  final choice = await showDialog<({String scope, bool pdf})>(
    context: context,
    builder: (_) => _BidBoqDialog(project: project),
  );
  if (choice == null || !context.mounted) return;
  if (choice.pdf) {
    await downloadBidPdf(context, project, choice.scope);
  } else {
    await downloadBidCsv(context, project, choice.scope);
  }
}

/// Downloads the bill of quantities for bidders of [scope] as a PDF.
Future<void> downloadBidPdf(
  BuildContext context,
  Project project,
  String scope,
) async {
  showMessage(context, context.tr('Preparing the PDF…'));
  try {
    await bid_pdf.loadLibrary();
    final bytes = await bid_pdf.bidPdf(project, scope: scope);
    final saved = await saveFile(
      '${bidFileSlug(project, scope)}.pdf',
      bytes,
      'application/pdf',
    );
    if (!context.mounted) return;
    showMessage(
      context,
      context.tr(
        saved
            ? 'Downloaded the bill for bidders.'
            : "Downloads aren't supported here.",
      ),
    );
  } catch (_) {
    if (context.mounted) {
      showMessage(context, context.tr("Couldn't make the PDF."));
    }
  }
}

/// Downloads the bill of quantities for bidders of [scope] as a CSV file.
Future<void> downloadBidCsv(
  BuildContext context,
  Project project,
  String scope,
) async {
  final saved = await saveFile(
    '${bidFileSlug(project, scope)}.csv',
    Uint8List.fromList(utf8.encode(bidCsv(project, scope: scope))),
    'text/csv',
  );
  if (!context.mounted) return;
  showMessage(
    context,
    context.tr(
      saved
          ? 'Downloaded the bill for bidders (CSV).'
          : "Downloads aren't supported here.",
    ),
  );
}

/// The scope of a bill for bidders: the whole job or one trade.
class _BidBoqDialog extends StatefulWidget {
  const _BidBoqDialog({required this.project});

  final Project project;

  @override
  State<_BidBoqDialog> createState() => _BidBoqDialogState();
}

class _BidBoqDialogState extends State<_BidBoqDialog> {
  var _scope = wholeJob;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(context.tr(bidBoqTitle)),
      scrollable: true,
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(
                'The work items with their quantities, empty unit price and '
                'amount columns, a total to fill in and short instructions, '
                'for contractors or subcontractors to price.',
              ),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Space.lg),
            Text(context.tr('Scope'), style: theme.textTheme.labelLarge),
            const SizedBox(height: Space.sm),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final s in scopesOf(widget.project))
                  if (s.key != generalScope)
                    ChoiceChip(
                      label: Text(
                        s.letter.isEmpty
                            ? context.tr(s.label)
                            : '${s.letter}. ${context.tr(s.label)}',
                      ),
                      selected: _scope == s.key,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _scope = s.key),
                    ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel')),
        ),
        OutlinedButton(
          onPressed: () =>
              Navigator.of(context).pop((scope: _scope, pdf: false)),
          child: Text(context.tr('CSV')),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop((scope: _scope, pdf: true)),
          child: Text(context.tr('PDF')),
        ),
      ],
    );
  }
}
