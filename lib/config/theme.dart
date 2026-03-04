import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Removed as we use custom asset font
import '../core/constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3:
          false, // Disabled to fix shader compilation error on Windows Web build
      scaffoldBackgroundColor: AppColors.ivory,
      primaryColor: AppColors.burgundy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.burgundy,
        background: AppColors.ivory,
        surface: AppColors.ivory,
        primary: AppColors.burgundy,
        secondary: AppColors.charcoal,
        onPrimary: AppColors.white,
        onSurface: AppColors.charcoal,
        onBackground: AppColors.charcoal,
      ),

      // Typography
      fontFamily: 'Pretendard', // Set default font family
      textTheme: const TextTheme(
        // Display/Headlines
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),

        // Titles
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.charcoal,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColors.charcoal,
        ),
        titleSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.charcoal,
        ),

        // Body
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.charcoal,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.charcoal,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.grey,
        ),
      ),

      // Component Themes
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ivory,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.charcoal),
        titleTextStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.charcoal,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.burgundy,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ivory,
        contentTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          color: AppColors.charcoal,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      ),
    );
  }
}
