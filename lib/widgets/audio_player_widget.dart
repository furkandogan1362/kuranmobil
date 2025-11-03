import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/quran_json_service.dart';
import '../models/chapter.dart';
import 'audio_player/audio_control_buttons.dart';
import 'audio_player/speed_panel.dart';
import 'audio_player/surah_list_panel.dart';
import 'audio_player/minimized_player.dart';
import 'audio_player/player_header.dart';
import 'audio_player/control_toggle_buttons.dart';

/// Gelişmiş sesli meal oynatıcı widget'ı
class AudioPlayerWidget extends StatefulWidget {
  final Chapter? chapter;
  final int currentPage;
  final Map<int, Chapter> chapters;
  final List<dynamic>? currentPageVerses;
  final bool isExpanded;
  final bool isMinimized;
  final ValueChanged<bool> onExpandedChanged;
  final ValueChanged<bool> onMinimizedChanged;
  final ValueChanged<Chapter>? onChapterSelected; // Yeni callback
  
  const AudioPlayerWidget({
    super.key,
    required this.chapter,
    required this.currentPage,
    required this.chapters,
    this.currentPageVerses,
    required this.isExpanded,
    required this.isMinimized,
    required this.onExpandedChanged,
    required this.onMinimizedChanged,
    this.onChapterSelected,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isSpeedPanelExpanded = false; // Hız paneli için local state
  bool _isSurahListExpanded = false; // Sure listesi için local state
  List<Chapter>? _allChapters; // Tüm 114 surenin listesi
  final QuranJsonService _jsonService = QuranJsonService();
  final ScrollController _surahListScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAllChapters();
  }

  @override
  void dispose() {
    _surahListScrollController.dispose();
    super.dispose();
  }

  // Seçili sureye scroll yap
  void _scrollToCurrentSurah(int? currentSurah) {
    if (currentSurah == null || _allChapters == null) {
      print('❌ Scroll iptal: currentSurah=$currentSurah, chapters=${_allChapters?.length}');
      return;
    }
    
    print('🔍 Scroll başlatılıyor: Sure $currentSurah');
    
    // Her item'ın sabit yüksekliği: 50.0
    const itemHeight = 50.0;
    final targetIndex = currentSurah - 1; // Sure ID 1'den başlıyor, index 0'dan
    final scrollOffset = targetIndex * itemHeight;
    
    // Kısa bir gecikme sonrası scroll yap
    Future.delayed(Duration(milliseconds: 50), () {
      if (_surahListScrollController.hasClients) {
        final maxScroll = _surahListScrollController.position.maxScrollExtent;
        final targetScroll = scrollOffset.clamp(0.0, maxScroll);
        
        print('📍 Scroll hedef: $targetScroll (index: $targetIndex, max: $maxScroll)');
        
        _surahListScrollController.animateTo(
          targetScroll,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        print('⚠️  ScrollController hazır değil');
      }
    });
  }

  // Tüm 114 sureyi yükle
  Future<void> _loadAllChapters() async {
    List<Chapter> chapters = [];
    for (int i = 1; i <= 114; i++) {
      try {
        final chapter = await _jsonService.getChapterFromCache(i);
        chapters.add(chapter);
      } catch (e) {
        print('Sure $i yüklenirken hata: $e');
      }
    }

    if (mounted) {
      setState(() {
        _allChapters = chapters;
      });
    }
  }

  void _closePlayer(AudioService audioService) async {
    await audioService.stopAudio();
    widget.onExpandedChanged(false);
    widget.onMinimizedChanged(false);
    setState(() {
      _isSpeedPanelExpanded = false;
      _isSurahListExpanded = false;
    });
  }
  
  void _toggleMinimize() {
    if (widget.isExpanded && !widget.isMinimized) {
      widget.onExpandedChanged(false);
      widget.onMinimizedChanged(true);
      setState(() {
        _isSpeedPanelExpanded = false;
        _isSurahListExpanded = false;
      });
    }
  }

  void _expandPlayer() {
    widget.onMinimizedChanged(false);
    widget.onExpandedChanged(true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        // Widget hiç açılmamışsa gizle
        if (!widget.isExpanded && !widget.isMinimized) {
          return SizedBox.shrink();
        }
        
        // Minimize edilmişse sadece küçük bir gösterge
        if (widget.isMinimized) {
          return MinimizedPlayer(
            isDark: isDark,
            currentSurah: audioService.currentSurah,
            currentAyah: audioService.currentAyah,
            chapters: widget.chapters,
            onTap: _expandPlayer,
          );
        }
        
        return _buildExpandedPlayer(context, audioService, isDark);
      },
    );
  }

  Widget _buildExpandedPlayer(BuildContext context, AudioService audioService, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Color(0xFF1E293B), Color(0xFF0F172A)]
              : [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark 
                ? Color(0xFF10B981).withOpacity(0.3)
                : Color(0xFF2E7D32).withOpacity(0.2),
            width: 2,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üst çubuk
              _buildDragHandle(isDark),
              
              // Ana içerik
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Başlık
                    PlayerHeader(
                      isDark: isDark,
                      currentSurah: audioService.currentSurah,
                      currentAyah: audioService.currentAyah,
                      chapters: widget.chapters,
                      chapter: widget.chapter,
                      onMinimize: _toggleMinimize,
                      onClose: () => _closePlayer(audioService),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Oynatma kontrolleri
                    AudioControlButtons(
                      audioService: audioService,
                      isDark: isDark,
                      currentSurah: audioService.currentSurah,
                      currentAyah: audioService.currentAyah,
                      isPlaying: audioService.isPlaying,
                      isLoading: audioService.isLoading,
                      onPlayPressed: () => _handlePlayPress(audioService),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Toggle butonları
                    ControlToggleButtons(
                      isDark: isDark,
                      isSpeedPanelExpanded: _isSpeedPanelExpanded,
                      isSurahListExpanded: _isSurahListExpanded,
                      onSpeedToggle: () => setState(() {
                        _isSpeedPanelExpanded = !_isSpeedPanelExpanded;
                        if (_isSpeedPanelExpanded) _isSurahListExpanded = false;
                      }),
                      onSurahListToggle: () => setState(() {
                        _isSurahListExpanded = !_isSurahListExpanded;
                        if (_isSurahListExpanded) {
                          _isSpeedPanelExpanded = false;
                          _scrollToCurrentSurah(audioService.currentSurah);
                        }
                      }),
                    ),
                    
                    // Hız paneli
                    if (_isSpeedPanelExpanded) ...[
                      const SizedBox(height: 6),
                      SpeedPanel(
                        audioService: audioService,
                        isDark: isDark,
                        playbackSpeed: audioService.playbackSpeed,
                      ),
                    ],
                    
                    // Sure listesi
                    if (_isSurahListExpanded) ...[
                      const SizedBox(height: 6),
                      SurahListPanel(
                        allChapters: _allChapters,
                        currentSurah: audioService.currentSurah,
                        isDark: isDark,
                        scrollController: _surahListScrollController,
                        chapters: widget.chapters,
                        audioService: audioService,
                        onChapterSelected: (chapter) {
                          if (widget.onChapterSelected != null) {
                            widget.onChapterSelected!(chapter);
                          }
                        },
                        onListClosed: () => setState(() => _isSurahListExpanded = false),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withOpacity(0.3)
                : Colors.black.withOpacity(0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePlayPress(AudioService audioService) async {
    final isPlaying = audioService.isPlaying;
    final currentSurah = audioService.currentSurah;
    final currentAyah = audioService.currentAyah;

    if (isPlaying) {
      // Çalıyorsa duraklat
      await audioService.pauseAudio();
    } else if (currentSurah != null && currentAyah != null) {
      // Duraklatılmışsa devam ettir
      await audioService.resumeAudio();
    } else {
      // Hiç başlamamışsa başlat
      await _startPlaying(audioService);
    }
  }

  Future<void> _startPlaying(AudioService audioService) async {
    if (widget.chapter == null) return;

    final hasPermission = await audioService.requestPermissions();
    if (!hasPermission) return;

    int surahToPlay;
    int ayahToPlay;
    int totalAyahs;
    
    // ÖNCELİK 1: Kullanıcının scroll ile görünen sureyi kullan (visibleSurah)
    if (audioService.visibleSurah != null) {
      surahToPlay = audioService.visibleSurah!;
      
      // Bu sure'nin mevcut sayfada ilk ayetini bul
      if (widget.currentPageVerses != null && widget.currentPageVerses!.isNotEmpty) {
        try {
          final surahFirstVerse = widget.currentPageVerses!.firstWhere(
            (verse) => verse.chapterId == surahToPlay,
          );
          ayahToPlay = surahFirstVerse.verseNumber;
        } catch (e) {
          ayahToPlay = 1;
        }
      } else {
        ayahToPlay = 1;
      }
      
      final chapterToPlay = widget.chapters[surahToPlay];
      totalAyahs = chapterToPlay?.versesCount ?? 286;
      
      print('🎯 Görünen sure kullanılıyor: $surahToPlay (${chapterToPlay?.nameTurkish}), Ayet: $ayahToPlay');
    }
    // ÖNCELİK 2: Sayfanın ilk ayetini kullan
    else if (widget.currentPageVerses != null && widget.currentPageVerses!.isNotEmpty) {
      final firstVerse = widget.currentPageVerses!.first;
      surahToPlay = firstVerse.chapterId;
      ayahToPlay = firstVerse.verseNumber;
      final chapterToPlay = widget.chapters[surahToPlay];
      totalAyahs = chapterToPlay?.versesCount ?? 286;
      
      print('📄 Sayfa başı kullanılıyor: $surahToPlay, Ayet: $ayahToPlay');
    } 
    // FALLBACK: Chapter bilgisini kullan
    else {
      surahToPlay = widget.chapter?.id ?? 1;
      ayahToPlay = 1;
      final chapterToPlay = widget.chapters[surahToPlay] ?? widget.chapter;
      totalAyahs = chapterToPlay?.versesCount ?? 7;
      
      print('⚠️ Fallback kullanılıyor: $surahToPlay, Ayet: $ayahToPlay');
    }
    
    await audioService.playAyah(
      surahToPlay,
      ayahToPlay,
      totalAyahs: totalAyahs,
      chapters: widget.chapters,
    );

    if (context.mounted) {
      final playingChapter = widget.chapters[surahToPlay];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.volume_up, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('${playingChapter?.nameArabic ?? "Sure $surahToPlay"} - Ayet $ayahToPlay'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
