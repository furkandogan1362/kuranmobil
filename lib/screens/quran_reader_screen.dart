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

part 'quran_reader/quran_reader_actions.dart';
part 'quran_reader/quran_reader_builders.dart';

class QuranReaderScreen extends StatefulWidget {
  final Function(String themeMode)? onThemeChanged;
  
  const QuranReaderScreen({super.key, this.onThemeChanged});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen>
    with _QuranReaderActions, _QuranReaderBuilders {
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
  // Mixin'ler için instance üzerinden kullanılabilir hale getir
  int get totalPagesCount => _QuranReaderScreenState.totalPages;

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
  @override
  Widget build(BuildContext context) {
    return buildQuranReaderScaffold(context);
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
