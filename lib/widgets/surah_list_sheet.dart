import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chapter.dart';
import '../services/quran_json_service.dart';
import '../utils/search_helper.dart';

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
  final TextEditingController _searchController = TextEditingController();
  List<Chapter>? _chapters;
  List<Chapter>? _filteredChapters;
  bool _isSearching = false;
  double _savedScrollPosition = 0.0; // Orijinal scroll pozisyonu
  
  // SharedPreferences key
  static const String _lastSurahIndexKey = 'lastSurahIndex';
  
  // Sabit item yüksekliği
  static const double _itemExtent = 72.0;

  @override
  void initState() {
    super.initState();
    _loadChapters();
    _searchController.addListener(_onSearchChanged);
  }
  
  // Arama değiştiğinde
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    setState(() {
      // Arama başlarken mevcut scroll pozisyonunu kaydet
      if (!_isSearching && query.isNotEmpty && _scrollController.hasClients) {
        _savedScrollPosition = _scrollController.offset;
      }
      
      _isSearching = query.isNotEmpty;
      
      if (query.isEmpty) {
        _filteredChapters = null;
        // Arama temizlendiğinde orijinal pozisyona dön
        _restoreScrollPosition();
      } else {
        _filteredChapters = _chapters?.where((chapter) {
          // Sayısal arama: "8" yazınca 8, 18, 28, 38, 48, 58, 68, 78, 88, 98, 108
          if (SearchHelper.matchesNumber(query, chapter.id)) {
            return true;
          }
          
          // Sure ismiyle arama (Türkçe karakterlere duyarlı)
          if (SearchHelper.matchesText(query, chapter.nameTurkish)) {
            return true;
          }
          
          // Arapça isimle arama (direkt)
          if (chapter.nameArabic.contains(query)) {
            return true;
          }
          
          return false;
        }).toList();
        
        // Arama sonuçları varsa scroll'u en başa getir
        _scrollToTop();
      }
    });
  }
  
  // Scroll'u en başa getir (animasyonlu)
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }
  
  // Orijinal scroll pozisyonuna dön (animasyonlu)
  void _restoreScrollPosition() {
    if (_scrollController.hasClients && _savedScrollPosition > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _savedScrollPosition,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, draggableScrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF302F30) : Colors.white,
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
                    colors: isDark
                        ? [
                            Color(0xFF2E7D32),
                            Color(0xFF388E3C),
                          ]
                        : [
                            Color(0xFF1a237e),
                            Color(0xFF283593),
                          ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
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
                    
                    // Arama kutusu
                    SizedBox(height: 16),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Color(0xFF3A393A) 
                            : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          fontSize: 15,
                          color: isDark ? Colors.white.withOpacity(0.95) : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Sure adı veya sure numarası ile ara...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF2E7D32),
                            size: 22,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    
                    // Sonuç sayısı
                    if (_isSearching && _filteredChapters != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          _filteredChapters!.isEmpty
                              ? 'Sonuç bulunamadı'
                              : '${_filteredChapters!.length} sure bulundu',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                    : _isSearching && _filteredChapters != null && _filteredChapters!.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Aradığınız sure bulunamadı',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.white.withOpacity(0.7) : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Farklı bir arama deneyin',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.zero,
                            itemExtent: _itemExtent,
                            itemCount: (_isSearching && _filteredChapters != null) 
                                ? _filteredChapters!.length 
                                : _chapters!.length,
                            itemBuilder: (context, index) {
                              final chapter = (_isSearching && _filteredChapters != null)
                                  ? _filteredChapters![index]
                                  : _chapters![index];
                              final isCurrentChapter = chapter.id == widget.currentChapterId;
                              final actualIndex = _chapters!.indexWhere((c) => c.id == chapter.id);
                              return _buildSurahListItem(chapter, isCurrentChapter, actualIndex, isDark);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSurahListItem(Chapter chapter, bool isCurrentChapter, int index, bool isDark) {
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
          color: isCurrentChapter ? null : (isDark ? Color(0xFF3A393A) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentChapter 
                ? Color(0xFF2E7D32).withOpacity(0.5)
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
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
                                ? Color(0xFF2E7D32)
                                : (isDark ? Colors.white.withOpacity(0.95) : Colors.black87),
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
                              : (isDark ? Colors.white.withOpacity(0.95) : Color(0xFF1a237e)),
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
                            : (isDark ? Colors.white.withOpacity(0.5) : Colors.black45),
                      ),
                      SizedBox(width: 3),
                      Text(
                        '${chapter.versesCount} Ayet',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrentChapter ? FontWeight.w600 : FontWeight.normal,
                          color: isCurrentChapter
                              ? Color(0xFF2E7D32)
                              : (isDark ? Colors.white.withOpacity(0.6) : Colors.black54),
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.book_outlined,
                        size: 12,
                        color: isCurrentChapter
                            ? Color(0xFF2E7D32)
                            : (isDark ? Colors.white.withOpacity(0.5) : Colors.black45),
                      ),
                      SizedBox(width: 3),
                      Text(
                        'Sayfa ${chapter.pageStart}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isCurrentChapter ? FontWeight.w600 : FontWeight.normal,
                          color: isCurrentChapter
                              ? Color(0xFF2E7D32)
                              : (isDark ? Colors.white.withOpacity(0.6) : Colors.black54),
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
                  : (isDark ? Colors.white.withOpacity(0.3) : Colors.black26),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

