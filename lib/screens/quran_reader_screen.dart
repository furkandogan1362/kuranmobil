import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/chapter.dart';
import '../models/verse.dart';
import '../services/quran_json_service.dart';
import '../services/font_settings_service.dart';
import '../services/audio_service.dart';
import '../widgets/surah_list_sheet.dart';
import '../widgets/settings_menu_sheet.dart';
import '../widgets/audio_player_widget.dart';
import 'quran_reader/widgets/quran_reader_header.dart';
import 'quran_reader/widgets/quran_reader_bottom_bar.dart';
import 'quran_reader/widgets/quran_page_content.dart';
import 'quran_reader/utils/scroll_manager.dart';
import 'quran_reader/utils/navigation_helper.dart';

class QuranReaderScreen extends StatefulWidget {
  final Function(String themeMode)? onThemeChanged;
  
  const QuranReaderScreen({super.key, this.onThemeChanged});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final QuranJsonService _jsonService = QuranJsonService();
  final ScrollManager _scrollManager = ScrollManager();
  final NavigationHelper _navigationHelper = NavigationHelper();
  late PageController _pageController;
  final ScrollController _paginationScrollController = ScrollController();
  // Sabit header'ı ölçmek için GlobalKey (başlık alt sınırına temas anını tespit edeceğiz)
  final GlobalKey _headerKey = GlobalKey();
  // Uzak sayfalara hızlı atlama sırasında yumuşak bir katman göstermek için
  bool _isJumpingFar = false;

  static const int totalPages = 604; // Kuran'ın toplam sayfa sayısı

  Map<int, List<Verse>> _pageVerses = {}; // Sayfa numarası -> Ayetler
  Map<int, Chapter> _pageChapters = {}; // Sayfa numarası -> Sure bilgisi
  Map<int, Chapter> _chapterCache = {}; // Sure ID -> Sure bilgisi (yeni)
  Map<int, Map<int, GlobalKey>> _pageKeys =
      {}; // Sayfa numarası -> (Sure ID -> GlobalKey) - Sure başlıkları için
  Map<int, Map<String, GlobalKey>> _verseKeys = 
      {}; // Sayfa numarası -> ("surah_ayah" -> GlobalKey) - Ayetler için
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

  // Oynatıcı durumu
  bool _isPlayerExpanded = false; // Oynatıcı açık mı?
  bool _isPlayerMinimized = false; // Oynatıcı minimize mi?

