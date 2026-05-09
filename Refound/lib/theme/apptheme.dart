import 'package:flutter/material.dart';

class AppColors {
  static const navy       = Color(0xFF0A1628);
  static const navyMid    = Color(0xFF112240);
  static const navyLight  = Color(0xFF1B3A6B);
  static const teal       = Color(0xFF14B8A6);
  static const tealLight  = Color(0xFFCCFBF1);
  static const surface    = Color(0xFFF4F7FF);
  static const white      = Color(0xFFFFFFFF);
  static const textPrimary   = Color(0xFF0A1628);
  static const textSecondary = Color(0xFF64748B);
  static const border     = Color(0xFFE2E8F0);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: const ColorScheme.light(
          primary: AppColors.teal,
          onPrimary: Colors.white,
          surface: AppColors.surface,
        ),
     
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: AppColors.border, width: 1.5),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      );
}