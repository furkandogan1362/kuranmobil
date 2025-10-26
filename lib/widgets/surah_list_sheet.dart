import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chapter.dart';
import '../services/quran_json_service.dart';

class SurahListSheet extends StatefulWidget {
  final int currentChapterId;
  final Function(int pageNumber, int chapterId) onSurahSelected;

  const SurahListSheet({
    super.key,
    required this.currentChapterId,
    required this.onSurahSelected,
  });

  @override
  State<SurahListSheet> createState() => _SurahListSheetState();
}

class _SurahListSheetState extends State<SurahListSheet> {
  final QuranJsonService _jsonService = QuranJsonService();
  final ScrollController _scrollController = ScrollController();
  List<Chapter>? _chapters;
  
  // SharedPreferences key
  static const String _lastSurahIndexKey = 'lastSurahIndex';
  
  // Sabit item yüksekliği
  static const double _itemExtent = 72.0;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    List<Chapter> chapters = [];
    for (int i = 1; i <= 114; i++) {
      try {
        final chapter = await _jsonService.getChapterFromCache(i);
        chapters.add(chapter);
      } catch (e) {
        print('Sure $i yüklenirken hata: $e');
      }
    }

    setState(() {
      _chapters = chapters;
    });

    // Widget build edildikten sonra scroll pozisyonunu ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentSurah();
    });
  }

  // Mevcut surenin pozisyonuna git (currentChapterId kullanarak)
  void _scrollToCurrentSurah() {
    if (!_scrollController.hasClients || _chapters == null) return;
    
    try {
      // currentChapterId'ye karşılık gelen index'i bul (ID 1'den başlar, index 0'dan)
      final currentIndex = widget.currentChapterId - 1;
      
      if (currentIndex >= 0 && currentIndex < _chapters!.length) {
        // Seçili surenin biraz üstünden başlat (başlığa yapışık olması için)
        final targetIndex = currentIndex - 2;
        final position = (targetIndex > 0 ? targetIndex * _itemExtent : 0.0).toDouble();
        
        // Max scroll pozisyonunu kontrol et
        final maxScroll = _scrollController.position.maxScrollExtent;
        final finalPosition = position > maxScroll ? maxScroll : position;
        
        print('📜 Mevcut sure ID: ${widget.currentChapterId}, Index: $currentIndex, Scroll pozisyonu: $finalPosition');
        
        _scrollController.jumpTo(finalPosition);
      }
    } catch (e) {
      print('❌ Scroll pozisyonu hatası: $e');
    }
  }
  
  // Seçilen surenin index'ini kaydet (0'dan başlayan)
  Future<void> _saveSelectedSurahIndex(int chapterIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSurahIndexKey, chapterIndex);
      print('💾 Sure index kaydedildi: $chapterIndex (${chapterIndex + 1}. sure)');
    } catch (e) {
      print('❌ Sure index kaydetme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, draggableScrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Başlık
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1a237e),
                      Color(0xFF283593),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sureler',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Sure listesi
              Expanded(
                child: _chapters == null
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2E7D32),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.zero, // Boşlukları kaldır
                        itemExtent: _itemExtent, // Sabit yükseklik
                        itemCount: _chapters!.length,
                        itemBuilder: (context, index) {
                          final chapter = _chapters![index];
                          final isCurrentChapter = chapter.id == widget.currentChapterId;
                          return _buildSurahListItem(chapter, isCurrentChapter, index);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSurahListItem(Chapter chapter, bool isCurrentChapter, int index) {
    return InkWell(
      onTap: () async {
        // Seçilen surenin index'ini kaydet (0'dan başlayan)
        await _saveSelectedSurahIndex(index);
        
        // Bottom sheet'i kapat ve sayfaya git (sure ID'sini de gönder)
        Navigator.pop(context);
        widget.onSurahSelected(chapter.pageStart, chapter.id);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isCurrentChapter
              ? LinearGradient(
                  colors: [
                    Color(0xFF2E7D32).withOpacity(0.15),
                    Color(0xFF388E3C).withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isCurrentChapter ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentChapter 
                ? Color(0xFF2E7D32).withOpacity(0.5)
                : Colors.grey.shade200,
            width: isCurrentChapter ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCurrentChapter
                  ? Color(0xFF2E7D32).withOpacity(0.15)
                  : Colors.black.withOpacity(0.03),
              blurRadius: isCurrentChapter ? 12 : 8,
              offset: Offset(0, isCurrentChapter ? 4 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Sure numarası
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCurrentChapter
                      ? [
                          Color(0xFF2E7D32),
                          Color(0xFF43A047),
                        ]
                      : [
                          Color(0xFF2E7D32).withOpacity(0.7),
                          Color(0xFF388E3C).withOpacity(0.7),
                        ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isCurrentChapter
                    ? [
                        BoxShadow(
                          color: Color(0xFF2E7D32).withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${chapter.id}',
                  style: TextStyle(
                    fontSize: isCurrentChapter ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(width: 12),

            // Sure bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sure adı (Türkçe ve Arapça)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chapter.nameTurkish,
                          style: TextStyle(
                            fontSize: isCurrentChapter ? 15 : 14,
                            fontWeight: isCurrentChapter ? FontWeight.w700 : FontWeight.bold,
                            color: isCurrentChapter
                                ? Color(0xFF1a237e)
                                : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        chapter.nameArabic,
                        style: TextStyle(
                          fontFamily: 'ShaikhHamdullah',
                          fontSize: isCurrentChapter ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentChapter
                              ? Color(0xFF2E7D32)
                              : Color(0xFF1a237e),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 2),

                  // Ayet sayısı ve sayfa numarası
                  Row(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 12,
                        color: isCurrentChapter
                            ? Color(0xFF2E7D32)
                            : Colors.black45,
                      ),
                      SizedBox(width: 3),
                      Text(
                        '${chapter.versesCount} Ayet',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrentChapter ? FontWeight.w600 : FontWeight.normal,
                          color: isCurrentChapter
                              ? Color(0xFF2E7D32)
                              : Colors.black54,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.book_outlined,
                        size: 12,
                        color: isCurrentChapter
                            ? Color(0xFF2E7D32)
                            : Colors.black45,
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Sayfa ${chapter.pageStart}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrentChapter ? FontWeight.w600 : FontWeight.normal,
                          color: isCurrentChapter
                              ? Color(0xFF2E7D32)
                              : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ok işareti
            Icon(
              isCurrentChapter ? Icons.play_arrow_rounded : Icons.arrow_forward_ios,
              size: isCurrentChapter ? 24 : 14,
              color: isCurrentChapter
                  ? Color(0xFF2E7D32)
                  : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

