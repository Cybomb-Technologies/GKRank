import 'package:flutter/material.dart';

//FF9F1C
//FFBF69
//FFFFFF
//CBF3F0
//2CBBAD

//FFBF69(0%) FF9F1C (100%) app logo color with gradient
//2EC4B6 app name color

class AppColors {
  // ==========================================
  // 1. CORE BRAND PALETTE (Constants)
  // ==========================================
  static const Color brandOrange = Color(0xFFFF9F1C);
  static const Color brandApricot = Color(0xFFFFBF69);
  static const Color brandWhite = Color(0xFFFFFFFF);
  static const Color brandMint = Color(0xFFCBF3F0);
  static const Color brandTeal = Color(
      0xFF2EC4B6); // Updated from user's preference for app name

  // Gradient for logo
  static const List<Color> logoGradient = [
    brandApricot,
    brandOrange,
  ];

  // ==========================================
  // 2. LIGHT THEME ROLES
  // ==========================================
  static const Color primary = brandTeal;
  static const Color onPrimary = brandWhite;
  static const Color primaryContainer = brandMint;
  static const Color onPrimaryContainer = Color(0xFF00201D);

  static const Color secondary = brandOrange;
  static const Color onSecondary = brandWhite;
  static const Color secondaryContainer = Color(0xFFFFDBCB);
  static const Color onSecondaryContainer = Color(0xFF341100);

  static const Color tertiary = brandApricot;
  static const Color onTertiary = brandWhite;
  static const Color tertiaryContainer = Color(0xFFFFEBD6);
  static const Color onTertiaryContainer = Color(0xFF2B1700);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Colors.white;
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color background = brandWhite;
  static const Color onBackground = Color(0xFF00201D);

  static const Color surface = brandWhite;
  static const Color onSurface = Color(0xFF00201D);

  static const Color surfaceVariant = brandMint;
  static const Color onSurfaceVariant = Color(0xFF3F4947);

  static const Color outline = Color(0xFF6F7977);
  static const Color outlineVariant = Color(0xFFBEC9C6);

  // ==========================================
  // 3. DARK THEME ROLES
  // ==========================================
  static const Color primaryDark = Color(0xFF4FDAD0);
  static const Color onPrimaryDark = Color(0xFF003733);
  static const Color primaryContainerDark = Color(0xFF00504B);
  static const Color onPrimaryContainerDark = brandMint;

  static const Color secondaryDark = brandOrange;
  static const Color onSecondaryDark = Color(0xFF4D2700);
  static const Color secondaryContainerDark = Color(0xFF6E3900);
  static const Color onSecondaryContainerDark = Color(0xFFFFDBCB);

  static const Color tertiaryDark = brandApricot;
  static const Color onTertiaryDark = Color(0xFF482900);
  static const Color tertiaryContainerDark = Color(0xFF673D00);
  static const Color onTertiaryContainerDark = Color(0xFFFFEBD6);

  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color onErrorDark = Color(0xFF690005);
  static const Color errorContainerDark = Color(0xFF93000A);
  static const Color onErrorContainerDark = Color(0xFFFFDAD6);

  static const Color backgroundDark = Color(0xFF191C1C);
  static const Color onBackgroundDark = Color(0xFFE0E3E1);

  static const Color surfaceDark = Color(0xFF191C1C);
  static const Color onSurfaceDark = Color(0xFFE0E3E1);

  static const Color surfaceVariantDark = Color(0xFF3F4947);
  static const Color onSurfaceVariantDark = Color(0xFFBEC9C6);

  static const Color outlineDark = Color(0xFF899391);
  static const Color outlineVariantDark = Color(0xFF3F4947);

}