// Kur'an sayfası içeriğini oluşturan widget - sure başlıkları ve ayet kartları
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/chapter.dart';
import '../../../models/verse.dart';
import '../../../services/audio_service.dart';
import 'surah_header.dart';
import 'verse_card.dart';

class QuranPageContent extends StatelessWidget {
  final int pageNumber;
  final Chapter chapter;
  final List<Verse> verses;
  final double arabicFontSize;
  final double turkishFontSize;
  final ScrollController scrollController;
  final Map<int, GlobalKey> pageKeys;
  final Map<String, GlobalKey> verseKeys;
  final Map<int, Chapter> chapterCache;
  final int? scrollToChapterId;
  final VoidCallback? onScrollToChapterComplete;
  final Function(int pageNumber, int chapterId, int verseNumber) onScrollToPlayingVerse;

  const QuranPageContent({
    super.key,
    required this.pageNumber,
    required this.chapter,
    required this.verses,
    required this.arabicFontSize,
    required this.turkishFontSize,
    required this.scrollController,
    required this.pageKeys,
    required this.verseKeys,
    required this.chapterCache,
    this.scrollToChapterId,
    this.onScrollToChapterComplete,
    required this.onScrollToPlayingVerse,
  });

  @override
  Widget build(BuildContext context) {
    // Eğer hedef sure ID'si varsa ve bu sayfada varsa, scroll yap
    if (scrollToChapterId != null && pageKeys.containsKey(scrollToChapterId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = pageKeys[scrollToChapterId];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.0,
          );
          // Callback ile ana widget'ı bilgilendir
          onScrollToChapterComplete?.call();
        }
      });
    }

    // Sayfadaki ayetleri gruplara ayır (sure başlangıçlarına göre)
    List<Widget> pageContent = [];
    int? lastChapterId;

    for (var verse in verses) {
      // Yeni bir sure başladı mı kontrol et
      if (verse.chapterId != lastChapterId) {
        // Sure değişti
        if (verse.verseNumber == 1) {
          // Sure başlangıcı için GlobalKey oluştur (zaten parent tarafından oluşturulmuş)
          final key = pageKeys[verse.chapterId];
          final chapterInfo = chapterCache[verse.chapterId];
          final surahName = chapterInfo?.nameTurkish ?? 'Yükleniyor...';
          
          pageContent.add(
            Consumer<AudioService>(
              builder: (context, audioService, child) {
                // 0. ayet (sure adı + besmele) çalınıyor mu kontrol et
                final isPlayingZeroVerse = audioService.isAyahPlaying(verse.chapterId, 0);
                
                // 0. ayet çalınıyorsa scroll yap
                if (isPlayingZeroVerse) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onScrollToPlayingVerse(pageNumber, verse.chapterId, 0);
                  });
                }
                
                return SurahHeader(
                  key: key,
                  chapterId: verse.chapterId,
                  surahName: surahName,
                  showBesmele: true,
                  isPlaying: isPlayingZeroVerse,
                );
              },
            ),
          );
        }
        lastChapterId = verse.chapterId;
      }

      // Ayet için GlobalKey (zaten parent tarafından oluşturulmuş)
      final verseKeyId = '${verse.chapterId}_${verse.verseNumber}';
      final verseKey = verseKeys[verseKeyId];

      // Ayeti ekle
      pageContent.add(
        Consumer<AudioService>(
          builder: (context, audioService, child) {
            // Bu ayet çalınıyor mu kontrol et
            final isPlaying = audioService.isAyahPlaying(verse.chapterId, verse.verseNumber);
            
            // Çalan ayete otomatik scroll
            if (isPlaying) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                onScrollToPlayingVerse(pageNumber, verse.chapterId, verse.verseNumber);
              });
            }
            
            return VerseCard(
              key: verseKey,
              verse: verse,
              arabicFontSize: arabicFontSize,
              turkishFontSize: turkishFontSize,
              isPlaying: isPlaying,
              onDoubleTap: () async {
                // Çift tıklama ile ayet seslendirilsin
                final audioService = Provider.of<AudioService>(context, listen: false);
                
                // Mevcut sayfadaki tüm chapter'ları al
                final chapters = <int, Chapter>{};
                for (final v in verses) {
                  if (!chapters.containsKey(v.chapterId) && 
                      chapterCache.containsKey(v.chapterId)) {
                    chapters[v.chapterId] = chapterCache[v.chapterId]!;
                  }
                }
                
                // Ayeti çal
                await audioService.playAyah(
                  verse.chapterId,
                  verse.verseNumber,
                  totalAyahs: chapters[verse.chapterId]?.versesCount ?? 0,
                  chapters: chapters,
                  skipSurahName: verse.verseNumber != 1,
                );
              },
            );
          },
        ),
      );
    }

    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          ...pageContent,

          // Sayfa numarası (alt kısım)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              '$pageNumber',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
