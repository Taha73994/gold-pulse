import 'package:flutter/material.dart';

/// ألوان هوية «نبض الذهب» — نهاري وليلي.
class AppColors {
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color gold;
  final Color goldDeep;
  final Color ink;
  final Color muted;
  final Color border;
  final Color green;
  final Color red;
  final Color amber;
  final Color blue;
  final Color shadow;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.gold,
    required this.goldDeep,
    required this.ink,
    required this.muted,
    required this.border,
    required this.green,
    required this.red,
    required this.amber,
    required this.blue,
    required this.shadow,
  });

  static const dark = AppColors(
    bg: Color(0xFF0A0C11),
    surface: Color(0xFF121620),
    surfaceAlt: Color(0xFF1A202C),
    gold: Color(0xFFE9C46A),
    goldDeep: Color(0xFFC99B2F),
    ink: Color(0xFFF6F1E6),
    muted: Color(0xFF98A2B3),
    border: Color(0xFF252C3A),
    green: Color(0xFF4ADE80),
    red: Color(0xFFF87171),
    amber: Color(0xFFFBBF24),
    blue: Color(0xFF60A5FA),
    shadow: Color(0x66000000),
  );

  static const light = AppColors(
    bg: Color(0xFFF7F3EA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF0E9DA),
    gold: Color(0xFFC08A12),
    goldDeep: Color(0xFF8A5E00),
    ink: Color(0xFF1B1A17),
    muted: Color(0xFF6E675B),
    border: Color(0xFFE2D9C6),
    green: Color(0xFF15803D),
    red: Color(0xFFB91C1C),
    amber: Color(0xFFB45309),
    blue: Color(0xFF1D4ED8),
    shadow: Color(0x1A000000),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

class AppTheme {
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7E3A1), Color(0xFFD9AC45), Color(0xFFB8860B)],
  );

  static const subtleGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33E9C46A), Color(0x0DE9C46A)],
  );

  static ThemeData get dark => _build(Brightness.dark, AppColors.dark);
  static ThemeData get light => _build(Brightness.light, AppColors.light);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: 'Cairo',
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: c.goldDeep,
      brightness: brightness,
      primary: c.gold,
      onPrimary: brightness == Brightness.dark
          ? const Color(0xFF1A1508)
          : Colors.white,
      secondary: c.goldDeep,
      surface: c.surface,
      onSurface: c.ink,
      error: c.red,
    );

    final textTheme = base.textTheme
        .apply(fontFamily: 'Cairo', bodyColor: c.ink, displayColor: c.ink)
        .copyWith(
          displayLarge: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 46,
            fontWeight: FontWeight.w800,
            height: 1.05,
            color: c.ink,
            letterSpacing: -1,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: c.ink,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: c.ink,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: c.ink,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            height: 1.55,
            color: c.ink,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13.5,
            height: 1.55,
            color: c.ink,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            height: 1.45,
            color: c.muted,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: c.ink,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.muted,
            letterSpacing: 0.2,
          ),
        );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      textTheme: textTheme,
      dividerColor: c.border,
      splashColor: c.gold.withValues(alpha: 0.08),
      highlightColor: c.gold.withValues(alpha: 0.05),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: c.ink,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: c.ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.gold.withValues(alpha: 0.18),
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: selected ? c.gold : c.muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? c.gold : c.muted,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceAlt,
        hintStyle: TextStyle(fontFamily: 'Cairo', color: c.muted, fontSize: 13),
        labelStyle: TextStyle(fontFamily: 'Cairo', color: c.muted, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.gold, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.red),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.gold,
          foregroundColor:
              brightness == Brightness.dark ? const Color(0xFF161204) : Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          side: BorderSide(color: c.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.gold,
          textStyle: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceAlt,
        selectedColor: c.gold.withValues(alpha: 0.22),
        side: BorderSide(color: c.border),
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          color: c.ink,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceAlt,
        contentTextStyle: TextStyle(fontFamily: 'Cairo', color: c.ink),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.gold),
      iconTheme: IconThemeData(color: c.ink),
    );
  }
}

Color toneColor(String tone, AppColors c) {
  switch (tone) {
    case 'green':
      return c.green;
    case 'teal':
      return const Color(0xFF2DD4BF);
    case 'red':
      return c.red;
    case 'orange':
      return const Color(0xFFFB923C);
    default:
      return c.amber;
  }
}
