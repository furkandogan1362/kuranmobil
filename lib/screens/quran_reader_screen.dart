import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chapter.dart';
import '../models/verse.dart';
import '../services/quran_api_service.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final QuranApiService _apiService = QuranApiService();
  final PageController _pageController = PageController(initialPage: 0);
  final ScrollController _paginationScrollController = ScrollController();
  
  static const int totalPages = 604; // Kuran'ın toplam sayfa sayısı
  
  Map<int, List<Verse>> _pageVerses = {}; // Sayfa numarası -> Ayetler
  Map<int, Chapter> _pageChapters = {}; // Sayfa numarası -> Sure bilgisi
  int _currentPage = 1; // 1'den başlıyor
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialPage();
  }

  Future<void> _loadInitialPage() async {
    await _loadPageData(1);
    // İlk birkaç sayfayı önceden yükle
    _loadPageData(2);
    _loadPageData(3);
  }

  Future<void> _loadPageData(int pageNumber) async {
    if (_pageVerses.containsKey(pageNumber)) {
      return; // Zaten yüklü
    }

    try {
      if (pageNumber == 1 && _isLoading) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      // Sayfa ayetlerini çek
      final verses = await _apiService.getVersesByPage(pageNumber);
      
      // Bu sayfadaki ilk ayetin suresini bul (cache'den)
      if (verses.isNotEmpty) {
        final chapterId = verses[0].chapterId;
        final chapter = await _apiService.getChapterFromCache(chapterId);
        
        setState(() {
          _pageVerses[pageNumber] = verses;
          _pageChapters[pageNumber] = chapter;
          if (pageNumber == 1) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (pageNumber == 1) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Veriler yüklenirken hata oluştu: $e';
        });
      }
      print('Sayfa $pageNumber yüklenirken hata: $e');
    }
  }

  void _onPageChanged(int index) {
    final pageNumber = index + 1; // Index 0'dan başlar, sayfa 1'den
    setState(() {
      _currentPage = pageNumber;
    });

    // Mevcut sayfayı yükle
    _loadPageData(pageNumber);
    
    // Önceki ve sonraki sayfaları önceden yükle
    if (pageNumber > 1) {
      _loadPageData(pageNumber - 1);
    }
    if (pageNumber < totalPages) {
      _loadPageData(pageNumber + 1);
    }
    if (pageNumber + 1 < totalPages) {
      _loadPageData(pageNumber + 2);
    }

    // Pagination scroll pozisyonunu güncelle
    _scrollPaginationToPage(pageNumber);
  }

  void _scrollPaginationToPage(int pageNumber) {
    if (_paginationScrollController.hasClients) {
      final position = (pageNumber - 1) * 52.0; // Her item 48px + 4px margin
      _paginationScrollController.animateTo(
        position,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int pageNumber) {
    _pageController.animateToPage(
      pageNumber - 1, // PageView index 0'dan başlar
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1a237e),
                Color(0xFF0d47a1),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                SizedBox(height: 24),
                Text(
                  'Kur\'an-ı Kerim yükleniyor...',
                  style: GoogleFonts.notoSans(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ).animate()
              .fadeIn(duration: 600.ms)
              .scale(delay: 200.ms),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1a237e),
                Color(0xFF0d47a1),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white70,
                  ),
                  SizedBox(height: 24),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadInitialPage,
                    icon: Icon(Icons.refresh),
                    label: Text('Tekrar Dene'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFAF8F3),
              Color(0xFFF5F1E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Sabit başlık ve pagination
              _buildFixedHeader(),
              
              // Ana içerik - Sayfalar arası kaydırma
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: totalPages,
                  reverse: true, // Sağdan sola kaydırma için
                  itemBuilder: (context, index) {
                    final pageNumber = index + 1;
                    final verses = _pageVerses[pageNumber];
                    final chapter = _pageChapters[pageNumber];
                    
                    if (verses == null || chapter == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF2E7D32),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Sayfa $pageNumber yükleniyor...',
                              style: GoogleFonts.notoSans(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return _buildQuranPage(pageNumber, chapter, verses);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedHeader() {
    final chapter = _pageChapters[_currentPage];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Geri butonu ve sure adı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Color(0xFF1a237e)),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        chapter?.nameArabic ?? '...',
                        style: GoogleFonts.amiriQuran(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a237e),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        chapter?.nameTurkish ?? 'Yükleniyor...',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sayfa $_currentPage',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 48), // Dengeli görünüm için
              ],
            ),
          ),
          
          // Horizontal pagination (tüm Kuran sayfaları)
          Container(
            height: 60,
            child: ListView.builder(
              controller: _paginationScrollController,
              scrollDirection: Axis.horizontal,
              reverse: true, // Sağdan sola
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: totalPages,
              itemBuilder: (context, index) {
                final pageNum = index + 1;
                final isSelected = pageNum == _currentPage;
                return GestureDetector(
                  onTap: () => _goToPage(pageNum),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 44,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Color(0xFF2E7D32) 
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(0xFF2E7D32).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$pageNum',
                        style: GoogleFonts.notoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ).animate(
                    key: ValueKey('page_$pageNum'),
                  ).scale(
                    duration: 200.ms,
                    curve: Curves.easeOut,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuranPage(int pageNumber, Chapter chapter, List<Verse> verses) {
    // Besmele sabiti (Türk alfabesi formatı - API'den gelen)
    const besmele = 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ';
    
    // Sayfadaki ayetleri gruplara ayır (sure başlangıçlarına göre)
    List<Widget> pageContent = [];
    int? lastChapterId;
    
    for (var verse in verses) {
      // Yeni bir sure başladı mı kontrol et
      if (verse.chapterId != lastChapterId) {
        // Sure değişti
        if (verse.verseNumber == 1) {
          // Sure başlangıcı
          // Fatiha için de besmele göster, Tevbe hariç
          if (verse.chapterId != 9) {
            pageContent.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 16),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1a237e).withOpacity(0.05),
                        Color(0xFF2E7D32).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    besmele,
                    style: GoogleFonts.amiriQuran(
                      fontSize: 32,
                      height: 2,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a237e),
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ).animate()
                  .fadeIn(duration: 800.ms)
                  .scale(begin: Offset(0.9, 0.9), end: Offset(1, 1)),
              ),
            );
          }
        }
        lastChapterId = verse.chapterId;
      }
      
      // Ayeti ekle
      pageContent.add(_buildVerseWidget(verse));
    }
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          ...pageContent,
          
          // Sayfa numarası (alt kısım)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              '$pageNumber',
              style: GoogleFonts.notoSans(
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

  Widget _buildVerseWidget(Verse verse) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ayet numarası
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${verse.verseNumber}',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Arapça metin - Google Fonts ile
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RichText(
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: verse.textUthmani,
                          style: GoogleFonts.amiriQuran(
                            fontSize: 32,
                            height: 2.2,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        TextSpan(text: ' '),
                        // Ayet sonu işareti
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            margin: EdgeInsets.only(right: 4),
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color(0xFF2E7D32),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              verse.getArabicVerseNumber(),
                              style: GoogleFonts.amiriQuran(
                                fontSize: 18,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Türkçe meal
            if (verse.translationTurkish.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  verse.translationTurkish,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    height: 1.8,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ],
        ),
      ).animate()
        .fadeIn(duration: 600.ms)
        .slideX(begin: 0.1, end: 0),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _paginationScrollController.dispose();
    super.dispose();
  }
}
