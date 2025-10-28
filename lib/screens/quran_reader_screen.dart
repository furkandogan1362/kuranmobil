import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chapter.dart';
import '../models/verse.dart';
import '../services/quran_json_service.dart';
import '../services/font_settings_service.dart';
import '../widgets/surah_list_sheet.dart';
import '../widgets/settings_menu_sheet.dart';
import 'quran_reader/widgets/quran_reader_header.dart';
import 'quran_reader/widgets/surah_header.dart';
import 'quran_reader/widgets/verse_card.dart';

class QuranReaderScreen extends StatefulWidget {
  final Function(String themeMode)? onThemeChanged;
  
  const QuranReaderScreen({super.key, this.onThemeChanged});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final QuranJsonService _jsonService = QuranJsonService();
  late PageController _pageController;
  final ScrollController _paginationScrollController = ScrollController();
  // Sabit header'ı ölçmek için GlobalKey (başlık alt sınırına temas anını tespit edeceğiz)
  final GlobalKey _headerKey = GlobalKey();
  // Uzak sayfalara hızlı atlama sırasında yumuşak bir katman göstermek için
  bool _isJumpingFar = false;
  static const int _farJumpThreshold =
      1; // Bu kadar ve üzeri farkta anlık geçiş + fade kullan

  static const int totalPages = 604; // Kuran'ın toplam sayfa sayısı

  Map<int, List<Verse>> _pageVerses = {}; // Sayfa numarası -> Ayetler
  Map<int, Chapter> _pageChapters = {}; // Sayfa numarası -> Sure bilgisi
  Map<int, Chapter> _chapterCache = {}; // Sure ID -> Sure bilgisi (yeni)
  Map<int, Map<int, GlobalKey>> _pageKeys =
      {}; // Sayfa numarası -> (Sure ID -> GlobalKey)
  Map<int, ScrollController> _pageScrollControllers =
      {}; // Her sayfa için ayrı ScrollController
  int _currentPage = 1; // 1'den başlıyor
  int _initialPage = 0; // Son okunan sayfa
  int? _lastSelectedChapterId; // Son seçilen sure ID'si
  int? _scrollToChapterId; // Bu sayfada hangi sureye scroll yapılacak
  int? _currentVisibleChapterId; // Şu anda görünür olan sure ID'si
  bool _isLoading = true;
  String? _errorMessage;
  
  // Font boyutları
  double _arabicFontSize = FontSettingsService.defaultArabicFontSize;
  double _turkishFontSize = FontSettingsService.defaultTurkishFontSize;

