import 'package:material_ui/material_ui.dart';

import '../materials/material_spec.dart';

/// Spacing scale on a 4 px grid.
abstract final class Space {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

/// Corner radii, from chips up to full-width panels.
abstract final class Radii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

/// Colours for one material category: [accent] for its icon, [container]
/// behind it, [onContainer] for text on the container and [chart] for its
/// share in charts.
///
/// Chart colours follow the categorical order structural, architectural,
/// electrical, plumbing (orange, aqua, yellow, blue), which passes the
/// colour-blind separation checks for adjacent segments in both modes.
@immutable
class CategoryColors {
  const CategoryColors(
    this.accent,
    this.container,
    this.onContainer,
    this.chart,
  );

  final Color accent;
  final Color container;
  final Color onContainer;
  final Color chart;
}

/// Brand colours the Material colour scheme has no slot for.
///
/// The "ink" panel is the dark brand surface that holds the numbers that
/// matter: the home header, an estimate's result and the project total.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brand,
    required this.onBrand,
    required this.ink,
    required this.inkRaised,
    required this.onInk,
    required this.onInkMuted,
    required this.inkLine,
    required this.inkAccent,
    required this.success,
    required this.warning,
    required this.structural,
    required this.architectural,
    required this.electrical,
    required this.plumbing,
    required this.other,
  });

  /// Construction amber, used to fill primary buttons.
  final Color brand;
  final Color onBrand;
  final Color ink;
  final Color inkRaised;
  final Color onInk;
  final Color onInkMuted;

  /// Blueprint grid lines and dividers on [ink].
  final Color inkLine;

  /// Amber for figures on [ink].
  final Color inkAccent;
  final Color success;

  /// Icons for values that look wrong but are allowed.
  final Color warning;
  final CategoryColors structural;
  final CategoryColors architectural;
  final CategoryColors electrical;
  final CategoryColors plumbing;

  /// Entries that belong to no category, such as imported legacy rows.
  final CategoryColors other;

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  CategoryColors category(MaterialCategory? c) => switch (c) {
    MaterialCategory.structural => structural,
    MaterialCategory.architectural => architectural,
    MaterialCategory.electrical => electrical,
    MaterialCategory.plumbing => plumbing,
    null => other,
  };

  static const light = AppPalette(
    brand: Color(0xFFF59E0B),
    onBrand: Color(0xFF1C1917),
    ink: Color(0xFF1C1917),
    inkRaised: Color(0xFF2E2925),
    onInk: Color(0xFFFAFAF9),
    onInkMuted: Color(0xFFC8C2BA),
    inkLine: Color(0x14FFFFFF),
    inkAccent: Color(0xFFFBBF24),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    structural: CategoryColors(
      Color(0xFFC2410C),
      Color(0xFFFFEDD5),
      Color(0xFF7C2D12),
      Color(0xFFEB6834),
    ),
    architectural: CategoryColors(
      Color(0xFF047857),
      Color(0xFFD1FAE5),
      Color(0xFF064E3B),
      Color(0xFF1BAF7A),
    ),
    electrical: CategoryColors(
      Color(0xFFA16207),
      Color(0xFFFEF9C3),
      Color(0xFF713F12),
      Color(0xFFEDA100),
    ),
    plumbing: CategoryColors(
      Color(0xFF1D4ED8),
      Color(0xFFDBEAFE),
      Color(0xFF1E3A8A),
      Color(0xFF2A78D6),
    ),
    other: CategoryColors(
      Color(0xFF57534E),
      Color(0xFFEDE8E1),
      Color(0xFF292524),
      Color(0xFF8C847B),
    ),
  );

  static const dark = AppPalette(
    brand: Color(0xFFFBBF24),
    onBrand: Color(0xFF1C1917),
    ink: Color(0xFF26221F),
    inkRaised: Color(0xFF332E2A),
    onInk: Color(0xFFFAFAF9),
    onInkMuted: Color(0xFFC8C2BA),
    inkLine: Color(0x12FFFFFF),
    inkAccent: Color(0xFFFCD34D),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    structural: CategoryColors(
      Color(0xFFFDBA74),
      Color(0xFF3B1A0A),
      Color(0xFFFFEDD5),
      Color(0xFFD95926),
    ),
    architectural: CategoryColors(
      Color(0xFF6EE7B7),
      Color(0xFF052E22),
      Color(0xFFD1FAE5),
      Color(0xFF199E70),
    ),
    electrical: CategoryColors(
      Color(0xFFFDE047),
      Color(0xFF3A2E05),
      Color(0xFFFEF9C3),
      Color(0xFFC98500),
    ),
    plumbing: CategoryColors(
      Color(0xFF93C5FD),
      Color(0xFF0B2550),
      Color(0xFFDBEAFE),
      Color(0xFF3987E5),
    ),
    other: CategoryColors(
      Color(0xFFC8C2BA),
      Color(0xFF2F2B27),
      Color(0xFFF5F5F4),
      Color(0xFF8A837B),
    ),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  // Dark amber passes 4.5:1 on white for text, links and focus rings.
  primary: Color(0xFFB45309),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFFEF3C7),
  onPrimaryContainer: Color(0xFF78350F),
  secondary: Color(0xFF57534E),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFEDE8E1),
  onSecondaryContainer: Color(0xFF1C1917),
  tertiary: Color(0xFF0F766E),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFCCFBF1),
  onTertiaryContainer: Color(0xFF134E4A),
  error: Color(0xFFB91C1C),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFEE2E2),
  onErrorContainer: Color(0xFF7F1D1D),
  surface: Color(0xFFF6F4F0),
  onSurface: Color(0xFF1C1917),
  surfaceDim: Color(0xFFE9E5DF),
  surfaceBright: Color(0xFFFFFFFF),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFBF9F6),
  surfaceContainer: Color(0xFFF1EEE9),
  surfaceContainerHigh: Color(0xFFEAE6E0),
  surfaceContainerHighest: Color(0xFFE3DED7),
  onSurfaceVariant: Color(0xFF57534E),
  outline: Color(0xFF8C847B),
  outlineVariant: Color(0xFFE4DED6),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF292524),
  onInverseSurface: Color(0xFFF5F5F4),
  inversePrimary: Color(0xFFFCD34D),
  surfaceTint: Color(0x00000000),
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFBBF24),
  onPrimary: Color(0xFF1C1917),
  primaryContainer: Color(0xFF4A2C0A),
  onPrimaryContainer: Color(0xFFFDE68A),
  secondary: Color(0xFFC8C2BA),
  onSecondary: Color(0xFF1C1917),
  secondaryContainer: Color(0xFF2F2B27),
  onSecondaryContainer: Color(0xFFF5F5F4),
  tertiary: Color(0xFF5EEAD4),
  onTertiary: Color(0xFF042F2E),
  tertiaryContainer: Color(0xFF06302C),
  onTertiaryContainer: Color(0xFFCCFBF1),
  error: Color(0xFFF87171),
  onError: Color(0xFF450A0A),
  errorContainer: Color(0xFF5A1414),
  onErrorContainer: Color(0xFFFECACA),
  surface: Color(0xFF12100E),
  onSurface: Color(0xFFF5F5F4),
  surfaceDim: Color(0xFF12100E),
  surfaceBright: Color(0xFF3A3531),
  surfaceContainerLowest: Color(0xFF0D0B0A),
  surfaceContainerLow: Color(0xFF1A1715),
  surfaceContainer: Color(0xFF1F1C19),
  surfaceContainerHigh: Color(0xFF292522),
  surfaceContainerHighest: Color(0xFF34302C),
  onSurfaceVariant: Color(0xFFC8C2BA),
  outline: Color(0xFF8A837B),
  outlineVariant: Color(0xFF34302C),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFFF5F5F4),
  onInverseSurface: Color(0xFF1C1917),
  inversePrimary: Color(0xFFB45309),
  surfaceTint: Color(0x00000000),
);

