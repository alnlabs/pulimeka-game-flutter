import 'package:flutter/material.dart';

/// Single palette for the whole app (tigers = primary, goats = secondary green).
class AppTheme {
  AppTheme._();

  // Surfaces
  static const Color background = Color(0xFFF8F2E7);
  static const Color backgroundLight = Color(0xFFFCF8EF);
  static const Color backgroundLighter = Color(0xFFF1E4CE);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color boardFill = Color(0xFFFFFBF5);

  // Brand (tigers / UI chrome)
  static const Color primary = Color(0xFFC96A22);
  static const Color primaryDark = Color(0xFF974B16);
  static const Color primaryLight = Color(0xFFE08935);
  static const Color primaryLighter = Color(0xFFEEA55F);
  static const Color primaryLightBackground = Color(0xFFFFF2E2);

  // Goats (secondary — board highlights & goat turn only)
  static const Color goatAccent = Color(0xFF5D8A66);
  static const Color goatSurface = Color(0xFFE8F0E9);
  static const Color goatMuted = Color(0x995D8A66);

  // Aliases used across game UI
  static const Color tigerAccent = primaryDark;
  static const Color tigerSurface = primaryLightBackground;
  static const Color tigerTurnBg = primaryDark;
  static const Color goatTurnBg = goatAccent;

  // Board drawing
  static const Color boardBorder = Color(0xFF6D4C41);
  static const Color boardLine = Color(0xFFB8A898);
  static const Color boardNode = Color(0xFFB8A898);
  static const Color validMoveStroke = goatAccent;
  static const Color hintNodeStroke = primaryLight;

  // Pieces on board
  static const Color pieceTigerBg = Color(0xE6FFC896);
  static const Color pieceTigerBorder = primaryDark;
  static const Color pieceTigerRing = primaryLight;
  static const Color pieceGoatBg = Color(0xE6D8E8DA);
  static const Color pieceGoatBorder = goatAccent;
  static const Color pieceGoatRing = Color(0xFF7CB342);

  // Feedback (tinted from brand, not random reds/oranges)
  static const Color messageErrorBg = Color(0xFFFFEBEE);
  static const Color messageErrorFg = Color(0xFFB71C1C);
  static const Color messageHintBg = primaryLightBackground;
  static const Color messageHintFg = primaryDark;
  static const Color messageInfoBg = goatSurface;
  static const Color messageInfoFg = goatAccent;

  // Text
  static const Color textPrimary = Color(0xFF2F241B);
  static const Color textSecondary = Color(0xFF4A3A2C);
  static const Color textTertiary = Color(0xFF6E5C4D);
  static const Color textOnDark = Color(0xFFFFF6EC);

  static Color get borderSubtle => textPrimary.withOpacity(0.12);

  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;

  static const double buttonHeight = 52;
  static const double logoSize = 120;
  static const double iconSize = 22;

  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;

  static const String fontFamily = 'Poppins';

  static List<BoxShadow> cardShadow({double opacity = 0.12}) => [
        BoxShadow(
          color: textPrimary.withOpacity(opacity),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration panelDecoration({
    Color? color,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? cardWhite,
      borderRadius: BorderRadius.circular(radiusMedium),
      border: Border.all(color: borderColor ?? borderSubtle),
      boxShadow: cardShadow(),
    );
  }

  static BoxDecoration topBarDecoration() {
    return BoxDecoration(
      color: primary,
      border: Border(
        bottom: BorderSide(color: primaryDark.withOpacity(0.4), width: 1),
      ),
      boxShadow: cardShadow(opacity: 0.08),
    );
  }

  static ButtonStyle get filledButtonStyle => FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textOnDark,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
        textStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );

  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: backgroundLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: BorderSide(color: textTertiary.withOpacity(0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: BorderSide(color: textTertiary.withOpacity(0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  static ThemeData materialTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: textOnDark,
        secondary: goatAccent,
        surface: background,
        onSurface: textPrimary,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textOnDark,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(style: filledButtonStyle),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
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
