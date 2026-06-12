import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
//===============
class SwitchmodeProvider extends ChangeNotifier {
ThemeMode _themeMode = ThemeMode.light;
ThemeMode get themeMode => _themeMode;
bool get isDarkMode => _themeMode == ThemeMode.dark;
SwitchmodeProvider() {
_loadTheme();
}
//===============
Future<void> _loadTheme() async {
final prefs = await SharedPreferences.getInstance();
final savedTheme = prefs.getString('theme');
if (savedTheme == 'dark') {
_themeMode = ThemeMode.dark;
} else {
_themeMode = ThemeMode.light;
}
notifyListeners();
}
//===============
Future<void> toggleTheme() async {
final prefs = await SharedPreferences.getInstance();
if (_themeMode == ThemeMode.dark) {
_themeMode = ThemeMode.light;
await prefs.setString('theme', 'light');
} else {
_themeMode = ThemeMode.dark;
await prefs.setString('theme', 'dark');
}
notifyListeners();
}
}
