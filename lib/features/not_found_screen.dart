import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/widgets.dart';
import '../router.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => PageTitle(
    title: 'Page not found',
    child: Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        icon: Icons.explore_off_outlined,
        title: 'Page not found',
        message: "That link doesn't lead anywhere in BuildQuantify.",
        action: FilledButton(
          onPressed: () => context.go(Routes.home),
          child: const Text('Go to home'),
        ),
      ),
    ),
  );
}
