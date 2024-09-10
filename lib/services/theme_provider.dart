import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool isDarkMode =
      false; // Por defecto, se usará el diseño actual (considerado "claro")

  void setTheme(bool isDark) {
    isDarkMode = isDark;
    notifyListeners();
  }
}
