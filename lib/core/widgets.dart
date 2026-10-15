import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../materials/material_spec.dart';
import 'layout.dart';
import 'theme.dart';

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

/// Large title at the top of a tab's content, aligned with the content
/// below it, with optional [actions] on the right.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.xl, bottom: Space.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.headlineMedium),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: Space.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
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
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(Radii.lg + 4),
                ),
                child: SizedBox.square(
                  dimension: 80,
                  child: Icon(icon, size: 36, color: scheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: Space.xl),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: Space.sm),
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: Space.xl),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A heading above a group of items, with an optional [trailing] action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing, this.padding});

  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? const EdgeInsets.fromLTRB(0, Space.xxl, 0, Space.md),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(text, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// A card that can be tapped, with a hover border on desktop and a clear
/// focus ring for keyboard users.
class TapCard extends StatefulWidget {
  const TapCard({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(Space.lg),
    this.color,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  State<TapCard> createState() => _TapCardState();
}

class _TapCardState extends State<TapCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final side = _focused
        ? BorderSide(color: scheme.primary, width: 2.5)
        : BorderSide(color: _hovered ? scheme.outline : scheme.outlineVariant);
    return Card(
      color: widget.color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: side,
      ),
      child: InkWell(
        onTap: widget.onTap,
        onHover: (v) => setState(() => _hovered = v),
        onFocusChange: (v) => setState(() => _focused = v),
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );
  }
}

/// A rounded square in a category's colour holding a material or category
/// icon, so every list in the app uses the same icon language.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    this.category,
    this.image,
    this.icon,
    this.size = 48,
    this.background,
  }) : assert(image != null || icon != null);

  IconTile.material(MaterialSpec spec, {Key? key, double size = 48})
    : this(key: key, category: spec.category, image: spec.image, size: size);

  IconTile.category(
    MaterialCategory category, {
    Key? key,
    double size = 56,
    Color? background,
  }) : this(
         key: key,
         category: category,
         image: 'assets/images/categories/${category.name}.png',
         size: size,
         background: background,
       );

  final MaterialCategory? category;
  final String? image;
  final IconData? icon;
  final double size;

  /// Overrides the category container, e.g. on a tinted banner.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context).category(category);
    final inset = size * 0.22;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background ?? colors.container,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: SizedBox.square(
          dimension: size,
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: image != null
                ? Image.asset(
                    image!,
                    color: colors.accent,
                    colorBlendMode: BlendMode.srcIn,
                    fit: BoxFit.contain,
                  )
                : Icon(icon, size: size - inset * 2, color: colors.accent),
          ),
        ),
      ),
    );
  }
}

/// Theme for content on the dark [InkPanel], built once.
final ThemeData _onInkTheme = buildTheme(Brightness.dark);

/// The dark brand surface with a faint blueprint grid. Content inside it
/// uses the dark theme, so text, icons and buttons read correctly.
class InkPanel extends StatelessWidget {
  const InkPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.xl),
    this.borderRadius = const BorderRadius.all(Radius.circular(Radii.xl)),
    this.grid = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final bool grid;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: CustomPaint(
        painter: _BlueprintPainter(
          background: palette.ink,
          line: grid ? palette.inkLine : null,
          glow: palette.brand.withValues(alpha: 0.16),
        ),
        child: Theme(
          data: _onInkTheme,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: palette.onInk),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class _BlueprintPainter extends CustomPainter {
  const _BlueprintPainter({
    required this.background,
    required this.line,
    required this.glow,
  });

  final Color background;
  final Color? line;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    // A soft amber glow in the top-right corner.
    final center = Offset(size.width, 0);
    final radius = size.shortestSide * 1.1;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [glow, glow.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final color = line;
    if (color == null) return;
    const step = 24.0;
    final minor = Paint()
      ..color = color
      ..strokeWidth = 1;
    final major = Paint()
      ..color = color.withValues(alpha: color.a * 2)
      ..strokeWidth = 1;
    var i = 0;
    for (var x = 0.0; x <= size.width; x += step, i++) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        i % 4 == 0 ? major : minor,
      );
    }
    i = 0;
    for (var y = 0.0; y <= size.height; y += step, i++) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i % 4 == 0 ? major : minor,
      );
    }
  }

  @override
  bool shouldRepaint(_BlueprintPainter old) =>
      old.background != background || old.line != line || old.glow != glow;
}

/// A label and value on one line, used for result breakdowns.
class KeyValueLine extends StatelessWidget {
  const KeyValueLine(
    this.label,
    this.value, {
    super.key,
    this.emphasize = false,
    this.padding = const EdgeInsets.symmetric(vertical: 10),
  });

  final String label;
  final String value;
  final bool emphasize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: Space.lg),
            Expanded(
              flex: 2,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: tabular(
                  emphasize
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One coloured share of a [ProportionBar].
typedef Proportion = ({String label, double value, Color color});

/// A single stacked bar showing how a total splits into parts, with a
/// legend underneath. Parts are drawn in the order given.
class ProportionBar extends StatelessWidget {
  const ProportionBar({
    super.key,
    required this.parts,
    required this.format,
    this.height = 10,
  });

  final List<Proportion> parts;
  final String Function(double value) format;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = parts.fold<double>(0, (sum, p) => sum + p.value);
    if (total <= 0) return const SizedBox.shrink();
    final shown = [
      for (final p in parts)
        if (p.value > 0) p,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, p) in shown.indexed) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: (p.value / total * 1000).round().clamp(1, 1000),
                      child: Tooltip(
                        message: '${p.label}: ${format(p.value)}',
                        child: ColoredBox(color: p.color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.md),
        Wrap(
          spacing: Space.lg,
          runSpacing: Space.sm,
          children: [
            for (final p in shown)
              MergeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const SizedBox.square(dimension: 10),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${p.label} ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      format(p.value),
                      style: tabular(
                        theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
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

/// Lets long tokens such as e-mail addresses wrap at sensible points
/// (after "@" and before dots) instead of mid-word.
String breakable(String text) =>
    text.replaceAll('@', '@​').replaceAll('.', '​.');

/// Space at the bottom of scrolling content so the last item clears a
/// floating bar.
double bottomClearance(BuildContext context) =>
    WindowSize.of(context) == WindowSize.compact ? Space.xxl : Space.xxxl;

/// The BuildQuantify mark: the house logo on an amber tile.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.brand,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: SizedBox.square(
          dimension: size,
          child: Padding(
            padding: EdgeInsets.all(size * 0.18),
            child: Image.asset(
              'assets/images/brand/house.png',
              color: palette.onBrand,
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

/// The mark followed by the product name.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: size),
        const SizedBox(width: Space.md),
        Text(
          'BuildQuantify',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

/// Lays out [children] in equal columns, rows stretched to the tallest.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    required this.columnsFor,
    this.gap = Space.md,
  });

  final List<Widget> children;
  final int Function(double width) columnsFor;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsFor(constraints.maxWidth);
        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += columns) {
          if (i > 0) rows.add(SizedBox(height: gap));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) SizedBox(width: gap),
                    Expanded(
                      child: i + j < children.length
                          ? children[i + j]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}
