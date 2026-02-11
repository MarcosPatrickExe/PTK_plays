import 'package:flutter/material.dart';


class ThemeController extends ChangeNotifier {
  
  bool _isDark = false;
  bool get isDark => _isDark;
  ThemeMode get getThemeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDark = !_isDark;
    super.notifyListeners();
  }
}
