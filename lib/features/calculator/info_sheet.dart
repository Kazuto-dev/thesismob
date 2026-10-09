import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../materials/material_spec.dart';

/// Bottom sheet listing a material's definitions or solution steps.
class MaterialInfoSheet extends StatelessWidget {
  const MaterialInfoSheet({
    super.key,
    required this.title,
    required this.sections,
    this.references = const [],
  });

  final String title;
  final List<InfoSection> sections;
  final List<String> references;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.headlineSmall),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          for (final s in sections) ...[
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(s.title, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 6),
            Text(s.body, style: theme.textTheme.bodyLarge),
            if (s.formula != null) ...[
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    s.formula!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ],
          if (references.isNotEmpty) ...[
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: Text('References', style: theme.textTheme.titleMedium),
            ),
            for (final url in references)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      launchUrl(Uri.parse(url), webOnlyWindowName: '_blank'),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(Uri.parse(url).host.replaceFirst('www.', '')),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
