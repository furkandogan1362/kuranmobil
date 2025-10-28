import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema ayarlarını yöneten servis
class ThemeService {
  static const String _themeModeKey = 'theme_mode';
  
  /// Tema modları
  static const String themeModeLight = 'light';
  static const String themeModeDark = 'dark';
  static const String themeModeSystem = 'system';
  
  /// Mevcut tema modunu kaydet
  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
    print('🎨 Tema modu kaydedildi: $mode');
  }
  
  /// Kayıtlı tema modunu getir
  static Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? themeModeSystem;
  }
  
  /// String'i ThemeMode'a çevir
  static ThemeMode stringToThemeMode(String mode) {
    switch (mode) {
      case themeModeLight:
        return ThemeMode.light;
      case themeModeDark:
        return ThemeMode.dark;
      case themeModeSystem:
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }
  
  /// ThemeMode'u String'e çevir
  static String themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return themeModeLight;
      case ThemeMode.dark:
        return themeModeDark;
      case ThemeMode.system:
        return themeModeSystem;
    }
  }
  
  /// Açık tema renk şeması
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: Color(0xFF2E7D32),
      scaffoldBackgroundColor: Color(0xFFFAF8F3),
      colorScheme: ColorScheme.light(
        primary: Color(0xFF2E7D32),
        secondary: Color(0xFF43A047),
        surface: Colors.white,
        background: Color(0xFFFAF8F3),
        error: Color(0xFFD32F2F),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        onBackground: Colors.black87,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1a237e),
        elevation: 0,
      ),
      cardColor: Colors.white,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1a237e),
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
    );
  }
  
  /// Koyu tema renk şeması
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: Color(0xFF4CAF50),
      scaffoldBackgroundColor: Color(0xFF121212),
      colorScheme: ColorScheme.dark(
        primary: Color(0xFF4CAF50),
        secondary: Color(0xFF66BB6A),
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF121212),
        error: Color(0xFFCF6679),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white.withOpacity(0.95),
        onBackground: Colors.white.withOpacity(0.95),
        onError: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white.withOpacity(0.95),
        elevation: 0,
      ),
      cardColor: Color(0xFF1E1E1E),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4CAF50),
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.95),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white.withOpacity(0.95),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white.withOpacity(0.85),
        ),
      ),
    );
  }
}