/// Background of cards, inputs and navigation bars: white on the warm
/// canvas in light mode, one step above the canvas in dark mode.
Color raisedSurface(ColorScheme scheme) => scheme.brightness == Brightness.light
    ? scheme.surfaceContainerLowest
    : scheme.surfaceContainerLow;

/// Digits of equal width, so amounts line up in lists and tables.
TextStyle? tabular(TextStyle? style) =>
    style?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

TextTheme _textTheme() => const TextTheme(
  displaySmall: TextStyle(
    fontSize: 36,
    height: 44 / 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
  ),
  headlineLarge: TextStyle(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
  ),
  headlineMedium: TextStyle(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
  ),
  headlineSmall: TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  ),
  titleLarge: TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  ),
  titleMedium: TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  ),
  titleSmall: TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  ),
  bodyLarge: TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  ),
  bodyMedium: TextStyle(
    fontSize: 14,
    height: 21 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  ),
  bodySmall: TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  ),
  labelLarge: TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  ),
  labelMedium: TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  ),
  labelSmall: TextStyle(
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  ),
);

ThemeData buildTheme([Brightness brightness = Brightness.light]) {
  final light = brightness == Brightness.light;
  final scheme = light ? _lightScheme : _darkScheme;
  final palette = light ? AppPalette.light : AppPalette.dark;
  final raised = raisedSurface(scheme);
  final text = _textTheme().apply(
    fontFamily: 'PlusJakartaSans',
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  final cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.lg),
    side: BorderSide(color: scheme.outlineVariant),
  );
  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    fontFamily: 'PlusJakartaSans',
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    extensions: [palette],
    // Keep 48 px touch targets on desktop browsers too.
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkRipple.splashFactory,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final p in TargetPlatform.values)
          p: const FadeForwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      toolbarHeight: 64,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: raised,
      margin: EdgeInsets.zero,
      shape: cardShape,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 24),
        ),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        elevation: const WidgetStatePropertyAll(0),
        textStyle: WidgetStatePropertyAll(
          text.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.12)
              : palette.brand,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.38)
              : palette.onBrand,
        ),
        iconColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.38)
              : palette.onBrand,
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? palette.onBrand.withValues(alpha: 0.12)
              : states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)
              ? palette.onBrand.withValues(alpha: 0.08)
              : null,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: const StadiumBorder(),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: scheme.primary,
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        textStyle: WidgetStatePropertyAll(text.labelLarge),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : raised,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurface,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: raised,
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
      ),
      labelStyle: text.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: raised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: inputBorder(scheme.outline),
      enabledBorder: inputBorder(scheme.outline),
      focusedBorder: inputBorder(scheme.primary, 2),
      errorBorder: inputBorder(scheme.error),
      focusedErrorBorder: inputBorder(scheme.error, 2),
      labelStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => text.bodyLarge!.copyWith(
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.error)
              ? scheme.error
              : states.contains(WidgetState.focused)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
      helperStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      suffixStyle: text.bodyLarge?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      prefixStyle: text.bodyLarge?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      helperMaxLines: 2,
      errorMaxLines: 2,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: raised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: scheme.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium?.copyWith(
          color: states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w600,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: raised,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      selectedLabelTextStyle: text.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      unselectedLabelTextStyle: text.labelLarge?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    listTileTheme: ListTileThemeData(
      titleTextStyle: text.titleMedium,
      subtitleTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      iconColor: scheme.onSurfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      width: 560,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      actionTextColor: scheme.inversePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: raised,
      surfaceTintColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 720),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: raised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: raised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      textStyle: text.bodyLarge,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(raised),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: palette.brand,
      textColor: palette.onBrand,
      textStyle: text.labelSmall,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
  );
}
