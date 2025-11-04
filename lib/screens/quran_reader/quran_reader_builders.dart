// QuranReader ekranı için UI kurucuları: header, bottom bar, sayfa içerikleri ve ana Scaffold
part of '../quran_reader_screen.dart';

mixin _QuranReaderBuilders on State<QuranReaderScreen> {
  // Gerekli alan ve yardımcılar (State içinde sağlanır)
  int get totalPagesCount;
  int get _currentPage;
  Map<int, Chapter> get _pageChapters;
  Map<int, Chapter> get _chapterCache;
  Map<int, List<Verse>> get _pageVerses;
  Map<int, Map<int, GlobalKey>> get _pageKeys;
  Map<int, Map<String, GlobalKey>> get _verseKeys;
  Map<int, ScrollController> get _pageScrollControllers;
  GlobalKey get _headerKey;
  PageController get _pageController;
  ScrollController get _paginationScrollController;
  int? get _currentVisibleChapterId;
  int? get _scrollToChapterId;
  set _scrollToChapterId(int? v);
  double get _arabicFontSize;
  double get _turkishFontSize;
  bool get _isJumpingFar;
  bool get _isPlayerExpanded;
  set _isPlayerExpanded(bool v);
  bool get _isPlayerMinimized;
  set _isPlayerMinimized(bool v);
  String? get _errorMessage;
  bool get _isLoading;

  // Actions'a delegasyon (aynı kütüphane içinde oldukları için erişilebilir)
  Future<void> _loadInitialPage();
  void _onPageChanged(int index);
  void _goToPage(int pageNumber, {int? targetChapterId});
  void _showSurahList();
  void _showFontSettings();
  void _updateVisibleChapter(int pageNumber);
  void _scheduleScrollSave(int pageNumber);
  void _scrollToPlayingVerse(int pageNumber, int surahId, int verseNumber);
  void _startAudioPlayer();

  Widget buildQuranReaderScaffold(BuildContext context) {
    if (_isLoading) return _buildLoadingScaffold(context);
    if (_errorMessage != null) return _buildErrorScaffold(context);
    return _buildMainScaffold(context);
  }

  Widget _buildLoadingScaffold(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF242324), Color(0xFF242324)]
                : const [Color(0xFF1a237e), Color(0xFF0d47a1)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              const SizedBox(height: 24),
              const Text(
                "Kur'an-ı Kerim yükleniyor...",
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

  Widget _buildErrorScaffold(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF242324), Color(0xFF242324)]
                : const [Color(0xFF1a237e), Color(0xFF0d47a1)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.white70),
                const SizedBox(height: 24),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadInitialPage,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
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

  Widget _buildMainScaffold(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                          ? const [Color(0xFF242324), Color(0xFF242324)]
                          : const [Color(0xFFFAF8F3), Color(0xFFF5F1E8)],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // Sabit başlık ve pagination
                        _buildFixedHeader(),

                        // Ana içerik - Sayfalar arası kaydırma
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: _onPageChanged,
                            itemCount: totalPagesCount,
                            reverse: true, // Sağdan sola kaydırma için
                            allowImplicitScrolling: true,
                            itemBuilder: (context, index) {
                              final pageNumber = index + 1;
                              final verses = _pageVerses[pageNumber];
                              final chapter = _pageChapters[pageNumber];

                              if (verses == null || chapter == null) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      CircularProgressIndicator(color: Color(0xFF2E7D32)),
                                      SizedBox(height: 16),
                                      Text(
                                        'Sayfa yükleniyor...',
                                        style: TextStyle(fontSize: 16, color: Colors.black54),
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
                  duration: const Duration(milliseconds: 400),
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
  totalPages: totalPagesCount,
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
    _pageKeys.putIfAbsent(pageNumber, () => {});

    // Bu sayfa için ayet key'lerini sakla
    _verseKeys.putIfAbsent(pageNumber, () => {});

    // Sure başlangıç ve ayet key'lerini oluştur
    for (var verse in verses) {
      if (verse.verseNumber == 1 && !_pageKeys[pageNumber]!.containsKey(verse.chapterId)) {
        _pageKeys[pageNumber]![verse.chapterId] = GlobalKey();
      }

      final verseKeyId = '${verse.chapterId}_${verse.verseNumber}';
      _verseKeys[pageNumber]!.putIfAbsent(verseKeyId, () => GlobalKey());
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
}
