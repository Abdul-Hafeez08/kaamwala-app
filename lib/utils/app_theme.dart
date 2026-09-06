import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryOrange = Color(0xFFFF9800); // Main Orange
  static const Color accentOrange = Color(0xFFFFB74D);
  static const Color black = Color(0xFF121212);
  static const Color white = Color(0xFFFFFFFF);
  static const Color greyDark = Color(0xFF1E1E1E);
  static const Color greyLight = Color(0xFFF5F5F5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: white,
      colorScheme: const ColorScheme.light(
        primary: primaryOrange,
        secondary: black,
        surface: white,
        onPrimary: white,
        onSecondary: white,
        onSurface: black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: white,
          overlayColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: greyLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIconColor: Colors.grey,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: black, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: black, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: black, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: black),
        bodyMedium: TextStyle(color: Colors.black87),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: black,
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        secondary: accentOrange,
        surface: greyDark,
        onPrimary: white,
        onSecondary: black,
        onSurface: white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: black,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: greyDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: black,
          overlayColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: greyDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIconColor: Colors.grey,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: white, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: white, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: white, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }
}
