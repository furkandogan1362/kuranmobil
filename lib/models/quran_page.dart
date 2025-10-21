import 'verse.dart';

// Kuran sayfası modeli
class QuranPage {
  final int pageNumber;
  final List<Verse> verses;
  final int chapterId;
  final String chapterNameArabic;
  final String chapterNameTurkish;

  QuranPage({
    required this.pageNumber,
    required this.verses,
    required this.chapterId,
    required this.chapterNameArabic,
    required this.chapterNameTurkish,
  });
}
