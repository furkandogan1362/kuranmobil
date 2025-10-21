// Sure (Chapter) modeli
class Chapter {
  final int id;
  final String nameArabic;
  final String nameSimple;
  final String nameTurkish;
  final int versesCount;
  final int revelationOrder;
  final String revelationPlace;
  final int pageStart;
  final int pageEnd;

  Chapter({
    required this.id,
    required this.nameArabic,
    required this.nameSimple,
    required this.nameTurkish,
    required this.versesCount,
    required this.revelationOrder,
    required this.revelationPlace,
    required this.pageStart,
    required this.pageEnd,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    // Yeni API formatı (acikkuran.com)
    return Chapter(
      id: json['id'] ?? 0,
      nameArabic: json['name_original'] ?? '',
      nameSimple: json['name'] ?? json['name_en'] ?? '',
      nameTurkish: json['name'] ?? '',
      versesCount: json['verse_count'] ?? 0,
      revelationOrder: 0, // Yeni API'de yok, default 0
      revelationPlace: '', // Yeni API'de yok
      pageStart: json['page_number'] ?? 1,
      pageEnd: json['page_number'] ?? 1, // Tek sayfa için aynı
    );
  }
}
