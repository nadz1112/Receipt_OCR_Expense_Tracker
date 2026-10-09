import 'package:flutter/material.dart';

/// VKU Expense Tracker - Material 3 Theme Configuration
/// Seed Color: 0xFF2C4570 (VKU Navy Blue)
class AppTheme {
  AppTheme._(); // Prevent instantiation

  /// Primary VKU Navy seed color
  static const Color _seedColor = Color(0xFF2C4570);

  /// Light theme configuration using Material 3 color scheme seeding
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
        // Card theming with rounded corners
        cardTheme: const CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        // AppBar styling
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF2C4570),
          foregroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
        // Bottom navigation bar theming
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: const Color(0xFF2C4570).withOpacity(0.15),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        // Input decoration theming
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        // Typography
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(letterSpacing: 0.1),
          labelLarge: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  /// Dark theme configuration using Material 3 color scheme seeding
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        cardTheme: const CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      );

  /// Category color mapping for consistent visual categorization
  static Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'ăn uống':
      case 'an uong':
        return const Color(0xFFE57373); // Red
      case 'transport':
      case 'di chuyển':
      case 'di chuyen':
        return const Color(0xFF64B5F6); // Blue
      case 'shopping':
      case 'mua sắm':
      case 'mua sam':
        return const Color(0xFFBA68C8); // Purple
      case 'utilities':
      case 'hóa đơn':
      case 'hoa don':
        return const Color(0xFF4DB6AC); // Teal
      case 'entertainment':
      case 'giải trí':
      case 'giai tri':
        return const Color(0xFFFFB74D); // Orange
      default:
        return const Color(0xFF90A4AE); // Grey fallback
    }
  }

  /// Category icon mapping
  static IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'ăn uống':
      case 'an uong':
        return Icons.restaurant_rounded;
      case 'transport':
      case 'di chuyển':
      case 'di chuyen':
        return Icons.directions_car_rounded;
      case 'shopping':
      case 'mua sắm':
      case 'mua sam':
        return Icons.shopping_bag_rounded;
      case 'utilities':
      case 'hóa đơn':
      case 'hoa don':
        return Icons.bolt_rounded;
      case 'entertainment':
      case 'giải trí':
      case 'giai tri':
        return Icons.movie_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}