  @override
  void initState() {
    super.initState();
    _loadLastPageAndInit();
    _loadFontSettings();
    
    // AudioService sayfa değiştirme callback'ini ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioService = Provider.of<AudioService>(context, listen: false);
      audioService.onPageChangeNeeded = _handlePageChangeRequest;
    });
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
        _navigationHelper.scrollPaginationToPage(
          pageNumber: _currentPage,
          paginationScrollController: _paginationScrollController,
          context: context,
        );

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
    
    // AudioService'e yeni sayfanın suresini bildir
    if (_currentVisibleChapterId != null) {
      final audioService = Provider.of<AudioService>(context, listen: false);
      audioService.setVisibleSurah(_currentVisibleChapterId!);
    }

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
      _navigationHelper.scrollPaginationToPage(
        pageNumber: pageNumber,
        paginationScrollController: _paginationScrollController,
        context: context,
      );
    });
  }

  void _goToPage(int pageNumber, {int? targetChapterId}) {
    _navigationHelper.goToPage(
      targetPage: pageNumber,
      currentPage: _currentPage,
      pageController: _pageController,
      targetChapterId: targetChapterId,
      onScrollToChapterIdChanged: (chapterId) {
        setState(() {
          _scrollToChapterId = chapterId;
        });
      },
      onJumpingStateChanged: (isJumping) {
        if (mounted) {
          setState(() {
            _isJumpingFar = isJumping;
          });
        }
      },
      loadPageData: (page) async => await _loadPageData(page),
      totalPages: totalPages,
    );
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
        // Meal sayfasında görünüm ayarı YOK - null gönder
        onViewModeChanged: null,
      ),
    );
  }

  
  // Sure başlangıcına scroll yap
  void _performScrollToChapter(int chapterId) {
    _navigationHelper.performScrollToChapter(
      chapterId: chapterId,
      currentPage: _currentPage,
      pageKeys: _pageKeys,
    );
  }  // Scroll pozisyonunu kaydetmeyi zamanla (debouncing)
  void _scheduleScrollSave(int pageNumber) {
    _scrollManager.scheduleScrollSave(
      pageNumber: pageNumber,
      currentPage: _currentPage,
      pageScrollControllers: _pageScrollControllers,
    );
  }

  // Scroll pozisyonuna göre görünür surenin ID'sini güncelle
  void _updateVisibleChapter(int pageNumber) {
    final newVisibleChapterId = _scrollManager.updateVisibleChapter(
      pageNumber: pageNumber,
      currentPage: _currentPage,
      pageScrollControllers: _pageScrollControllers,
      pageKeys: _pageKeys,
      pageChapters: _pageChapters,
      headerKey: _headerKey,
    );

    // Eğer görünür sure değiştiyse, state'i güncelle
    if (newVisibleChapterId != null &&
        newVisibleChapterId != _currentVisibleChapterId) {
      setState(() {
        _currentVisibleChapterId = newVisibleChapterId;
        _lastSelectedChapterId = newVisibleChapterId;
      });
      
      // AudioService'e görünen sureyi bildir - SADECE sesli meal çalmıyorsa
      final audioService = Provider.of<AudioService>(context, listen: false);
      if (!audioService.isPlaying) {
        audioService.setVisibleSurah(newVisibleChapterId);
      }
    }
  }
  
  // Çalan ayetin sayfa bilgisini kontrol et ve gerekirse sayfa değiştir
  void _handlePageChangeRequest(int surahId, int ayahNumber) {
    // Mevcut sayfadaki ayetler arasında bu ayet var mı kontrol et
    final currentPageVerses = _pageVerses[_currentPage];
    if (currentPageVerses == null) return;
    
    // Bu ayetin mevcut sayfada olup olmadığını kontrol et
    final verseInCurrentPage = currentPageVerses.any(
      (v) => v.chapterId == surahId && v.verseNumber == ayahNumber,
    );
    
    // Eğer ayet bu sayfada varsa, sayfa değişimine gerek yok
    if (verseInCurrentPage) return;
    
    // Ayet bu sayfada değil - tüm yüklü sayfalarda ara
    int? targetPage;
    for (var pageEntry in _pageVerses.entries) {
      final verses = pageEntry.value;
      final verse = verses.firstWhere(
        (v) => v.chapterId == surahId && v.verseNumber == ayahNumber,
        orElse: () => Verse(
          id: 0,
          verseNumber: 0,
          chapterId: 0,
          verseKey: '',
          textUthmani: '',
          translationTurkish: '',
          pageNumber: 0,
          juzNumber: 0,
        ),
      );
      
      if (verse.pageNumber > 0) {
        targetPage = verse.pageNumber;
        break;
      }
    }
    
    // Hedef sayfa bulunduysa git
    if (targetPage != null && targetPage != _currentPage) {
      print('📄 Sayfa değiştiriliyor: $_currentPage -> $targetPage (Sure: $surahId, Ayet: $ayahNumber)');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            targetPage! - 1, // PageController 0-indexed
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }
  
  // Çalan ayete otomatik scroll
  void _scrollToPlayingVerse(int pageNumber, int surahId, int verseNumber) {
    _scrollManager.scrollToPlayingVerse(
      pageNumber: pageNumber,
      surahId: surahId,
      verseNumber: verseNumber,
      pageKeys: _pageKeys,
      verseKeys: _verseKeys,
    );
  }

  // Sesli meal oynatıcıyı aç/kapat
  void _startAudioPlayer() {
    setState(() {
      if (_isPlayerMinimized) {
        // Minimize edilmişse tam aç
        _isPlayerMinimized = false;
        _isPlayerExpanded = true;
      } else if (_isPlayerExpanded) {
        // Açıksa minimize et
        _isPlayerExpanded = false;
        _isPlayerMinimized = true;
      } else {
        // Kapalıysa aç
        _isPlayerExpanded = true;
        _isPlayerMinimized = false;
      }
    });
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
      body: Column(
        children: [
          // Ana içerik
          Expanded(
            child: Stack(
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
                    bottom: false, // Bottom'u false yapıyoruz çünkü aşağıda widget'lar var
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
          ),
          
          // Audio player - Bottom bar'ın hemen üstünde
          AudioPlayerWidget(
            chapter: _pageChapters[_currentPage],
            currentPage: _currentPage,
            chapters: _chapterCache,
            currentPageVerses: _pageVerses[_currentPage],
            isExpanded: _isPlayerExpanded,
            isMinimized: _isPlayerMinimized,
            onExpandedChanged: (value) => setState(() => _isPlayerExpanded = value),
            onMinimizedChanged: (value) => setState(() => _isPlayerMinimized = value),
            onChapterSelected: (chapter) {
              // Sure seçildiğinde o surenin sayfasına git
              final targetPage = chapter.pageStart;
              if (targetPage != _currentPage) {
                _pageController.animateToPage(
                  targetPage - 1, // PageView 0-indexed
                  duration: Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
          
          // Bottom navigation bar
          _buildBottomNavigationBar(),
        ],
      ),
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
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        return QuranReaderBottomBar(
          onAudioPlayerTap: _startAudioPlayer,
          onSettingsTap: _showFontSettings,
        );
      },
    );
  }

  Widget _buildQuranPage(int pageNumber, Chapter chapter, List<Verse> verses) {
    // Bu sayfa için sure başlangıç key'lerini sakla
    if (!_pageKeys.containsKey(pageNumber)) {
      _pageKeys[pageNumber] = {};
    }
    
    // Bu sayfa için ayet key'lerini sakla
    if (!_verseKeys.containsKey(pageNumber)) {
      _verseKeys[pageNumber] = {};
    }

    // Sure başlangıç key'lerini oluştur
    for (var verse in verses) {
      if (verse.verseNumber == 1 && !_pageKeys[pageNumber]!.containsKey(verse.chapterId)) {
        _pageKeys[pageNumber]![verse.chapterId] = GlobalKey();
      }
      
      // Ayet key'lerini oluştur
      final verseKeyId = '${verse.chapterId}_${verse.verseNumber}';
      if (!_verseKeys[pageNumber]!.containsKey(verseKeyId)) {
        _verseKeys[pageNumber]![verseKeyId] = GlobalKey();
      }
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

    return QuranPageContent(
      pageNumber: pageNumber,
      chapter: chapter,
      verses: verses,
      arabicFontSize: _arabicFontSize,
      turkishFontSize: _turkishFontSize,
      scrollController: scrollController,
      pageKeys: _pageKeys[pageNumber]!,
      verseKeys: _verseKeys[pageNumber]!,
      chapterCache: _chapterCache,
      scrollToChapterId: pageNumber == _currentPage ? _scrollToChapterId : null,
      onScrollToChapterComplete: () {
        setState(() {
          _scrollToChapterId = null;
        });
      },
      onScrollToPlayingVerse: (page, surahId, verseNumber) {
        if (page == _currentPage) {
          _scrollToPlayingVerse(page, surahId, verseNumber);
        }
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _paginationScrollController.dispose();

    // Scroll manager'ı temizle
    _scrollManager.dispose();

    // Tüm sayfa ScrollController'larını temizle
    for (var controller in _pageScrollControllers.values) {
      controller.dispose();
    }
    _pageScrollControllers.clear();

    super.dispose();
  }
}
