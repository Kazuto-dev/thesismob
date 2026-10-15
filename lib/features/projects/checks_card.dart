import 'package:material_ui/material_ui.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/checks.dart';
import '../../data/project.dart';

/// The project's numbers checked against what is usual for houses.
class ChecksCard extends StatelessWidget {
  const ChecksCard({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final checks = checkProject(project);
    if (checks.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final palette = AppPalette.of(context);
    final warnings = checks.where((c) => c.level == CheckLevel.warning).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                context.tr('Checks'),
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: Space.xs),
            Text(
              warnings == 0
                  ? context.tr('Nothing looks out of the ordinary.')
                  : context.tr(
                      warnings == 1
                          ? '1 thing to look at before sending this out.'
                          : '{n} things to look at before sending this out.',
                      {'n': warnings},
                    ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            for (final c in checks) ...[
              const SizedBox(height: Space.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    switch (c.level) {
                      CheckLevel.ok => Icons.check_circle_outline,
                      CheckLevel.info => Icons.info_outline,
                      CheckLevel.warning => Icons.warning_amber_rounded,
                    },
                    size: 20,
                    color: switch (c.level) {
                      CheckLevel.ok => palette.success,
                      CheckLevel.info => scheme.primary,
                      CheckLevel.warning => palette.warning,
                    },
                  ),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title, style: theme.textTheme.bodyMedium),
                        Text(
                          c.detail,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
