import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/i18n.dart';
import '../core/widgets.dart';
import '../router.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => PageTitle(
    title: context.tr('Page not found'),
    child: Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        icon: Icons.explore_off_outlined,
        title: context.tr('Page not found'),
        message: context.tr(
          "That link doesn't lead anywhere in BuildQuantify.",
        ),
        action: FilledButton(
          onPressed: () => context.go(Routes.home),
          child: Text(context.tr('Go to home')),
        ),
      ),
    ),
  );
}
