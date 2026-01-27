import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // ==========================================
  // LIGHT THEME
  // ==========================================
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      background: AppColors.background,
      onBackground: AppColors.onBackground,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceVariant: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      appBarTheme: _appBarTheme(colorScheme),
      cardTheme: _cardThemeData(),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      textTheme: _textTheme(colorScheme.onSurface),
      scaffoldBackgroundColor: colorScheme.background,
    );
  }

  static ThemeData get darkTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      primaryContainer: AppColors.primaryContainerDark,
      onPrimaryContainer: AppColors.onPrimaryContainerDark,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.onSecondaryDark,
      secondaryContainer: AppColors.secondaryContainerDark,
      onSecondaryContainer: AppColors.onSecondaryContainerDark,
      tertiary: AppColors.tertiaryDark,
      onTertiary: AppColors.onTertiaryDark,
      tertiaryContainer: AppColors.tertiaryContainerDark,
      onTertiaryContainer: AppColors.onTertiaryContainerDark,
      error: AppColors.errorDark,
      onError: AppColors.onErrorDark,
      background: AppColors.backgroundDark,
      onBackground: AppColors.onBackgroundDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      surfaceVariant: AppColors.surfaceVariantDark,
      onSurfaceVariant: AppColors.onSurfaceVariantDark,
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.outlineVariantDark,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      appBarTheme: _appBarTheme(colorScheme),
      cardTheme: _cardThemeData(),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      textTheme: _textTheme(colorScheme.onSurface),
      scaffoldBackgroundColor: colorScheme.background,
    );
  }

  static AppBarTheme _appBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  static CardThemeData _cardThemeData() {
    return CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.transparent),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
    );
  }

  static TextTheme _textTheme(Color onSurface) {
    return TextTheme(
      headlineLarge: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 32),
      headlineMedium: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 24),
      headlineSmall: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 20),
      bodyLarge: TextStyle(color: onSurface, fontSize: 16),
      bodyMedium: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 14),
      labelLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
