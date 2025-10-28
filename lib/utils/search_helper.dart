/// Sure arama işlemleri için yardımcı sınıf
class SearchHelper {
  /// Türkçe karakterleri normalize et (şapkasız hale getir)
  /// Örnek: "Şûrâ" -> "sura", "A'râf" -> "araf"
  static String normalizeTurkish(String text) {
    const turkish = 'çğıİöşüÇĞÖŞÜâîûÂÎÛ';
    const normalized = 'cgiiösuCGOSUaiuAIU';
    
    String result = text.toLowerCase();
    for (int i = 0; i < turkish.length; i++) {
      result = result.replaceAll(turkish[i].toLowerCase(), normalized[i].toLowerCase());
    }
    // Özel karakterleri temizle (apostrof, tire vb.)
    result = result.replaceAll(RegExp(r'[^\w\s]'), '');
    return result.trim();
  }
  
  /// Sayısal arama kontrolü yapar
  /// Kullanıcı "8" yazdığında: 8, 18, 28, 38, ..., 98, 108 gibi
  /// tüm sure numaralarını içeren sonuçları döner
  static bool matchesNumber(String query, int surahId) {
    // Sadece sayısal arama için
    if (!_isNumeric(query)) return false;
    
    // Sure ID'si arama metnini içeriyorsa eşleşme var
    return surahId.toString().contains(query);
  }
  
  /// Metin sayısal mı kontrol eder
  static bool _isNumeric(String str) {
    return int.tryParse(str) != null;
  }
  
  /// Tam metin araması yapar (Türkçe karakterlere duyarlı)
  static bool matchesText(String query, String surahName) {
    final normalizedQuery = normalizeTurkish(query);
    final normalizedName = normalizeTurkish(surahName);
    
    return normalizedName.contains(normalizedQuery);
  }
}
