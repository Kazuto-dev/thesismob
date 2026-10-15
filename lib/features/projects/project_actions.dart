import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/widgets.dart';
import '../../data/project.dart';
import '../../data/google_sheets_client.dart';
import '../../export/files.dart';
import '../../export/project_documents.dart';
// Loaded on first use: the PDF library is large and few visits need it.
import '../../export/project_pdf.dart' deferred as pdf;
import '../../router.dart';
import '../../state/google_account_controller.dart';
import '../../state/projects_controller.dart';

/// Downloads the project's bill of quantities as a PDF.
Future<void> downloadProjectPdf(BuildContext context, Project project) async {
  showMessage(context, 'Preparing the PDF…');
  try {
    await pdf.loadLibrary();
    final bytes = await pdf.projectPdf(project);
    final saved = await saveFile(
      '${fileSlug(project, 'boq')}.pdf',
      bytes,
      'application/pdf',
    );
    if (!context.mounted) return;
    showMessage(
      context,
      saved
          ? 'Downloaded the bill of quantities.'
          : "Downloads aren't supported here.",
    );
  } catch (_) {
    if (context.mounted) showMessage(context, "Couldn't make the PDF.");
  }
}

/// Downloads the project as a CSV file for Excel or Google Sheets.
Future<void> downloadProjectCsv(BuildContext context, Project project) async {
  final saved = await saveFile(
    '${fileSlug(project, 'boq')}.csv',
    Uint8List.fromList(utf8.encode(projectCsv(project))),
    'text/csv',
  );
  if (!context.mounted) return;
  showMessage(
    context,
    saved
        ? 'Downloaded the spreadsheet (CSV).'
        : "Downloads aren't supported here.",
  );
}

/// Copies the project as plain text, ready to paste into a message.
Future<void> copyProjectText(BuildContext context, Project project) async {
  await Clipboard.setData(ClipboardData(text: projectText(project)));
  if (context.mounted) showMessage(context, 'Copied the project as text.');
}

/// Saves the project to a spreadsheet in the user's Google Drive, signing
/// in first if needed. Call it straight from a button press: Google's
/// sign-in window may only open in direct response to a tap.
Future<void> saveProjectToSheets(BuildContext context, Project project) async {
  final projects = context.read<ProjectsController>();
  final result = await context.read<GoogleAccountController>().saveProject(
    project,
  );
  final sheet = result.sheet;
  if (sheet != null) projects.setSheetId(project.id, sheet.id);
  if (!context.mounted) return;
  showMessage(
    context,
    result.message,
    action: sheet != null
        ? SnackBarAction(label: 'Open', onPressed: () => openUrl(sheet.url))
        : context.read<GoogleAccountController>().isConfigured
        ? null
        : SnackBarAction(
            label: 'Settings',
            onPressed: () => context.go(Routes.settings),
          ),
  );
}

/// Opens the spreadsheet the project was last saved to.
void openProjectSheet(Project project) {
  if (project.sheetId case final id?) openUrl(spreadsheetUrl(id));
}

/// Asks before deleting a project, then offers undo.
Future<void> confirmDeleteProject(BuildContext context, Project project) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete ${project.name}?'),
      content: Text(
        project.items.isEmpty
            ? 'This project has no estimates.'
            : 'Its ${project.items.length} estimates and budget settings '
                  'will be removed. History is kept.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final controller = context.read<ProjectsController>();
  final removed = controller.delete(project.id);
  if (removed == null) return;
  showMessage(
    context,
    'Deleted ${project.name}.',
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () => controller.restore(removed.index, removed.project),
    ),
  );
}

/// Duplicates a project, e.g. to price a second option.
void duplicateProject(BuildContext context, Project project) {
  final copy = context.read<ProjectsController>().duplicate(project.id);
  showMessage(context, 'Made ${copy.name}. New estimates go there.');
}
