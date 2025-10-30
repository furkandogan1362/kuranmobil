import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chapter.dart';
import '../models/verse.dart';
import '../services/quran_json_service.dart';
import '../services/font_settings_service.dart';
import '../services/view_settings_service.dart';
import '../widgets/surah_list_sheet.dart';
import '../widgets/settings_menu_sheet.dart';
import '../widgets/verse_separator.dart';
import 'quran_reader/widgets/quran_reader_header.dart';
import 'quran_reader/widgets/surah_header.dart';

class ArabicQuranReaderScreen extends StatefulWidget {
  final Function(String themeMode)? onThemeChanged;
  
  const ArabicQuranReaderScreen({super.key, this.onThemeChanged});

  @override
  State<ArabicQuranReaderScreen> createState() => _ArabicQuranReaderScreenState();
}

class _ArabicQuranReaderScreenState extends State<ArabicQuranReaderScreen> {
  final QuranJsonService _jsonService = QuranJsonService();
  late PageController _pageController;
  final ScrollController _paginationScrollController = ScrollController();
  final GlobalKey _headerKey = GlobalKey();
  bool _isJumpingFar = false;
  static const int _farJumpThreshold = 1;

  static const int totalPages = 604;

  Map<int, List<Verse>> _pageVerses = {};
  Map<int, Chapter> _pageChapters = {};
  Map<int, Chapter> _chapterCache = {};
  Map<int, Map<int, GlobalKey>> _pageKeys = {};
  Map<int, ScrollController> _pageScrollControllers = {};
  int _currentPage = 1;
  int _initialPage = 0;
  int? _lastSelectedChapterId;
  int? _scrollToChapterId;
  int? _currentVisibleChapterId;
  bool _isLoading = true;
  String? _errorMessage;
  
  double _arabicFontSize = FontSettingsService.defaultArabicFontSize;
  String _viewMode = ViewSettingsService.defaultViewMode;

