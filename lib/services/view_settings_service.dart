import 'package:shared_preferences/shared_preferences.dart';

/// Görünüm modu ayarlarını yöneten servis
class ViewSettingsService {
  static const String _viewModeKey = 'view_mode';
  
  // Görünüm modları
  static const String wideView = 'wide'; // Geniş görünüm (mevcut)
  static const String dynamicView = 'dynamic'; // Dinamik görünüm (yeni)
  
  // Varsayılan görünüm
  static const String defaultViewMode = dynamicView;
  
  /// Görünüm modunu kaydet
  static Future<void> saveViewMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewModeKey, mode);
    print('💾 Görünüm modu kaydedildi: $mode');
  }
  
  /// Görünüm modunu getir
  static Future<String> getViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_viewModeKey) ?? defaultViewMode;
  }
  
  /// Geniş görünüm mü kontrol et
  static Future<bool> isWideView() async {
    final mode = await getViewMode();
    return mode == wideView;
  }
  
  /// Dinamik görünüm mü kontrol et
  static Future<bool> isDynamicView() async {
    final mode = await getViewMode();
    return mode == dynamicView;
  }
}
