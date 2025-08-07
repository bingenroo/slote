import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static bool _initialDarkMode = false;
  bool _isDarkMode = _initialDarkMode;

  bool get isDarkMode => _isDarkMode;

  // Static method to initialize theme before app starts
  static Future<void> initializeTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _initialDarkMode = prefs.getBool('isDarkMode') ?? false;
    } catch (e) {
      _initialDarkMode = false;
    }
  }

  ThemeProvider() {
    _isDarkMode = _initialDarkMode;
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      notifyListeners();
    } catch (e) {
      // Handle the error gracefully - use default light mode
      // print('Error loading theme preference: $e');
      _isDarkMode = false;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      notifyListeners();
    } catch (e) {
      // Handle the error gracefully
      // print('Error saving theme preference: $e');
      // Still update the UI state even if saving fails
      notifyListeners();
    }
  }
}
