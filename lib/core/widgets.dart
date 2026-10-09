import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Sets the browser tab title for a screen.
class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Title(
    title: title == null ? 'BuildQuantify' : '$title · BuildQuantify',
    color: Theme.of(context).colorScheme.primary,
    child: child,
  );
}

/// Friendly placeholder for an empty list, with an optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  size: 36,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// A small heading above a group of items.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.padding});

  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? const EdgeInsets.fromLTRB(0, 24, 0, 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}

/// Shows a snackbar, replacing any that is showing.
void showMessage(
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

/// Allows digits and at most one decimal point, so pasted "1,250.50"
/// becomes "1250.50" and letters never reach the field.
class DecimalInputFormatter extends TextInputFormatter {
  const DecimalInputFormatter({this.allowDecimal = true});

  final bool allowDecimal;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final pattern = allowDecimal ? RegExp(r'[^0-9.]') : RegExp(r'[^0-9]');
    final cleaned = newValue.text.replaceAll(pattern, '');
    if (allowDecimal && '.'.allMatches(cleaned).length > 1) return oldValue;
    if (cleaned == newValue.text) return newValue;
    final offset =
        (newValue.selection.end - (newValue.text.length - cleaned.length))
            .clamp(0, cleaned.length);
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
