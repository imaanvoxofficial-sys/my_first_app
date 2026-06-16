import 'package:flutter/material.dart';

class AppTheme {
  // الألوان الأساسية
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFF8B5CF6);

  // ألوان المكافآت
  static const Color gold = Color(0xFFF59E0B);
  static const Color success = Color(0xFF22C55E);

  // ألوان المنصات
  static const Color telegram = Color(0xFF229ED9);
  static const Color youtube = Color(0xFFFF0000);
  static const Color xColor = Color(0xFF111827);

  // الخلفيات
  static const Color background = Color(0xFFF8FAFC);
  static const Color card = Colors.white;

  // النصوص
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
    ),

    scaffoldBackgroundColor: background,

    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: textPrimary,
    ),

    cardTheme: const CardThemeData(
      color: card,
      elevation: 2,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}