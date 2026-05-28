// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Nautical dark theme
  static const navy = Color(0xFF0F172A);
  static const navyLight = Color(0xFF1E293B);
  static const teal = Color(0xFF2DD4BF);
  static const tealDark = Color(0xFF14B8A6);
  static const amber = Color(0xFFFBBF24);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF22C55E);
  static const white = Color(0xFFF8FAFC);
  static const grey = Color(0xFF64748B);
  static const greyDark = Color(0xFF334155);
}

ThemeData buildTheme() {
  const primary = AppColors.teal;
  const surface = AppColors.navy;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: AppColors.amber,
      surface: surface,
      onPrimary: AppColors.navy,
      onSecondary: AppColors.navy,
      onSurface: AppColors.white,
      error: AppColors.red,
    ),
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.navyLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: AppColors.navy,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.navyLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: AppColors.grey),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.w300,
        fontFamily: 'monospace',
        letterSpacing: 4,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(fontSize: 16, color: AppColors.grey),
    ),
  );
}
