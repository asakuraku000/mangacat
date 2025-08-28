import 'package:flutter/material.dart';

class AppColors {
  // Color palette from user's specification
  static const Color primaryRed = Color(0xFFA22B25);
  static const Color accentOrange = Color(0xFFFC3F29);
  static const Color creamWhite = Color(0xFFF6E4CD);
  static const Color blueGray = Color(0xFF58787C);
  static const Color darkNavy = Color(0xFF101622);
  
  // Additional colors
  static const Color cardBackground = Color(0xFF1A1D29);
  static const Color surfaceColor = Color(0xFF212530);
  static const Color textPrimary = Color(0xFFF6E4CD);
  static const Color textSecondary = Color(0xFF58787C);
  static const Color errorColor = Color(0xFFFC3F29);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: _createMaterialColor(AppColors.primaryRed),
      scaffoldBackgroundColor: AppColors.creamWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: AppColors.creamWhite,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: _createMaterialColor(AppColors.primaryRed),
      scaffoldBackgroundColor: AppColors.darkNavy,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkNavy,
        foregroundColor: AppColors.creamWhite,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardBackground,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryRed,
        secondary: AppColors.accentOrange,
        surface: AppColors.surfaceColor,
        background: AppColors.darkNavy,
        error: AppColors.errorColor,
      ),
    );
  }

  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (double strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}