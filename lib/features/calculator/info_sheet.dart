import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../materials/material_spec.dart';

/// Bottom sheet listing a material's definitions or solution steps.
class MaterialInfoSheet extends StatelessWidget {
  const MaterialInfoSheet({
    super.key,
    required this.spec,
    required this.title,
    required this.sections,
    this.references = const [],
  });

  final MaterialSpec spec;
  final String title;
  final List<InfoSection> sections;
  final List<String> references;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xxl),
        children: [
          Row(
            children: [
              IconTile.material(spec, size: 44),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.headlineSmall),
                    ),
                    Text(
                      spec.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          for (final (i, s) in sections.indexed) ...[
            const SizedBox(height: Space.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != 'Definitions') ...[
                  ExcludeSemantics(
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        '${i + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          s.title,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        s.body,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (s.formula != null) ...[
                        const SizedBox(height: Space.md),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(Radii.md),
                            border: Border(
                              left: BorderSide(
                                color: AppPalette.of(context).brand,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.lg,
                              vertical: Space.md,
                            ),
                            child: Text(
                              s.formula!,
                              style: tabular(
                                theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (references.isNotEmpty) ...[
            const SizedBox(height: Space.xxl),
            Semantics(
              header: true,
              child: Text('Sources', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: Space.xs),
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
