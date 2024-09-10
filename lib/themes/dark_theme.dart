import 'package:flutter/material.dart';

final ThemeData darkUberTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF1C1C1E),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF1C1C1E),
    secondary: Color(0xFFE5E5E5),
  ),
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    color: Color(0xFF1C1C1E),
    elevation: 2,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
        color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(
        color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
    displaySmall: TextStyle(
        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
    bodyMedium: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1C1C1E),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[600]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: const Color(0xFFE5E5E5),
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  primaryIconTheme: const IconThemeData(color: Colors.white),
);
