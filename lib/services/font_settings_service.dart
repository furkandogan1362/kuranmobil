import 'package:shared_preferences/shared_preferences.dart';

/// Font boyutu ayarlarını yöneten servis
class FontSettingsService {
  static const String _arabicFontSizeKey = 'arabic_font_size';
  static const String _turkishFontSizeKey = 'turkish_font_size';
  
  // Varsayılan font boyutları
  static const double defaultArabicFontSize = 60.0;
  static const double defaultTurkishFontSize = 16.0;
  
  // Font boyutu aralıkları
  static const double minArabicFontSize = 24.0;
  static const double maxArabicFontSize = 80.0;
  static const double minTurkishFontSize = 12.0;
  static const double maxTurkishFontSize = 30.0;
  
  /// Arapça font boyutunu kaydet
  static Future<void> saveArabicFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_arabicFontSizeKey, size);
    print('💾 Arapça font boyutu kaydedildi: $size');
  }
  
  /// Türkçe font boyutunu kaydet
  static Future<void> saveTurkishFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_turkishFontSizeKey, size);
    print('💾 Türkçe font boyutu kaydedildi: $size');
  }
  
  /// Arapça font boyutunu getir
  static Future<double> getArabicFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_arabicFontSizeKey) ?? defaultArabicFontSize;
  }
  
  /// Türkçe font boyutunu getir
  static Future<double> getTurkishFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_turkishFontSizeKey) ?? defaultTurkishFontSize;
  }
  
  /// Ayarları sıfırla
  static Future<void> resetToDefaults() async {
    await saveArabicFontSize(defaultArabicFontSize);
    await saveTurkishFontSize(defaultTurkishFontSize);
    print('🔄 Font ayarları varsayılana sıfırlandı');
  }
}