  Timer? _scrollSaveTimer;
  static const Duration _scrollSaveDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _loadLastPageAndInit();
    _loadFontSettings();
    _loadViewMode();
  }
  
  Future<void> _loadFontSettings() async {
    final arabicSize = await FontSettingsService.getArabicFontSize();
    setState(() {
      _arabicFontSize = arabicSize;
    });
  }
  
  Future<void> _loadViewMode() async {
    final viewMode = await ViewSettingsService.getViewMode();
    setState(() {
      _viewMode = viewMode;
    });
  }
  
  void _updateFontSizes(double arabicSize, double turkishSize) {
    setState(() {
      _arabicFontSize = arabicSize;
    });
  }

  Future<void> _loadLastPageAndInit() async {
    final lastPage = await QuranJsonService.getLastReadPage();
    setState(() {
      _currentPage = lastPage;
      _initialPage = lastPage - 1;
    });

    _pageController = PageController(initialPage: _initialPage);
    await _loadInitialPage();
  }

  Future<void> _loadInitialPage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _loadPageData(_currentPage);

      setState(() {
        _isLoading = false;
        _currentVisibleChapterId = _pageChapters[_currentPage]?.id;
        _lastSelectedChapterId = _pageChapters[_currentPage]?.id;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _scrollPaginationToPage(_currentPage);

        final scrollController = _pageScrollControllers[_currentPage];
        if (scrollController != null && scrollController.hasClients) {
          final savedPosition = await QuranJsonService.getLastScrollPosition(_currentPage);
          if (savedPosition > 0) {
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
      return;
    }

    try {
      final verses = await _jsonService.getVersesByPage(pageNumber);

      if (verses.isNotEmpty) {
        final mainChapterId = verses[0].chapterId;
        final mainChapter = await _jsonService.getChapterFromCache(mainChapterId);

        final uniqueChapterIds = verses.map((v) => v.chapterId).toSet();

        for (final chapterId in uniqueChapterIds) {
          if (!_chapterCache.containsKey(chapterId)) {
            final chapter = await _jsonService.getChapterFromCache(chapterId);
            _chapterCache[chapterId] = chapter;
          }
        }

        setState(() {
          _pageVerses[pageNumber] = verses;
          _pageChapters[pageNumber] = mainChapter;
        });
      }
    } catch (e) {
      print('Sayfa $pageNumber yüklenirken hata: $e');
    }
  }

  void _onPageChanged(int index) {
    final pageNumber = index + 1;
    final previousPage = _currentPage;

    setState(() {
      _currentPage = pageNumber;
      _currentVisibleChapterId = _pageChapters[pageNumber]?.id;
      _lastSelectedChapterId = _pageChapters[pageNumber]?.id;
    });

    QuranJsonService.saveLastReadPage(pageNumber);

    if (previousPage != pageNumber) {
      QuranJsonService.clearScrollPosition(previousPage);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final scrollController = _pageScrollControllers[pageNumber];
      if (scrollController != null && scrollController.hasClients) {
        final savedPosition = await QuranJsonService.getLastScrollPosition(pageNumber);
        if (savedPosition > 0) {
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

    _loadPageData(pageNumber);

    if (pageNumber > 1) {
      _loadPageData(pageNumber - 1);
    }
    if (pageNumber < totalPages) {
      _loadPageData(pageNumber + 1);
    }
    if (pageNumber + 1 < totalPages) {
      _loadPageData(pageNumber + 2);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollPaginationToPage(pageNumber);
    });
  }

  void _scrollPaginationToPage(int pageNumber) {
    if (_paginationScrollController.hasClients) {
      final screenWidth = MediaQuery.of(context).size.width;
      final availableWidth = screenWidth - 24;
      
      const visibleBoxCount = 9;
      const spacing = 4.0;
      const totalSpacing = spacing * (visibleBoxCount - 1);
      
      final boxWidth = (availableWidth - totalSpacing) / visibleBoxCount;
      final itemWidth = boxWidth + spacing;
      
      final rightPadding = spacing;
      final position = (pageNumber - 1) * itemWidth + rightPadding;
      
      _paginationScrollController.animateTo(
        position,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int pageNumber, {int? targetChapterId}) {
    QuranJsonService.saveLastReadPage(pageNumber);
    _scrollToChapterId = targetChapterId;

    final delta = (pageNumber - _currentPage).abs();
    if (delta >= _farJumpThreshold) {
      setState(() {
        _isJumpingFar = true;
      });
      () async {
        try {
          await _loadPageData(pageNumber);
          if (pageNumber > 1) _loadPageData(pageNumber - 1);
          if (pageNumber < totalPages) _loadPageData(pageNumber + 1);
          await Future.delayed(const Duration(milliseconds: 30));
          if (!mounted) return;
          _pageController.jumpToPage(pageNumber - 1);
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
      _pageController.animateToPage(
        pageNumber - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _showSurahList() {
    final currentChapterId = _lastSelectedChapterId ?? _pageChapters[_currentPage]?.id ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SurahListSheet(
        currentChapterId: currentChapterId,
        onSurahSelected: (pageNumber, chapterId) {
          _lastSelectedChapterId = chapterId;

          if (pageNumber == _currentPage) {
            setState(() {
              _scrollToChapterId = chapterId;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _performScrollToChapter(chapterId);
            });
          } else {
            _goToPage(pageNumber, targetChapterId: chapterId);
          }
        },
      ),
    );
  }
  
  void _showFontSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsMenuSheet(
        onFontSizeChanged: _updateFontSizes,
        onThemeChanged: widget.onThemeChanged,
        onViewModeChanged: () {
          // Görünüm modu değiştiğinde ekranı yeniden yükle
          _loadViewMode();
        },
      ),
    );
  }

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

  void _scheduleScrollSave(int pageNumber) {
    if (pageNumber != _currentPage) return;

    _scrollSaveTimer?.cancel();

    _scrollSaveTimer = Timer(_scrollSaveDelay, () {
      final scrollController = _pageScrollControllers[pageNumber];
      if (scrollController != null && scrollController.hasClients) {
        QuranJsonService.saveLastScrollPosition(pageNumber, scrollController.offset);
      }
    });
  }

  void _updateVisibleChapter(int pageNumber) {
    if (pageNumber != _currentPage) return;

    final scrollController = _pageScrollControllers[pageNumber];
    if (scrollController == null || !scrollController.hasClients) return;

    final pageKeysMap = _pageKeys[pageNumber];
    if (pageKeysMap == null || pageKeysMap.isEmpty) return;

    double headerBottom = 0.0;
    try {
      final headerBox = _headerKey.currentContext?.findRenderObject() as RenderBox?;
      if (headerBox != null) {
        final headerTop = headerBox.localToGlobal(Offset.zero).dy;
        headerBottom = headerTop + headerBox.size.height;
      }
    } catch (_) {
      headerBottom = headerBottom == 0.0 ? 180.0 : headerBottom;
    }
    const epsilon = 0.5;

    int? newVisibleChapterId;
    final positions = <MapEntry<int, double>>[];

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
      positions.sort((a, b) => a.value.compareTo(b.value));
      final underHeader = positions.where((e) => e.value <= headerBottom + epsilon).toList();
      if (underHeader.isNotEmpty) {
        newVisibleChapterId = underHeader.last.key;
      } else {
        newVisibleChapterId = _pageChapters[pageNumber]?.id;
      }
    }

    if (newVisibleChapterId != null && newVisibleChapterId != _currentVisibleChapterId) {
      setState(() {
        _currentVisibleChapterId = newVisibleChapterId;
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
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                  _buildFixedHeader(),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: totalPages,
                      reverse: true,
                      allowImplicitScrolling: true,
                      itemBuilder: (context, index) {
                        final pageNumber = index + 1;
                        final verses = _pageVerses[pageNumber];
                        final chapter = _pageChapters[pageNumber];

                        if (verses == null || chapter == null) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Color(0xFF2E7D32)),
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
    final displayChapterId = _currentVisibleChapterId ?? _pageChapters[_currentPage]?.id;
    final chapter = displayChapterId != null ? _chapterCache[displayChapterId] : _pageChapters[_currentPage];

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
              child: Icon(icon, color: Colors.white, size: 20),
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
    if (!_pageKeys.containsKey(pageNumber)) {
      _pageKeys[pageNumber] = {};
    }

    if (!_pageScrollControllers.containsKey(pageNumber)) {
      final scrollController = ScrollController();
      _pageScrollControllers[pageNumber] = scrollController;

      scrollController.addListener(() {
        _updateVisibleChapter(pageNumber);
        _scheduleScrollSave(pageNumber);
      });
    }

    final scrollController = _pageScrollControllers[pageNumber]!;
    final isWideView = _viewMode == ViewSettingsService.wideView;

    List<Widget> pageContent = [];
    int? lastChapterId;
    bool isFirstVerseOfPage = true;
    
    // Dinamik görünümde tüm ayetleri topla
    List<Verse> dynamicVerses = [];

    for (var verse in verses) {
      // Yeni bir sure başladı mı kontrol et
      if (verse.chapterId != lastChapterId) {
        // Eğer dinamik görünümdeyse ve toplanan ayetler varsa önce onları ekle
        if (!isWideView && dynamicVerses.isNotEmpty) {
          pageContent.add(_buildDynamicVerses(dynamicVerses));
          dynamicVerses.clear();
        }
        
        if (verse.verseNumber == 1) {
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
        isFirstVerseOfPage = false;
      }

      // Geniş görünümde her ayeti ayrı ekle
      if (isWideView) {
        pageContent.add(
          _buildArabicVerse(verse, isFirstVerseOfPage),
        );
        isFirstVerseOfPage = false;
      } else {
        // Dinamik görünümde ayetleri topla
        dynamicVerses.add(verse);
      }
    }
    
    // Dinamik görünümde kalan ayetleri ekle
    if (!isWideView && dynamicVerses.isNotEmpty) {
      pageContent.add(_buildDynamicVerses(dynamicVerses));
    }

    if (_scrollToChapterId != null && _pageKeys[pageNumber]?.containsKey(_scrollToChapterId) == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _pageKeys[pageNumber]![_scrollToChapterId];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.0,
          );
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

  Widget _buildArabicVerse(Verse verse, bool isFirst) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSajdah = verse.isSajdahVerse();
    final isWideView = _viewMode == ViewSettingsService.wideView;

    return Column(
      children: [
        // Ayraç SADECE geniş görünümde göster, dinamik görünümde HİÇ GÖSTERME
        if (!isFirst && isWideView) 
          VerseSeparator(),
        
        // Secde Badge (geniş görünümde)
        if (isSajdah && isWideView)
          Padding(
            padding: EdgeInsets.only(bottom: 8, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
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
            ),
          ),
        
        // Arapça metin
        Padding(
          padding: isWideView 
              ? EdgeInsets.symmetric(vertical: 8, horizontal: 4)
              : EdgeInsets.symmetric(vertical: 0, horizontal: 4),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: verse.textUthmani,
                        style: TextStyle(
                          fontFamily: 'Elif1',
                          fontSize: _arabicFontSize,
                          height: isWideView ? 2.2 : 1.3,
                          fontWeight: FontWeight.w500,
                          // Secde ayetleri için renkli vurgu
                          color: isSajdah
                              ? (isDark 
                                  ? Color(0xFFFF99CC) // Karanlık mod: Açık pembe
                                  : Color(0xFFbd2d2d)) // Aydınlık mod: Açık mor (eski mordan daha açık)
                              : (isDark ? Colors.white.withOpacity(0.95) : Colors.black87),
                        ),
                      ),
                      const TextSpan(text: ' '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Color(0xFFB8976A) : Color(0xFFB8976A),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            verse.getArabicVerseNumber(),
                            style: TextStyle(
                              fontFamily: 'ShaikhHamdullah',
                              fontSize: 18,
                              color: isDark ? Color(0xFFB8976A) : Color(0xFFB8976A),
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
        ),
      ],
    );
  }
  
  // Dinamik görünüm için - Tüm ayetler yan yana, alt satıra atlamadan
  Widget _buildDynamicVerses(List<Verse> verses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Tüm elemanları sırayla oluştur
    List<InlineSpan> spans = [];
    
    for (int i = 0; i < verses.length; i++) {
      final verse = verses[i];
      final isSajdah = verse.isSajdahVerse();
      
      // Ayet metni
      spans.add(
        TextSpan(
          text: verse.textUthmani,
          style: TextStyle(
            color: isSajdah
                ? (isDark 
                    ? Color(0xFFFF99CC) // Karanlık mod: Açık pembe
                    : Color(0xFFbd2d2d)) // Aydınlık mod: Açık mor
                : (isDark ? Colors.white.withOpacity(0.95) : Colors.black87),
          ),
        ),
      );
      
      spans.add(TextSpan(text: ' '));
      
      // Bir SONRAKİ ayetin secde ayeti olup olmadığını kontrol et
      // Secde badge'ini ayet numarasından ÖNCE ekle
      if (i + 1 < verses.length && verses[i + 1].isSajdahVerse()) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: EdgeInsets.only(left: 6, right: 6),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF8E24AA).withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.motion_photos_pause_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'SECDE AYETİ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        spans.add(TextSpan(text: ' '));
      }
      
      // Ayet numarası
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: EdgeInsets.only(right: 2, left: 2),
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Color(0xFFB8976A) : Color(0xFFB8976A),
                width: 2,
              ),
            ),
            child: Text(
              verse.getArabicVerseNumber(),
              style: TextStyle(
                fontFamily: 'ShaikhHamdullah',
                fontSize: 18,
                color: isDark ? Color(0xFFB8976A) : Color(0xFFB8976A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
      
      spans.add(TextSpan(text: ' '));
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: RichText(
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Elif1',
              fontSize: _arabicFontSize,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white.withOpacity(0.95) : Colors.black87,
            ),
            children: spans,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _paginationScrollController.dispose();
    _scrollSaveTimer?.cancel();

    for (var controller in _pageScrollControllers.values) {
      controller.dispose();
    }
    _pageScrollControllers.clear();

    super.dispose();
  }
}
