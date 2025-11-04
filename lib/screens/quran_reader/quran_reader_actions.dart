// QuranReader ekranının iş mantığı: veri yükleme, gezinme, scroll ve ses oynatıcı eylemleri
part of '../quran_reader_screen.dart';

mixin _QuranReaderActions on State<QuranReaderScreen> {
  // Bu mixin'in ihtiyaç duyduğu alanlar (State içinde sağlanır)
  QuranJsonService get _jsonService;
  ScrollManager get _scrollManager;
  NavigationHelper get _navigationHelper;
  PageController get _pageController;
  set _pageController(PageController controller);
  ScrollController get _paginationScrollController;

  // State alanları
  double get _arabicFontSize;
  set _arabicFontSize(double v);
  double get _turkishFontSize;
  set _turkishFontSize(double v);
  int get _currentPage;
  set _currentPage(int v);
  int get _initialPage;
  set _initialPage(int v);
  bool get _isLoading;
  set _isLoading(bool v);
  String? get _errorMessage;
  set _errorMessage(String? v);
  int? get _lastSelectedChapterId;
  set _lastSelectedChapterId(int? v);
  int? get _scrollToChapterId;
  set _scrollToChapterId(int? v);
  int? get _currentVisibleChapterId;
  set _currentVisibleChapterId(int? v);
  bool get _isJumpingFar;
  set _isJumpingFar(bool v);

  bool get _isPlayerExpanded;
  set _isPlayerExpanded(bool v);
  bool get _isPlayerMinimized;
  set _isPlayerMinimized(bool v);

  GlobalKey get _headerKey;
  Map<int, List<Verse>> get _pageVerses;
  Map<int, Chapter> get _pageChapters;
  Map<int, Chapter> get _chapterCache;
  Map<int, Map<int, GlobalKey>> get _pageKeys;
  Map<int, Map<String, GlobalKey>> get _verseKeys;
  Map<int, ScrollController> get _pageScrollControllers;

  int get totalPagesCount; // instance getter olarak State içinde sağlanacak
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
            await Future.delayed(const Duration(milliseconds: 300));
            if (scrollController.hasClients && mounted) {
              // Smooth scroll ile kaydedilmiş pozisyona git
              scrollController.animateTo(
                savedPosition,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOutCubic,
              );
            }
          }
        }
      });

      // Önceki ve sonraki sayfaları önceden yükle (background)
      if (_currentPage > 1) _loadPageData(_currentPage - 1);
  if (_currentPage < totalPagesCount) _loadPageData(_currentPage + 1);
  if (_currentPage + 1 < totalPagesCount) _loadPageData(_currentPage + 2);
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
      // ignore: avoid_print
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
          await Future.delayed(const Duration(milliseconds: 300));
          if (scrollController.hasClients && mounted) {
            scrollController.animateTo(
              savedPosition,
              duration: const Duration(milliseconds: 800),
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
    if (pageNumber < totalPagesCount) {
      _loadPageData(pageNumber + 1);
    }
    if (pageNumber + 1 < totalPagesCount) {
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
      totalPages: totalPagesCount,
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
  }

  // Scroll pozisyonunu kaydetmeyi zamanla (debouncing)
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
      // ignore: avoid_print
      print('📄 Sayfa değiştiriliyor: $_currentPage -> $targetPage (Sure: $surahId, Ayet: $ayahNumber)');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            targetPage! - 1, // PageController 0-indexed
            duration: const Duration(milliseconds: 500),
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
}
