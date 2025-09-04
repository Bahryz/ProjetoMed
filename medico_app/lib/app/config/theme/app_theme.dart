import 'package:flutter/material.dart';

class AppTheme {
  // Cores base para o tema único
  static const Color primaryColor = Color(0xFFB89453); // Dourado
  static const Color accentColor = Color(0xFF4A4A4A);  // Cinza escuro (usado para texto secundário)
  static const Color cozyBlack = Color(0xFF121212);    // Preto aconchegante
  static const Color darkSurface = Color(0xFF1E1E1E);  // Cor para cards e superfícies

  // Tema Principal (Preto e Dourado)
  static final ThemeData mainTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: cozyBlack,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.white70),
      titleTextStyle: TextStyle(
        color: Color.fromRGBO(255, 255, 255, 0.87),
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: Colors.white70,
      indicatorColor: primaryColor,
    ),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor,
      surface: darkSurface,
    ),
  );
}

