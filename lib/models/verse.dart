// Ayet (Verse) modeli
class Verse {
  final int id;
  final int verseNumber;
  final int chapterId;
  final String verseKey;
  final String textUthmani; // Arapça metin (Uthmani yazım)
  final String translationTurkish; // Türkçe meal
  final int pageNumber;
  final int juzNumber;

  Verse({
    required this.id,
    required this.verseNumber,
    required this.chapterId,
    required this.verseKey,
    required this.textUthmani,
    required this.translationTurkish,
    required this.pageNumber,
    required this.juzNumber,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    // Yeni API formatı (acikkuran.com)
    final surahId = json['surah_id'] ?? 1;
    final verseNum = json['verse_number'] ?? 1;
    final verseKey = '$surahId:$verseNum';
    
    // Arapça metin - "verse" field'ı (harekeli)
    String textUthmani = json['verse'] ?? '';
    
    // Türkçe meal - translation objesinden
    String translationTurkish = '';
    if (json['translation'] != null) {
      translationTurkish = json['translation']['text'] ?? '';
    }
    
    return Verse(
      id: json['id'] ?? 0,
      verseNumber: verseNum,
      chapterId: surahId,
      verseKey: verseKey,
      textUthmani: textUthmani,
      translationTurkish: translationTurkish,
      pageNumber: (json['page'] ?? 0) == 0 ? 1 : json['page'], // Fatiha için sayfa 0 -> 1'e çevir
      juzNumber: json['juz_number'] ?? 1,
    );
  }
  
  // Arapça rakamları döndür (ayet numarası için)
  String getArabicVerseNumber() {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return verseNumber
        .toString()
        .split('')
        .map((digit) => arabicDigits[int.parse(digit)])
        .join();
  }
}
