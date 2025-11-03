// Bu dosya, Arapça Kur'an okuyucu ekranının ana yapısıdır.
// Aşağıdaki parçalar bu dosyadan ayrılmış ve ilgili görevlerine göre gruplanmıştır:
// - arabic_quran_reader/parts/data_mixin.dart: veri yükleme/önbellekleme ve başlangıç işlemleri
// - arabic_quran_reader/parts/navigation_mixin.dart: sayfa geçişi, scroll ve görünür sure tespiti
// - arabic_quran_reader/parts/build_widgets_mixin.dart: UI alt bileşenleri ve ayet/sayfa çizimi

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

part 'arabic_quran_reader/parts/data_mixin.dart';
part 'arabic_quran_reader/parts/navigation_mixin.dart';
part 'arabic_quran_reader/parts/build_widgets_mixin.dart';
part 'arabic_quran_reader/parts/state_contract.dart';
part 'arabic_quran_reader/parts/base_state.dart';

class ArabicQuranReaderScreen extends StatefulWidget {
  final Function(String themeMode)? onThemeChanged;
  
  const ArabicQuranReaderScreen({super.key, this.onThemeChanged});

  @override
  State<ArabicQuranReaderScreen> createState() => _ArabicQuranReaderScreenState();
}

class _ArabicQuranReaderScreenState extends _ArabicQuranReaderBase
    with ArabicQuranDataMixin, ArabicQuranNavigationMixin, ArabicQuranBuildWidgetsMixin {
  final QuranJsonService _jsonService = QuranJsonService();
  late PageController _pageController;
  final ScrollController _paginationScrollController = ScrollController();
  final GlobalKey _headerKey = GlobalKey();
  bool _isJumpingFar = false;
  final int _farJumpThreshold = 1;

  final int totalPages = 604;

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
  final Duration _scrollSaveDelay = const Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _loadLastPageAndInit();
    _loadFontSettings();
    _loadViewMode();
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
