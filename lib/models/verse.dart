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
    // JSON dosyası formatı (all_verses.json)
    final surahId = json['surah_id'] ?? 1;
    final verseNum = json['verse_id_in_surah'] ?? 1;
    final verseKey = '$surahId:$verseNum';
    
    // Arapça metin - "arabic_script" objesinden
    String textUthmani = '';
    if (json['arabic_script'] != null && json['arabic_script']['text'] != null) {
      textUthmani = json['arabic_script']['text'] ?? '';
    }
    
    // Türkçe meal - "translation" objesinden
    String translationTurkish = '';
    if (json['translation'] != null && json['translation']['text'] != null) {
      translationTurkish = json['translation']['text'] ?? '';
    }
    
    return Verse(
      id: (surahId * 1000) + verseNum, // Benzersiz ID oluştur
      verseNumber: verseNum,
      chapterId: surahId,
      verseKey: verseKey,
      textUthmani: textUthmani,
      translationTurkish: translationTurkish,
      pageNumber: json['page_number'] ?? 1,
      juzNumber: 1, // JSON'da juz bilgisi yok, varsayılan 1
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
  
  // Secde ayeti mi kontrol et
  bool isSajdahVerse() {
    // Secde ayetleri listesi (Sure ID : Ayet numarası)
    const sajdahVerses = {
      7: 206,   // A'râf
      13: 15,   // Ra'd
      16: 49,   // Nahl
      17: 107,  // İsrâ
      19: 58,   // Meryem
      22: 18,   // Hacc
      25: 60,   // Furkan
      27: 25,   // Neml
      32: 15,   // Secde
      38: 24,   // Sâd
      41: 37,   // Fussılet
      53: 62,   // Necm
      84: 21,   // İnşikak
      96: 19,   // Alâk
    };
    
    return sajdahVerses[chapterId] == verseNumber;
  }
}
