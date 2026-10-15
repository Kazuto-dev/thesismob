import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/widgets.dart';
import '../../data/project.dart';
import '../../data/sheets_export_service.dart';
import '../../export/files.dart';
import '../../export/project_documents.dart';
import '../../export/project_pdf.dart';
import '../../router.dart';
import '../../state/projects_controller.dart';
import '../../state/sheet_settings_controller.dart';

/// Downloads the project's bill of quantities as a PDF.
Future<void> downloadProjectPdf(BuildContext context, Project project) async {
  showMessage(context, 'Preparing the PDF…');
  try {
    final bytes = await projectPdf(project);
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

/// Appends the project's estimates to the configured Google Sheet.
Future<void> sendProjectToSheet(BuildContext context, Project project) async {
  final result = await context.read<SheetSettingsController>().export(
    project.items,
  );
  if (!context.mounted) return;
  showMessage(
    context,
    result.message,
    action: result.status == SheetsExportStatus.missingSheetInfo
        ? SnackBarAction(
            label: 'Set up',
            onPressed: () => context.go(Routes.settings),
          )
        : null,
  );
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
