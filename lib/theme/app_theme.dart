import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.purple,
      secondary: Colors.pinkAccent,
      tertiary: Colors.tealAccent,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.purple.shade200,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple[400]!, 
      brightness: Brightness.dark,
      primary: Colors.deepPurple[300]!,
      secondary: Colors.indigo[300]!,
      surface: const Color(0xFF1E1E2E),
      background: const Color(0xFF151520), 
      error: Colors.red[400]!,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF2D2D3F), 
            foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    // Additional theme customizations for dark mode
    scaffoldBackgroundColor: const Color(0xFF151520),
    cardColor: const Color(0xFF1E1E2E),
    dividerColor: Colors.deepPurple[700]!.withOpacity(0.2),
  );
}