  // Scroll pozisyonu kaydetme için debounce timer
  Timer? _scrollSaveTimer;
  static const Duration _scrollSaveDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _loadLastPageAndInit();
    _loadFontSettings();
  }
  
  Future<void> _loadFontSettings() async {
    final arabicSize = await FontSettingsService.getArabicFontSize();
    final turkishSize = await FontSettingsService.getTurkishFontSize();
    setState(() {
      _arabicFontSize = arabicSize;
      _turkishFontSize = turkishSize;
    });
  }
  
  void _updateFontSizes(double arabicSize, double turkishSize) {
    setState(() {
      _arabicFontSize = arabicSize;
      _turkishFontSize = turkishSize;
    });
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
          final savedPosition = await QuranJsonService.getLastScrollPosition(
            _currentPage,
          );
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
        final mainChapter = await _jsonService.getChapterFromCache(
          mainChapterId,
        );

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
        final savedPosition = await QuranJsonService.getLastScrollPosition(
          pageNumber,
        );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollPaginationToPage(pageNumber);
    });
  }

  void _scrollPaginationToPage(int pageNumber) {
    if (_paginationScrollController.hasClients) {
      // Ekran genişliğinden hesapla
      final screenWidth = MediaQuery.of(context).size.width;
      final availableWidth = screenWidth - 24; // 12px padding her tarafta
      
      const visibleBoxCount = 9;
      const spacing = 4.0;
      const totalSpacing = spacing * (visibleBoxCount - 1);
      
      final boxWidth = (availableWidth - totalSpacing) / visibleBoxCount;
      final itemWidth = boxWidth + spacing; // Kutu genişliği + spacing
      
      final rightPadding = spacing; // Sağdan boşluk
      final position = (pageNumber - 1) * itemWidth + rightPadding;
      
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

    final delta = (pageNumber - _currentPage).abs();
    if (delta >= _farJumpThreshold) {
      // Çok uzak sayfaya geçiş: Önceden veri yükle, anlık jump yap, üstüne hafif bir fade uygula
      setState(() {
        _isJumpingFar = true;
      });
      () async {
        try {
          // Hedef ve komşu sayfaları önceden yükle
          await _loadPageData(pageNumber);
          if (pageNumber > 1) _loadPageData(pageNumber - 1);
          if (pageNumber < totalPages) _loadPageData(pageNumber + 1);
          // Overlay'in görünmesi için mini bir frame beklet
          await Future.delayed(const Duration(milliseconds: 30));
          if (!mounted) return;
          _pageController.jumpToPage(pageNumber - 1);
          // İçerik yerleşsin, sonra overlay'i yumuşakça kaldır
          await Future.delayed(const Duration(milliseconds: 120));
        } finally {
          if (mounted) {
            setState(() {
              _isJumpingFar = false;
            });
          }
        }
      }();
    } else {
      // Yakın sayfalara yumuşak animasyon
      _pageController.animateToPage(
        pageNumber - 1, // PageView index 0'dan başlar
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // Sure listesini göster
  void _showSurahList() {
    // Son seçilen sure ID'sini kullan, yoksa mevcut sayfanın ilk suresini kullan
    final currentChapterId =
        _lastSelectedChapterId ?? _pageChapters[_currentPage]?.id ?? 1;

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
  
  // Font ayarları bottom sheet'ini göster
  void _showFontSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsMenuSheet(
        onFontSizeChanged: _updateFontSizes,
        onThemeChanged: widget.onThemeChanged, // Callback'i ilet
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
        QuranJsonService.saveLastScrollPosition(
          pageNumber,
          scrollController.offset,
        );
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

    // Header'ın ekrandaki alt sınırını dinamik olarak ölç (sabit sayı kullanma)
    double headerBottom = 0.0;
    try {
      final headerBox =
          _headerKey.currentContext?.findRenderObject() as RenderBox?;
      if (headerBox != null) {
        final headerTop = headerBox.localToGlobal(Offset.zero).dy;
        headerBottom = headerTop + headerBox.size.height;
      }
    } catch (_) {
      // Ölçüm başarısız olursa, muhafazakar bir varsayılan kullan (ama mümkünse 0 bırak)
      headerBottom = headerBottom == 0.0 ? 180.0 : headerBottom;
    }
    // Yüzen sayılar için çok küçük bir tolerans
    const epsilon = 0.5;

    // Her sure başlangıcının ekrandaki pozisyonunu kontrol et
    int? newVisibleChapterId;
    final positions = <MapEntry<int, double>>[];

    // Mevcut sayfada render edilmiş tüm sure başlıklarının tepe (top) konumlarını topla
    pageKeysMap.forEach((chapterId, key) {
      final context = key.currentContext;
      if (context != null) {
        try {
          final box = context.findRenderObject() as RenderBox;
          final top = box.localToGlobal(Offset.zero).dy;
          positions.add(MapEntry(chapterId, top));
        } catch (_) {}
      }
    });

    if (positions.isNotEmpty) {
      // Ekrandaki konuma göre sırala (üstten alta)
      positions.sort((a, b) => a.value.compareTo(b.value));
      // Header altına GELEN veya TEMAS EDEN en son (ekrana göre en alttaki) başlığı seç
      final underHeader = positions
          .where((e) => e.value <= headerBottom + epsilon)
          .toList();
      if (underHeader.isNotEmpty) {
        newVisibleChapterId = underHeader.last.key;
      } else {
        // Henüz bu sayfadaki hiçbir sure başlığı header'a temas etmediyse,
        // sayfanın mevcut (ilk) suresini görünür kabul et
        newVisibleChapterId = _pageChapters[pageNumber]?.id;
      }
    }

    // Eğer görünür sure değiştiyse, state'i güncelle
    if (newVisibleChapterId != null &&
        newVisibleChapterId != _currentVisibleChapterId) {
      setState(() {
        _currentVisibleChapterId = newVisibleChapterId;
        // Sure listesinde vurgulanan sureyi de güncelle
        _lastSelectedChapterId = newVisibleChapterId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [Color(0xFF242324), Color(0xFF242324)]
                  : [Color(0xFF1a237e), Color(0xFF0d47a1)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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
            ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
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
              colors: isDark
                  ? [Color(0xFF242324), Color(0xFF242324)]
                  : [Color(0xFF1a237e), Color(0xFF0d47a1)],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.white70),
                  SizedBox(height: 24),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Color(0xFF242324), Color(0xFF242324)]
                    : [Color(0xFFFAF8F3), Color(0xFFF5F1E8)],
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
                      allowImplicitScrolling:
                          true, // Komşu sayfaları önceden hazırlayıp kaydırmayı yumuşat
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
          // Uzak sayfaya geçişte yumuşak katman (fade)
          if (_isJumpingFar)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 150),
                  child: Container(color: Colors.white.withOpacity(0.6)),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFixedHeader() {
    final displayChapterId =
        _currentVisibleChapterId ?? _pageChapters[_currentPage]?.id;
    final chapter = displayChapterId != null
        ? _chapterCache[displayChapterId]
        : _pageChapters[_currentPage];

    return QuranReaderHeader(
      headerKey: _headerKey,
      chapter: chapter,
      displayChapterId: displayChapterId,
      currentPage: _currentPage,
      totalPages: totalPages,
      paginationScrollController: _paginationScrollController,
      onBack: () => Navigator.pop(context),
      onShowSurahList: _showSurahList,
      onPageSelected: _goToPage,
    );
  }
  
  Widget _buildBottomNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [Color(0xFF302F30), Color(0xFF302F30)]
              : [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.12),
            blurRadius: 16,
            offset: Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavBarItem(
                icon: Icons.settings_rounded,
                label: 'Ayarlar',
                onTap: _showFontSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavBarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Color(0xFF2E7D32).withOpacity(0.8),
                    Color(0xFF43A047).withOpacity(0.8),
                  ]
                : [
                    Color(0xFF2E7D32),
                    Color(0xFF43A047),
                  ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF2E7D32).withOpacity(isDark ? 0.15 : 0.35),
              blurRadius: 10,
              offset: Offset(0, 3),
              spreadRadius: 0,
            ),
            if (!isDark)
              BoxShadow(
                color: Colors.white.withOpacity(0.4),
                blurRadius: 6,
                offset: Offset(0, -1),
                spreadRadius: 0,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
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
          final chapterInfo = _chapterCache[verse.chapterId];
          final surahName = chapterInfo?.nameTurkish ?? 'Yükleniyor...';
          pageContent.add(
            SurahHeader(
              key: key,
              chapterId: verse.chapterId,
              surahName: surahName,
              showBesmele: true,
            ),
          );
        }
        lastChapterId = verse.chapterId;
      }

      // Ayeti ekle
      pageContent.add(
        VerseCard(
          verse: verse,
          arabicFontSize: _arabicFontSize,
          turkishFontSize: _turkishFontSize,
        ),
      );
    }

    // Eğer hedef sure ID'si varsa ve bu sayfada varsa, scroll yap
    if (_scrollToChapterId != null &&
        _pageKeys[pageNumber]?.containsKey(_scrollToChapterId) == true) {
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
