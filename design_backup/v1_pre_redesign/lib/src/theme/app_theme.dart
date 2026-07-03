import 'package:flutter/material.dart';

/// Mirrors Android `AppTheme` in `ui/Theme.kt`.
class AppTheme {
  static const Color background = Color(0xFFF8F2E7);
  static const Color backgroundLight = Color(0xFFFCF8EF);
  static const Color backgroundLighter = Color(0xFFF1E4CE);

  static const Color primary = Color(0xFFC96A22);
  static const Color primaryDark = Color(0xFF974B16);
  static const Color primaryLight = Color(0xFFE08935);
  static const Color primaryLighter = Color(0xFFEEA55F);
  static const Color primaryLightBackground = Color(0xFFFFF2E2);

  static const Color cardYellow = Color(0xFFE0B650);
  static const Color cardWhite = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF2F241B);
  static const Color textSecondary = Color(0xFF4A3A2C);
  static const Color textTertiary = Color(0xFF6E5C4D);
  static const Color textOnDark = Color(0xFFFFF6EC);

  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;

  static const double buttonHeight = 52;
  static const double logoSize = 120;
  static const double iconSize = 22;

  static const String fontFamily = 'Poppins';

  static ThemeData materialTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: background,
      ),
      dialogTheme: const DialogTheme(
        backgroundColor: background,
        shape: RoundedRectangleBorder(),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textOnDark,
        elevation: 4,
      ),
    );
  }

  static TextStyle text({
    required double size,
    FontWeight weight = FontWeight.normal,
    Color color = textPrimary,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }
}
