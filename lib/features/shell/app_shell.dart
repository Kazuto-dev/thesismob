import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/layout.dart';
import '../../state/estimates_controller.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination('Estimate', Icons.calculate_outlined, Icons.calculate),
  _Destination('History', Icons.history, Icons.history),
  _Destination('Summary', Icons.receipt_long_outlined, Icons.receipt_long),
  _Destination('Sheet', Icons.table_chart_outlined, Icons.table_chart),
];

/// Top-level layout: a bottom navigation bar on phones and a labelled
/// navigation rail on tablets and desktops. Each tab keeps its own state.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final size = WindowSize.of(context);
    final count = context.select<EstimatesController, int>(
      (c) => c.summary.length,
    );

    Widget icon(_Destination d, IconData data) => d.label == 'Summary'
        ? Badge.count(
            count: count,
            isLabelVisible: count > 0,
            child: Icon(data),
          )
        : Icon(data);

    if (size == WindowSize.compact) {
      return Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _select,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: icon(d, d.icon),
                selectedIcon: icon(d, d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final extended = size == WindowSize.expanded;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _select,
            extended: extended,
            labelType: extended ? null : NavigationRailLabelType.all,
            minExtendedWidth: 200,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ExcludeSemantics(
                child: Image.asset(
                  'assets/images/brand/house.png',
                  height: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: icon(d, d.icon),
                  selectedIcon: icon(d, d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: shell),
        ],
      ),
    );
  }
}
