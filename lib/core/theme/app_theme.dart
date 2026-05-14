import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  App Colors
// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Primary brand color (Teal)
  static const Color primary        = Color(0xFF0D7B6E);
  static const Color primaryLight   = Color(0xFF1A9E8E);
  static const Color primaryDark    = Color(0xFF095C52);
  static const Color primarySurface = Color(0xFFE6F4F2);

  // Accent
  static const Color accent         = Color(0xFF00C9B1);

  // Neutrals
  static const Color background     = Color(0xFFF5F7FA);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);
  static const Color border         = Color(0xFFE2E8F0);

  // Text
  static const Color textPrimary    = Color(0xFF1A202C);
  static const Color textSecondary  = Color(0xFF718096);
  static const Color textHint       = Color(0xFFA0AEC0);

  // Status
  static const Color success        = Color(0xFF38A169);
  static const Color successSurface = Color(0xFFE6F4ED);
  static const Color warning        = Color(0xFFD69E2E);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color error          = Color(0xFFE53E3E);
  static const Color errorSurface   = Color(0xFFFEE2E2);
  static const Color info           = Color(0xFF3182CE);
  static const Color infoSurface    = Color(0xFFEBF5FF);

  // Card gradient
  static const List<Color> cardGradient = [
    Color(0xFF0D7B6E),
    Color(0xFF095C52),
  ];
}

// ─────────────────────────────────────────────
//  App Text Styles
// ─────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayLarge => GoogleFonts.cairo(
    fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );

  static TextStyle get displayMedium => GoogleFonts.cairo(
    fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );

  static TextStyle get headlineLarge => GoogleFonts.cairo(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );

  static TextStyle get headlineMedium => GoogleFonts.cairo(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );

  static TextStyle get headlineSmall => GoogleFonts.cairo(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  static TextStyle get titleLarge => GoogleFonts.cairo(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => GoogleFonts.cairo(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => GoogleFonts.cairo(
    fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.cairo(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary,
  );

  static TextStyle get bodySmall => GoogleFonts.cairo(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
  );

  static TextStyle get labelLarge => GoogleFonts.cairo(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  static TextStyle get labelSmall => GoogleFonts.cairo(
    fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
  );
}

// ─────────────────────────────────────────────
//  App Theme
// ─────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      background: AppColors.background,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: GoogleFonts.cairo().fontFamily,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.headlineSmall,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),

    // Bottom Nav
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppTextStyles.titleMedium,
        elevation: 0,
      ),
    ),

    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppTextStyles.titleMedium,
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
    ),

    // Card
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 0,
    ),
  );
}

// ─────────────────────────────────────────────
//  App Dimensions
// ─────────────────────────────────────────────
class AppDimens {
  AppDimens._();

  static const double paddingXS   = 4.0;
  static const double paddingSM   = 8.0;
  static const double paddingMD   = 16.0;
  static const double paddingLG   = 24.0;
  static const double paddingXL   = 32.0;

  static const double radiusSM    = 8.0;
  static const double radiusMD    = 12.0;
  static const double radiusLG    = 16.0;
  static const double radiusXL    = 24.0;
  static const double radiusFull  = 100.0;

  static const double iconSM      = 16.0;
  static const double iconMD      = 24.0;
  static const double iconLG      = 32.0;

  static const double buttonHeight = 54.0;
  static const double navBarHeight = 64.0;
}