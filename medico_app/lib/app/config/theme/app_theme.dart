// medico_app/lib/app/config/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFD4AF37);
  static const Color accentColor = Color(0xFFFFD700);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color textColor = Colors.white;
  static const Color textColorSlightlyFaded = Color(0xFFE0E0E0);
  static const Color hintColor = Colors.grey;

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: textColor,
      error: Colors.redAccent,
      onError: Colors.white,
    ),

    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme.apply(
          bodyColor: textColorSlightlyFaded,
          displayColor: textColor,
        )),

    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 1,
      centerTitle: true,
      iconTheme: const IconThemeData(color: primaryColor),
      titleTextStyle: GoogleFonts.poppins(
        color: primaryColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: primaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ))),

    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ))),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: TextStyle(color: hintColor.withAlpha(204)),
      hintStyle: TextStyle(color: hintColor.withAlpha(204)),
      prefixIconColor: hintColor,
    ),
    
    // CORREÇÃO FINAL AQUI
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 4,
      shadowColor: const Color.fromRGBO(0, 0, 0, 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // E AQUI
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
    ),

    iconTheme: const IconThemeData(color: textColorSlightlyFaded),

    listTileTheme: const ListTileThemeData(
      iconColor: primaryColor,
    )
  );
}