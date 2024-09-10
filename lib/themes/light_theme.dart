import 'package:flutter/material.dart';

final ThemeData lightUberTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color.fromARGB(255, 4, 107, 141),
  colorScheme: const ColorScheme.light(
    primary: Color.fromARGB(255, 4, 107, 141),
    secondary: Color(0xFF1C1C1E),
    onPrimary: Colors.white, // Color del texto sobre el color primario
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    color: Color.fromARGB(255, 4, 107, 141),
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
        color: Color(0xFF1C1C1E), fontSize: 34, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(
        color: Color(0xFF1C1C1E), fontSize: 26, fontWeight: FontWeight.w700),
    displaySmall: TextStyle(
        color: Color(0xFF1C1C1E), fontSize: 22, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(
        color: Color(0xFF1C1C1E), fontSize: 20, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(color: Color(0xFF1C1C1E), fontSize: 18),
    bodyMedium: TextStyle(color: Color(0xFF3E3E3E), fontSize: 16),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFE5E5E5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color.fromARGB(255, 4, 107, 141)),
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: const Color.fromARGB(255, 4, 107, 141),
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  primaryIconTheme: const IconThemeData(color: Colors.white),
);
