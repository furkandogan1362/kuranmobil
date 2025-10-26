import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chapter.dart';
import '../models/verse.dart';
import '../services/quran_json_service.dart';
import '../widgets/surah_list_sheet.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({super.key});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final QuranJsonService _jsonService = QuranJsonService();
  late PageController _pageController;
  final ScrollController _paginationScrollController = ScrollController();
  
  static const int totalPages = 604; // Kuran'ın toplam sayfa sayısı
  
  Map<int, List<Verse>> _pageVerses = {}; // Sayfa numarası -> Ayetler
  Map<int, Chapter> _pageChapters = {}; // Sayfa numarası -> Sure bilgisi
  Map<int, Chapter> _chapterCache = {}; // Sure ID -> Sure bilgisi (yeni)
  Map<int, Map<int, GlobalKey>> _pageKeys = {}; // Sayfa numarası -> (Sure ID -> GlobalKey)
  Map<int, ScrollController> _pageScrollControllers = {}; // Her sayfa için ayrı ScrollController
  int _currentPage = 1; // 1'den başlıyor
  int _initialPage = 0; // Son okunan sayfa
  int? _lastSelectedChapterId; // Son seçilen sure ID'si
  int? _scrollToChapterId; // Bu sayfada hangi sureye scroll yapılacak
  int? _currentVisibleChapterId; // Şu anda görünür olan sure ID'si
  bool _isLoading = true;
  String? _errorMessage;
  
  // Scroll pozisyonu kaydetme için debounce timer
  Timer? _scrollSaveTimer;
  static const Duration _scrollSaveDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _loadLastPageAndInit();
  }

  Future<void> _loadLastPageAndInit() async {
    // Son okunan sayfayı al
    final lastPage = await QuranJsonService.getLastReadPage();
    setState(() {
      _currentPage = lastPage;
      _initialPage = lastPage - 1; // PageController index 0'dan başlar
    });
    
    // PageController'ı başlat
    _pageController = PageController(initialPage: _initialPage);
    
    // Sayfa verilerini yükle
    await _loadInitialPage();
  }

  Future<void> _loadInitialPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Mevcut sayfayı yükle
      await _loadPageData(_currentPage);
      
      setState(() {
        _isLoading = false;
        // İlk yüklemede görünür sure ID'sini sayfanın ilk suresi olarak ayarla
        _currentVisibleChapterId = _pageChapters[_currentPage]?.id;
        // Sure listesi vurgulamasını da ayarla
        _lastSelectedChapterId = _pageChapters[_currentPage]?.id;
      });
      
      // Pagination scroll'u doğru konuma getir ve son scroll pozisyonuna git
      // Widget'ların build edilmesi için kısa bir gecikme ekleyelim
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _scrollPaginationToPage(_currentPage);
        
        // Son okunan sayfanın kaydedilmiş scroll pozisyonuna git
        final scrollController = _pageScrollControllers[_currentPage];
        if (scrollController != null && scrollController.hasClients) {
          final savedPosition = await QuranJsonService.getLastScrollPosition(_currentPage);
          if (savedPosition > 0) {
            // Sayfanın tamamen render edilmesi için kısa gecikme
            await Future.delayed(Duration(milliseconds: 300));
            if (scrollController.hasClients && mounted) {
              // Smooth scroll ile kaydedilmiş pozisyona git
              scrollController.animateTo(
                savedPosition,
                duration: Duration(milliseconds: 800),
                curve: Curves.easeInOutCubic,
              );
            }
          }
        }
      });
      
      // Önceki ve sonraki sayfaları önceden yükle (background)
      if (_currentPage > 1) _loadPageData(_currentPage - 1);
      if (_currentPage < totalPages) _loadPageData(_currentPage + 1);
      if (_currentPage + 1 < totalPages) _loadPageData(_currentPage + 2);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Veriler yüklenirken hata oluştu: $e';
      });
    }
  }

  Future<void> _loadPageData(int pageNumber) async {
    if (_pageVerses.containsKey(pageNumber)) {
      return; // Zaten yüklü
    }

    try {
      // Sayfa ayetlerini çek
      final verses = await _jsonService.getVersesByPage(pageNumber);
      
      // Bu sayfadaki tüm surelerin chapter bilgilerini yükle
      if (verses.isNotEmpty) {
        // İlk ayetin suresini bu sayfanın ana suresi olarak kaydet
        final mainChapterId = verses[0].chapterId;
        final mainChapter = await _jsonService.getChapterFromCache(mainChapterId);
        
        // Sayfadaki benzersiz sure ID'lerini bul
        final uniqueChapterIds = verses.map((v) => v.chapterId).toSet();
        
        // Her sure için chapter bilgisini cache'e ekle
        for (final chapterId in uniqueChapterIds) {
          if (!_chapterCache.containsKey(chapterId)) {
            final chapter = await _jsonService.getChapterFromCache(chapterId);
            _chapterCache[chapterId] = chapter;
          }
        }
        
        setState(() {
          _pageVerses[pageNumber] = verses;
          _pageChapters[pageNumber] = mainChapter; // Sayfanın ana suresi
        });
      }
    } catch (e) {
      print('Sayfa $pageNumber yüklenirken hata: $e');
    }
  }

  void _onPageChanged(int index) {
    final pageNumber = index + 1; // Index 0'dan başlar, sayfa 1'den
    final previousPage = _currentPage;
    
    setState(() {
      _currentPage = pageNumber;
      // Sayfa değiştiğinde görünür sure ID'sini sayfanın ilk suresi olarak ayarla
      _currentVisibleChapterId = _pageChapters[pageNumber]?.id;
      // Sure listesi vurgulamasını da güncelle
      _lastSelectedChapterId = _pageChapters[pageNumber]?.id;
    });

    // Son okunan sayfayı kaydet
    QuranJsonService.saveLastReadPage(pageNumber);
    
    // Önceki sayfanın scroll pozisyonunu temizle (artık o sayfa "son sayfa" değil)
    if (previousPage != pageNumber) {
      QuranJsonService.clearScrollPosition(previousPage);
    }
    
    // Yeni sayfanın kaydedilmiş scroll pozisyonuna git (sadece son sayfa için)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scrollController = _pageScrollControllers[pageNumber];
      if (scrollController != null && scrollController.hasClients) {
        final savedPosition = await QuranJsonService.getLastScrollPosition(pageNumber);
        if (savedPosition > 0) {
          // Son sayfa için smooth scroll yap
          await Future.delayed(Duration(milliseconds: 300));
          if (scrollController.hasClients && mounted) {
            scrollController.animateTo(
              savedPosition,
              duration: Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
            );
          }
        }
      }
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

  void _goToPage(int pageNumber, {int? targetChapterId}) {
    // Sayfayı kaydet
    QuranJsonService.saveLastReadPage(pageNumber);
    
    // Hedef sure ID'sini kaydet
    _scrollToChapterId = targetChapterId;
    
    _pageController.animateToPage(
      pageNumber - 1, // PageView index 0'dan başlar
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // Sure listesini göster
  void _showSurahList() {
    // Son seçilen sure ID'sini kullan, yoksa mevcut sayfanın ilk suresini kullan
    final currentChapterId = _lastSelectedChapterId ?? _pageChapters[_currentPage]?.id ?? 1;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SurahListSheet(
        currentChapterId: currentChapterId,
        onSurahSelected: (pageNumber, chapterId) {
          // Seçilen sure ID'sini kaydet
          _lastSelectedChapterId = chapterId;
          
          // Eğer aynı sayfadaysak, sadece scroll yap
          if (pageNumber == _currentPage) {
            setState(() {
              _scrollToChapterId = chapterId;
            });
            // Scroll işlemini tetikle
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _performScrollToChapter(chapterId);
            });
          } else {
            // Farklı sayfaya git
            _goToPage(pageNumber, targetChapterId: chapterId);
          }
        },
      ),
    );
  }
  
  // Sure başlangıcına scroll yap
  void _performScrollToChapter(int chapterId) {
    if (_pageKeys[_currentPage]?.containsKey(chapterId) == true) {
      final key = _pageKeys[_currentPage]![chapterId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.0,
        );
      }
    }
  }
  
  // Scroll pozisyonunu kaydetmeyi zamanla (debouncing)
  void _scheduleScrollSave(int pageNumber) {
    // Sadece mevcut sayfa için kaydet
    if (pageNumber != _currentPage) return;
    
    // Önceki timer'ı iptal et
    _scrollSaveTimer?.cancel();
    
    // Yeni timer başlat - 500ms sonra kaydet
    _scrollSaveTimer = Timer(_scrollSaveDelay, () {
      final scrollController = _pageScrollControllers[pageNumber];
      if (scrollController != null && scrollController.hasClients) {
        QuranJsonService.saveLastScrollPosition(pageNumber, scrollController.offset);
      }
    });
  }
  
  // Scroll pozisyonuna göre görünür surenin ID'sini güncelle
  void _updateVisibleChapter(int pageNumber) {
    if (pageNumber != _currentPage) return; // Sadece aktif sayfa için çalış
    
    final scrollController = _pageScrollControllers[pageNumber];
    if (scrollController == null || !scrollController.hasClients) return;
    
    final pageKeysMap = _pageKeys[pageNumber];
    if (pageKeysMap == null || pageKeysMap.isEmpty) return;
    
    // Header yüksekliği (geri butonu + sure adı + pagination)
    const headerHeight = 180.0;
    
    // Eşik değeri - Besmele konteyneri header'ın altına bu kadar yaklaştığında değişsin
    const threshold = 50.0;
    
    // Her sure başlangıcının ekrandaki pozisyonunu kontrol et
    int? newVisibleChapterId;
    
    // Sure ID'lerini sıralı şekilde işle (büyükten küçüğe - en alttaki sureden başla)
    final sortedChapterIds = pageKeysMap.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (final chapterId in sortedChapterIds) {
      final key = pageKeysMap[chapterId];
      final context = key?.currentContext;
      
      if (context != null) {
        try {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final position = box.localToGlobal(Offset.zero);
          
          // Sure başlangıcının ekrandaki Y pozisyonu
          final surahTopOnScreen = position.dy;
          
          // Eğer sure başlangıcı header'ın altına geldi veya geçtiyse (threshold içinde)
          if (surahTopOnScreen <= (headerHeight + threshold)) {
            newVisibleChapterId = chapterId;
            break; // İlk eşleşeni bulduk, dur
          }
        } catch (e) {
          // RenderBox henüz hazır değilse, geç
          continue;
        }
      }
    }
    
    // Eğer hiçbir sure header'ın altında değilse, sayfanın ilk suresini kullan
    if (newVisibleChapterId == null && sortedChapterIds.isNotEmpty) {
      newVisibleChapterId = sortedChapterIds.last; // En küçük ID (sayfanın ilk suresi)
    }
    
    // Eğer görünür sure değiştiyse, state'i güncelle
    if (newVisibleChapterId != null && newVisibleChapterId != _currentVisibleChapterId) {
      setState(() {
        _currentVisibleChapterId = newVisibleChapterId;
        // Sure listesinde vurgulanan sureyi de güncelle
        _lastSelectedChapterId = newVisibleChapterId;
      });
    }
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
                  style: TextStyle(
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
                    style: TextStyle(
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
                              style: TextStyle(
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
    // Görünür sure ID'si varsa onu kullan, yoksa sayfanın ilk suresini kullan
    final displayChapterId = _currentVisibleChapterId ?? _pageChapters[_currentPage]?.id;
    final chapter = displayChapterId != null ? _chapterCache[displayChapterId] : _pageChapters[_currentPage];
    
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
                    key: ValueKey('header_chapter_$displayChapterId'), // Animasyonu engellemek için key
                    children: [
                      Text(
                        chapter?.nameArabic ?? '...',
                        style: TextStyle(
                          fontFamily: 'ShaikhHamdullah',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a237e),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        chapter?.nameTurkish ?? 'Yükleniyor...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sayfa $_currentPage',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Sure listesi butonu
                IconButton(
                  icon: Icon(Icons.list_rounded, color: Color(0xFF2E7D32)),
                  onPressed: _showSurahList,
                  tooltip: 'Sureler',
                ),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
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
    // Bu sayfa için sure başlangıç key'lerini sakla
    if (!_pageKeys.containsKey(pageNumber)) {
      _pageKeys[pageNumber] = {};
    }
    
    // Bu sayfa için ScrollController oluştur (henüz yoksa)
    if (!_pageScrollControllers.containsKey(pageNumber)) {
      final scrollController = ScrollController();
      _pageScrollControllers[pageNumber] = scrollController;
      
      // Scroll listener ekle - sure değişikliklerini algıla
      scrollController.addListener(() {
        _updateVisibleChapter(pageNumber);
        _scheduleScrollSave(pageNumber);
      });
    }
    
    final scrollController = _pageScrollControllers[pageNumber]!;
    
    // Sayfadaki ayetleri gruplara ayır (sure başlangıçlarına göre)
    List<Widget> pageContent = [];
    int? lastChapterId;
    
    for (var verse in verses) {
      // Yeni bir sure başladı mı kontrol et
      if (verse.chapterId != lastChapterId) {
        // Sure değişti
        if (verse.verseNumber == 1) {
          // Sure başlangıcı için GlobalKey oluştur
          final key = GlobalKey();
          _pageKeys[pageNumber]![verse.chapterId] = key;
          
          // Sure başlangıcı - Sure adını ve besmeleyi göster
          // Tevbe hariç (Tevbe suresinde besmele yok)
          pageContent.add(_buildSurahHeader(verse.chapterId, key: key));
        }
        lastChapterId = verse.chapterId;
      }
      
      // Ayeti ekle
      pageContent.add(_buildVerseWidget(verse));
    }
    
    // Eğer hedef sure ID'si varsa ve bu sayfada varsa, scroll yap
    if (_scrollToChapterId != null && _pageKeys[pageNumber]?.containsKey(_scrollToChapterId) == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _pageKeys[pageNumber]![_scrollToChapterId];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.0, // En üste scroll et
          );
          // Hedef sure ID'sini temizle
          setState(() {
            _scrollToChapterId = null;
          });
        }
      });
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

  Widget _buildSurahHeader(int chapterId, {GlobalKey? key}) {
    // Besmele metni
    const besmele = 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ';
    
    // Sure bilgisini cache'den al
    final chapter = _chapterCache[chapterId];
    
    // Eğer cache'de yoksa, varsayılan bir isim kullan
    final surahName = chapter?.nameTurkish ?? 'Yükleniyor...';
    
    return Padding(
      key: key, // GlobalKey'i en dış widget'a ekle
      padding: const EdgeInsets.only(bottom: 24, top: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1a237e).withOpacity(0.05),
              const Color(0xFF2E7D32).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Sure adı (Türkçe)
            Text(
              '$surahName Sûresi',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a237e),
              ),
              textAlign: TextAlign.center,
            ),
            
            // Tevbe suresi hariç besmele göster
            if (chapterId != 9) ...[
              const SizedBox(height: 16),
              Text(
                besmele,
                style: const TextStyle(
                  fontFamily: 'ShaikhHamdullah',
                  fontSize: 32,
                  height: 2,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a237e),
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerseWidget(Verse verse) {
    final isSajdah = verse.isSajdahVerse();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Secde ayeti için özel gradient arka plan
          gradient: isSajdah
              ? LinearGradient(
                  colors: [
                    Color(0xFF8E24AA).withOpacity(0.08),
                    Color(0xFF6A1B9A).withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSajdah ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          // Secde ayeti için özel border
          border: isSajdah
              ? Border.all(
                  color: Color(0xFF8E24AA).withOpacity(0.3),
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isSajdah 
                  ? Color(0xFF8E24AA).withOpacity(0.15)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSajdah ? 15 : 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ayet numarası ve secde ikonu
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSajdah
                        ? Color(0xFF8E24AA).withOpacity(0.15)
                        : Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${verse.verseNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSajdah
                            ? Color(0xFF8E24AA)
                            : Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ),
                
                // Secde ayeti işareti
                if (isSajdah) ...[
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF8E24AA),
                          Color(0xFF6A1B9A),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF8E24AA).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.motion_photos_pause_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'SECDE AYETİ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                          style: TextStyle(
                            fontFamily: 'ShaikhHamdullah',
                            fontSize: 32,
                            height: 2.2,
                            fontWeight: FontWeight.w500,
                            color: isSajdah 
                                ? Color(0xFF6A1B9A)
                                : Colors.black87,
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
                                color: isSajdah
                                    ? Color(0xFF8E24AA)
                                    : Color(0xFF2E7D32),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              verse.getArabicVerseNumber(),
                              style: TextStyle(
                                fontFamily: 'ShaikhHamdullah',
                                fontSize: 18,
                                color: isSajdah
                                    ? Color(0xFF8E24AA)
                                    : Color(0xFF2E7D32),
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
                  style: TextStyle(
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
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _paginationScrollController.dispose();
    
    // Scroll save timer'ını iptal et
    _scrollSaveTimer?.cancel();
    
    // Tüm sayfa ScrollController'larını temizle
    for (var controller in _pageScrollControllers.values) {
      controller.dispose();
    }
    _pageScrollControllers.clear();
    
    super.dispose();
  }
}
