import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fixed brand/category accent colors that stay the same across light and
/// dark mode (used for workout category tags, macro rings, icons, etc.).
class AppBrand {
  AppBrand._();

  static const primary = Color(0xFF7C5CFF); // purple brand
  static const secondary = Color(0xFF10B981); // emerald
  static const accentOrange = Color(0xFFFF8A3D);
  static const accentBlue = Color(0xFF3DA5FF);
  static const accentPink = Color(0xFFFF5C93);

  // Macronutrient colors (used across the nutrition UI).
  static const calories = Color(0xFF7C5CFF); // purple
  static const protein = Color(0xFFFF5C93); // pink
  static const carbs = Color(0xFFFFB020); // amber
  static const fat = Color(0xFF3DA5FF); // blue
  static const fiber = Color(0xFF10B981); // green
}

class AppPalette {
  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color accentOrange;
  final Color accentBlue;
  final Color accentPink;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color gradientStart;
  final Color gradientEnd;
  final Brightness brightness;

  const AppPalette({
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.accentOrange,
    required this.accentBlue,
    required this.accentPink,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.gradientStart,
    required this.gradientEnd,
    required this.brightness,
  });

  static const light = AppPalette(
    primary: Color(0xFF7C5CFF),
    primaryDark: Color(0xFF6538E0),
    secondary: Color(0xFF10B981),
    accentOrange: Color(0xFFFF8A3D),
    accentBlue: Color(0xFF3DA5FF),
    accentPink: Color(0xFFFF5C93),
    background: Color(0xFFF6F5FB),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1C1830),
    textSecondary: Color(0xFF817B99),
    gradientStart: Color(0xFF8B5CFF),
    gradientEnd: Color(0xFF6538E0),
    brightness: Brightness.light,
  );

  // Black + purple dark theme.
  static const dark = AppPalette(
    primary: Color(0xFFA98BFF),
    primaryDark: Color(0xFF8B5CF6),
    secondary: Color(0xFF34D399),
    accentOrange: Color(0xFFFF9F5C),
    accentBlue: Color(0xFF5EBBFF),
    accentPink: Color(0xFFFF7AA8),
    background: Color(0xFF0B0912),
    surface: Color(0xFF171320),
    textPrimary: Color(0xFFF3EFFC),
    textSecondary: Color(0xFF9C93B5),
    gradientStart: Color(0xFF8B5CF6),
    gradientEnd: Color(0xFF6D28D9),
    brightness: Brightness.dark,
  );

  Color get shadow => brightness == Brightness.dark
      ? Colors.black.withValues(alpha: 0.45)
      : Colors.black.withValues(alpha: 0.04);

  /// Subtle purple hairline that gives cards definition on the near-black
  /// dark background (transparent in light mode, where shadows do the work).
  Color get cardBorder => brightness == Brightness.dark
      ? primary.withValues(alpha: 0.10)
      : Colors.transparent;
}

extension AppPaletteX on BuildContext {
  AppPalette get colors =>
      Theme.of(this).brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
}

class AppTheme {
  AppTheme._();

  static ThemeData _build(AppPalette p) {
    final base = ThemeData(brightness: p.brightness, useMaterial3: true);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      textTheme: textTheme.apply(
        bodyColor: p.textPrimary,
        displayColor: p.textPrimary,
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: p.primary,
        secondary: p.secondary,
        surface: p.surface,
        brightness: p.brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: p.background),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : p.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.primary.withValues(alpha: 0.4)
              : p.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }

  static ThemeData get light => _build(AppPalette.light);
  static ThemeData get dark => _build(AppPalette.dark);
}
