// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.latoTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark, // Important for a consistent dark palette
    ),
    textTheme: GoogleFonts.latoTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
  );
}