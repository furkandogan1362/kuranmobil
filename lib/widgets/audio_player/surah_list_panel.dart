import 'package:flutter/material.dart';
import '../../models/chapter.dart';
import '../../services/audio_service.dart';

/// Sure seçim listesi paneli
class SurahListPanel extends StatelessWidget {
  final List<Chapter>? allChapters;
  final int? currentSurah;
  final bool isDark;
  final ScrollController scrollController;
  final Map<int, Chapter> chapters;
  final AudioService audioService;
  final Function(Chapter) onChapterSelected;
  final VoidCallback onListClosed;

  const SurahListPanel({
    super.key,
    required this.allChapters,
    required this.currentSurah,
    required this.isDark,
    required this.scrollController,
    required this.chapters,
    required this.audioService,
    required this.onChapterSelected,
    required this.onListClosed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sureler',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '114 Sure',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Yükleniyor göstergesi veya liste
          allChapters == null
              ? _buildLoadingIndicator()
              : _buildSurahList(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF10B981),
              strokeWidth: 2,
            ),
            SizedBox(height: 8),
            Text(
              'Sureler yükleniyor...',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahList() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: 250, // Maksimum yükseklik
      ),
      child: ListView.builder(
        controller: scrollController,
        shrinkWrap: true,
        itemExtent: 50.0, // Her item'ın sabit yüksekliği
        itemCount: allChapters!.length,
        itemBuilder: (context, index) {
          final chapter = allChapters![index];
          final chapterId = chapter.id;
          final isCurrentSurah = currentSurah == chapterId;

          return _buildSurahListItem(chapter, chapterId, isCurrentSurah);
        },
      ),
    );
  }

  Widget _buildSurahListItem(Chapter chapter, int chapterId, bool isCurrentSurah) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleSurahTap(chapter, chapterId),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: isCurrentSurah
                ? LinearGradient(
                    colors: [
                      Color(0xFF10B981).withOpacity(0.2),
                      Color(0xFF059669).withOpacity(0.2),
                    ],
                  )
                : null,
            color: isCurrentSurah ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isCurrentSurah
                ? Border.all(
                    color: Color(0xFF10B981).withOpacity(0.5),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              // Sure numarası
              _buildSurahNumber(chapterId, isCurrentSurah),
              const SizedBox(width: 10),
              
              // Sure bilgileri
              _buildSurahInfo(chapter, isCurrentSurah),
              
              // Arapça sure adı
              Text(
                chapter.nameArabic,
                style: TextStyle(
                  fontFamily: 'ShaikhHamdullah',
                  fontSize: 14,
                  color: isCurrentSurah
                      ? Color(0xFF10B981)
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              
              if (isCurrentSurah) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.graphic_eq_rounded,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahNumber(int chapterId, bool isCurrentSurah) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isCurrentSurah
            ? Color(0xFF10B981)
            : (isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '$chapterId',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isCurrentSurah
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildSurahInfo(Chapter chapter, bool isCurrentSurah) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            chapter.nameTurkish,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isCurrentSurah ? FontWeight.bold : FontWeight.w600,
              color: isCurrentSurah
                  ? Color(0xFF10B981)
                  : (isDark ? Colors.white : Colors.black87),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${chapter.versesCount} Ayet',
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSurahTap(Chapter chapter, int chapterId) async {
    // 1. Listeyi kapat
    onListClosed();

    // 2. Callback ile parent'a bildir
    onChapterSelected(chapter);

    // 3. Kısa gecikme sonrası oynat
    await Future.delayed(Duration(milliseconds: 800));
    await audioService.playAyah(
      chapterId,
      1,
      totalAyahs: chapter.versesCount,
      chapters: chapters,
    );
  }
}
