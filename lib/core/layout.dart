import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Material 3 window size classes.
enum WindowSize {
  /// Phones in portrait, under 600 px.
  compact,

  /// Tablets and phones in landscape, 600-1023 px.
  medium,

  /// Laptops and desktops, 1024 px and up.
  expanded;

  static WindowSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return compact;
    if (width < 1024) return medium;
    return expanded;
  }
}

/// Side gutter: 16 px on phones, 32 px elsewhere.
double gutterOf(BuildContext context) =>
    WindowSize.of(context) == WindowSize.compact ? 16 : 32;

/// Horizontal padding that centres content of at most [maxWidth] inside
/// [available] width, never less than the gutter.
double contentInset(
  BuildContext context,
  double available, {
  double maxWidth = 1040,
}) => math.max(gutterOf(context), (available - maxWidth) / 2);

/// Centres [child] and caps its width so lines and forms stay readable on
/// wide screens, with the standard gutter on each side.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 1040});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final gutter = gutterOf(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth + gutter * 2),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: child,
          ),
        ),
      ),
    );
  }
}
