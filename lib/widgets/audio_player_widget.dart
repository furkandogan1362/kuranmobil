import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/quran_json_service.dart';
import '../models/chapter.dart';

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
    // Expanded'dan minimize'a geç
    if (widget.isExpanded && !widget.isMinimized) {
      widget.onExpandedChanged(false);
      widget.onMinimizedChanged(true);
      setState(() {
        _isSpeedPanelExpanded = false;
        _isSurahListExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isPlaying = audioService.isPlaying;
        final isLoading = audioService.isLoading;
        final currentSurah = audioService.currentSurah;
        final currentAyah = audioService.currentAyah;
        final playbackSpeed = audioService.playbackSpeed;
        
        // Widget hiç açılmamışsa gizle
        // NOT: isExpanded sadece hız panelini kontrol eder, widget açılmışsa bile false olabilir
        if (!widget.isExpanded && !widget.isMinimized) {
          return SizedBox.shrink();
        }
        
        // Minimize edilmişse sadece küçük bir gösterge
        if (widget.isMinimized) {
          return GestureDetector(
            onTap: () {
              // Minimize edilmişse tam aç
              widget.onMinimizedChanged(false);
              widget.onExpandedChanged(true);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Color(0xFF1E293B), Color(0xFF0F172A)]
                      : [Colors.white, Color(0xFFFAFAFA)],
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark 
                        ? Color(0xFF10B981).withOpacity(0.3)
                        : Color(0xFF2E7D32).withOpacity(0.2),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                    currentSurah != null && currentAyah != null
                        ? '${widget.chapters[currentSurah]?.nameTurkish ?? 'Sure $currentSurah'} - Ayet: $currentAyah'
                        : 'Sesli meal çalıyor...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Minimize'dan tam açmaya geç
                    widget.onMinimizedChanged(false);
                    widget.onExpandedChanged(true);
                  },
                  icon: Icon(
                    Icons.expand_less_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            ),
          );
        }
        
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
                  Container(
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
                  ),
                  
                  // Ana içerik
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sure ve Ayet bilgisi + Kapat butonu
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.graphic_eq_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    currentSurah != null 
                                        ? (widget.chapters[currentSurah]?.nameArabic ?? 'Yükleniyor...')
                                        : (widget.chapter?.nameArabic ?? 'Yükleniyor...'),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    currentSurah != null && currentAyah != null
                                        ? '${widget.chapters[currentSurah]?.nameTurkish ?? 'Sure $currentSurah'} - Ayet: $currentAyah'
                                        : 'Yükleniyor...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Minimize butonu
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _toggleMinimize,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 6),
                            
                            // Kapat butonu
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _closePlayer(audioService),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Oynatma kontrolleri
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildControlButton(
                              icon: Icons.skip_previous_rounded,
                              onPressed: (currentSurah != null && currentAyah != null) 
                                  ? () => audioService.previousAyah() 
                                  : null,
                              isDark: isDark,
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Ana oynat/durdur butonu
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isPlaying
                                      ? [Color(0xFFFBBF24), Color(0xFFF59E0B)] // Sarı - duraklat için
                                      : [Color(0xFF10B981), Color(0xFF059669)], // Yeşil - oynat için
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isPlaying ? Color(0xFFF59E0B) : Color(0xFF10B981))
                                        .withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                shape: CircleBorder(),
                                child: InkWell(
                                  customBorder: CircleBorder(),
                                  onTap: () async {
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
                                  },
                                  child: Center(
                                    child: isLoading
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Icon(
                                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            _buildControlButton(
                              icon: Icons.skip_next_rounded,
                              onPressed: (currentSurah != null && currentAyah != null) 
                                  ? () => audioService.nextAyah() 
                                  : null,
                              isDark: isDark,
                            ),
                          ],
                        ),
                        
                        // Butonlar (Hız ve Sureler)
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hız butonu
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => setState(() {
                                  _isSpeedPanelExpanded = !_isSpeedPanelExpanded;
                                  if (_isSpeedPanelExpanded) _isSurahListExpanded = false;
                                }),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _isSpeedPanelExpanded
                                        ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.speed_rounded,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Hız',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Sure Listesi butonu
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _isSurahListExpanded = !_isSurahListExpanded;
                                    if (_isSurahListExpanded) {
                                      _isSpeedPanelExpanded = false;
                                      // Sure listesi açıldığında mevcut sureye scroll yap
                                      _scrollToCurrentSurah(currentSurah);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _isSurahListExpanded
                                        ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.list_rounded,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Sureler',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Genişletilmiş kontroller (Hız paneli)
                        if (_isSpeedPanelExpanded) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Hız',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${playbackSpeed}x',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: Color(0xFF10B981),
                                    inactiveTrackColor: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.1),
                                    thumbColor: Color(0xFF10B981),
                                    overlayColor: Color(0xFF10B981).withOpacity(0.2),
                                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
                                    trackHeight: 3,
                                  ),
                                  child: Slider(
                                    value: playbackSpeed,
                                    min: 0.5,
                                    max: 2.0,
                                    divisions: 6,
                                    onChanged: (value) => audioService.setPlaybackSpeed(value),
                                  ),
                                ),
                                Wrap(
                                  spacing: 6,
                                  alignment: WrapAlignment.center,
                                  children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                                      .map((speed) => _buildSpeedChip(audioService, speed, isDark))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        // Genişletilmiş kontroller (Sure Listesi)
                        if (_isSurahListExpanded) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Sureler',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '114 Sure',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Yükleniyor göstergesi veya liste
                                _allChapters == null
                                    ? Container(
                                        height: 100,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                color: Color(0xFF10B981),
                                                strokeWidth: 2,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Sureler yükleniyor...',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isDark ? Colors.white60 : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Container(
                                        constraints: BoxConstraints(
                                          maxHeight: 250, // Maksimum yükseklik
                                        ),
                                        child: ListView.builder(
                                          controller: _surahListScrollController,
                                          shrinkWrap: true,
                                          itemExtent: 50.0, // Her item'ın sabit yüksekliği
                                          itemCount: _allChapters!.length, // Tüm sureler
                                          itemBuilder: (context, index) {
                                            final chapter = _allChapters![index];
                                            final chapterId = chapter.id;
                                            final isCurrentSurah = currentSurah == chapterId;
                                            
                                            return Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () async {
                                                  // Sure seçildiğinde:
                                                  // 1. Listeyi kapat
                                                  setState(() => _isSurahListExpanded = false);
                                                  
                                                  // 2. Callback ile parent'a bildir
                                                  if (widget.onChapterSelected != null) {
                                                    widget.onChapterSelected!(chapter);
                                                    
                                                    // 3. Kısa gecikme sonrası oynat
                                                    await Future.delayed(Duration(milliseconds: 800));
                                                    await audioService.playAyah(
                                                      chapterId,
                                                      1,
                                                      totalAyahs: chapter.versesCount,
                                                      chapters: widget.chapters,
                                                    );
                                                  }
                                                },
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            margin: EdgeInsets.symmetric(vertical: 2),
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            decoration: BoxDecoration(
                                              gradient: isCurrentSurah
                                                  ? LinearGradient(
                                                      colors: [
                                                        Color(0xFF10B981).withOpacity(0.2),
                                                        Color(0xFF059669).withOpacity(0.2),
                                                      ],
                                                    )
                                                  : null,
                                              color: isCurrentSurah ? null : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              border: isCurrentSurah
                                                  ? Border.all(
                                                      color: Color(0xFF10B981).withOpacity(0.5),
                                                      width: 1,
                                                    )
                                                  : null,
                                            ),
                                            child: Row(
                                              children: [
                                                // Sure numarası
                                                Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: isCurrentSurah
                                                        ? Color(0xFF10B981)
                                                        : (isDark 
                                                            ? Colors.white.withOpacity(0.1)
                                                            : Colors.black.withOpacity(0.05)),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '$chapterId',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: isCurrentSurah
                                                            ? Colors.white
                                                            : (isDark ? Colors.white70 : Colors.black54),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                
                                                // Sure bilgileri
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        chapter.nameTurkish,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: isCurrentSurah ? FontWeight.bold : FontWeight.w600,
                                                          color: isCurrentSurah
                                                              ? Color(0xFF10B981)
                                                              : (isDark ? Colors.white : Colors.black87),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${chapter.versesCount} Ayet',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          color: isDark ? Colors.white60 : Colors.black54,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                
                                                // Arapça sure adı
                                                Text(
                                                  chapter.nameArabic,
                                                  style: TextStyle(
                                                    fontFamily: 'ShaikhHamdullah',
                                                    fontSize: 14,
                                                    color: isCurrentSurah
                                                        ? Color(0xFF10B981)
                                                        : (isDark ? Colors.white70 : Colors.black54),
                                                  ),
                                                ),
                                                
                                                if (isCurrentSurah) ...[
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    Icons.graphic_eq_rounded,
                                                    color: Color(0xFF10B981),
                                                    size: 16,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                      ),
                              ],
                            ),
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
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    final isEnabled = onPressed != null;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isEnabled
            ? (isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05))
            : (isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02)),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isEnabled
              ? (isDark ? Colors.white : Colors.black87)
              : (isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)),
          size: 20,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
  
  Widget _buildSpeedChip(AudioService audioService, double speed, bool isDark) {
    final isSelected = audioService.playbackSpeed == speed;
    return GestureDetector(
      onTap: () => audioService.setPlaybackSpeed(speed),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
              : null,
          color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${speed}x',
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
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
          // Görünen sure'nin bu sayfadaki ilk ayetini bul
          final surahFirstVerse = widget.currentPageVerses!.firstWhere(
            (verse) => verse.chapterId == surahToPlay,
          );
          ayahToPlay = surahFirstVerse.verseNumber;
        } catch (e) {
          // Bu sayfada bu sure yoksa, sure'nin 1. ayetinden başla
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
