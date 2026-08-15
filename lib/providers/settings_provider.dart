import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  // Onboarding state
  bool _isFirstLaunch = true;
  String _userName = '';
  String _assembly = '';
  String _section = 'C';

  // Theme state
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = const Color(0xFF1E88E5); // Default Blue 600

  bool get isFirstLaunch => _isFirstLaunch;
  String get userName => _userName;
  String get assembly => _assembly;
  String get section => _section;
  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    
    _isFirstLaunch = _prefs?.getBool('isFirstLaunch') ?? true;
    _userName = _prefs?.getString('userName') ?? '';
    _assembly = _prefs?.getString('assembly') ?? '';
    _section = _prefs?.getString('section') ?? 'C';

    final themeModeIndex = _prefs?.getInt('themeMode');
    if (themeModeIndex != null) {
      _themeMode = ThemeMode.values[themeModeIndex];
    }

    final colorValue = _prefs?.getInt('primaryColor');
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }

    notifyListeners();
  }

  Future<void> saveProfile(String name, String assembly, String section) async {
    _userName = name;
    _assembly = assembly;
    _section = section;
    _isFirstLaunch = false;

    if (_prefs != null) {
      await _prefs!.setString('userName', name);
      await _prefs!.setString('assembly', assembly);
      await _prefs!.setString('section', section);
      await _prefs!.setBool('isFirstLaunch', false);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    if (_prefs != null) {
      await _prefs!.setInt('themeMode', mode.index);
    }
    notifyListeners();
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    if (_prefs != null) {
      await _prefs!.setInt('primaryColor', color.toARGB32());
    }
    notifyListeners();
  }
}
