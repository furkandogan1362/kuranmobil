// arabic_quran_reader_screen.dart'dan ayrıldı: mixin'lerin ihtiyaç duyduğu durum sözleşmesi
part of '../../arabic_quran_reader_screen.dart';

abstract class _ArabicQuranStateContract {
  // Flutter State API
  void setState(VoidCallback fn);
  bool get mounted;
  BuildContext get context;
  ArabicQuranReaderScreen get widget;

  // Controllers & Keys
  QuranJsonService get _jsonService;
  PageController get _pageController;
  set _pageController(PageController controller);
  ScrollController get _paginationScrollController;
  GlobalKey get _headerKey;

  // Flags & constants
  bool get _isJumpingFar;
  set _isJumpingFar(bool v);
  int get _farJumpThreshold;
  int get totalPages;

  // Data stores
  Map<int, List<Verse>> get _pageVerses;
  Map<int, Chapter> get _pageChapters;
  Map<int, Chapter> get _chapterCache;
  Map<int, Map<int, GlobalKey>> get _pageKeys;
  Map<int, ScrollController> get _pageScrollControllers;

  // Page state
  int get _currentPage;
  set _currentPage(int v);
  int get _initialPage;
  set _initialPage(int v);
  int? get _lastSelectedChapterId;
  set _lastSelectedChapterId(int? v);
  int? get _scrollToChapterId;
  set _scrollToChapterId(int? v);
  int? get _currentVisibleChapterId;
  set _currentVisibleChapterId(int? v);

  // UI state
  bool get _isLoading;
  set _isLoading(bool v);
  String? get _errorMessage;
  set _errorMessage(String? v);
  double get _arabicFontSize;
  set _arabicFontSize(double v);
  String get _viewMode;
  set _viewMode(String v);

  // Timers
  Timer? get _scrollSaveTimer;
  set _scrollSaveTimer(Timer? v);
  Duration get _scrollSaveDelay;

  // Cross-mixin methods (sözleşme için bildirildi)
  Future<void> _loadFontSettings();
  Future<void> _loadViewMode();
  void _updateFontSizes(double arabicSize, double turkishSize);
  Future<void> _loadLastPageAndInit();
  Future<void> _loadInitialPage();
  Future<void> _loadPageData(int pageNumber);
  void _onPageChanged(int index);
  void _scrollPaginationToPage(int pageNumber);
  void _goToPage(int pageNumber, {int? targetChapterId});
  void _showSurahList();
  void _showFontSettings();
  void _performScrollToChapter(int chapterId);
  void _scheduleScrollSave(int pageNumber);
  void _updateVisibleChapter(int pageNumber);
  Widget _buildFixedHeader();
  Widget _buildBottomNavigationBar();
  Widget _buildNavBarItem({required IconData icon, required String label, required VoidCallback onTap});
  Widget _buildQuranPage(int pageNumber, Chapter chapter, List<Verse> verses);
  Widget _buildArabicVerse(Verse verse, bool isFirst);
  Widget _buildDynamicVerses(List<Verse> verses);
}
