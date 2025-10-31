import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../models/chapter.dart';

/// Gelişmiş sesli meal oynatıcı widget'ı
class AudioPlayerWidget extends StatefulWidget {
  final Chapter? chapter;
  final int currentPage;
  final Map<int, Chapter> chapters; // Tüm sure bilgileri
  final List<dynamic>? currentPageVerses; // Mevcut sayfadaki ayetler
  
  const AudioPlayerWidget({
    super.key,
    required this.chapter,
    required this.currentPage,
    required this.chapters,
    this.currentPageVerses,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
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
        
        // Eğer ses çalmıyorsa sadece kompakt buton göster
        if (!isPlaying && !isLoading) {
          return _buildCompactButton(context, audioService, isDark);
        }
        
        // Ses çalıyorsa oynatıcıyı göster
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Color(0xFF1F2937), Color(0xFF111827)]
                  : [Colors.white, Color(0xFFF9FAFB)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Üst kısım - Sure/Ayet bilgisi ve temel kontroller
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Sure ve Ayet bilgisi
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.volume_up_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSurah != null 
                                      ? (widget.chapters[currentSurah]?.nameArabic ?? 'Yükleniyor...')
                                      : (widget.chapter?.nameArabic ?? 'Yükleniyor...'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentSurah != null && currentAyah != null
                                      ? '${widget.chapters[currentSurah]?.nameTurkish ?? 'Sure $currentSurah'} - Ayet: $currentAyah'
                                      : 'Yükleniyor...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Genişlet/Daralt butonu
                          IconButton(
                            onPressed: _toggleExpanded,
                            icon: AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.expand_more_rounded,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Oynatma kontrolleri
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Önceki ayet
                          _buildControlButton(
                            context,
                            icon: Icons.skip_previous_rounded,
                            onPressed: audioService.isPlaying
                                ? () => audioService.previousAyah()
                                : null,
                            isDark: isDark,
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Ana oynat/durdur butonu
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isPlaying
                                    ? [Color(0xFFEF4444), Color(0xFFDC2626)]
                                    : [Color(0xFF10B981), Color(0xFF059669)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isPlaying ? Color(0xFFEF4444) : Color(0xFF10B981))
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
                                onTap: isLoading
                                    ? null
                                    : () async {
                                        if (isPlaying) {
                                          await audioService.pauseAudio();
                                        } else if (currentSurah != null) {
                                          await audioService.resumeAudio();
                                        } else {
                                          await _startPlaying(audioService);
                                        }
                                      },
                                child: Center(
                                  child: isLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Icon(
                                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Sonraki ayet
                          _buildControlButton(
                            context,
                            icon: Icons.skip_next_rounded,
                            onPressed: audioService.isPlaying
                                ? () => audioService.nextAyah()
                                : null,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Genişletilmiş kontroller
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Container(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            children: [
                              Divider(color: isDark ? Colors.white10 : Colors.black12),
                              const SizedBox(height: 8),
                              
                              // Hız kontrolü
                              Row(
                                children: [
                                  Icon(
                                    Icons.speed_rounded,
                                    size: 20,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Oynatma Hızı',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              '${playbackSpeed}x',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF10B981),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Slider(
                                          value: playbackSpeed,
                                          min: 0.5,
                                          max: 2.0,
                                          divisions: 6,
                                          label: '${playbackSpeed}x',
                                          activeColor: Color(0xFF10B981),
                                          onChanged: (value) {
                                            audioService.setPlaybackSpeed(value);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Durdur butonu
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await audioService.stopAudio();
                                    setState(() {
                                      _isExpanded = false;
                                      _expandController.reverse();
                                    });
                                  },
                                  icon: Icon(Icons.stop_rounded),
                                  label: Text('Durdur'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactButton(BuildContext context, AudioService audioService, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startPlaying(audioService),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: 8),
                Text(
                  'Sesli Meal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null
              ? (isDark ? Colors.white : Colors.black87)
              : (isDark ? Colors.white30 : Colors.black26),
        ),
        iconSize: 24,
      ),
    );
  }

  Future<void> _startPlaying(AudioService audioService) async {
    if (widget.chapter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sure bilgisi yüklenemedi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // İzin kontrolü
    final hasPermission = await audioService.requestPermissions();
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses dosyalarını indirmek için depolama izni gerekli'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Ayarlar',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      return;
    }

    // Oynatılacak sure ve ayeti belirle
    int surahToPlay;
    int ayahToPlay;
    int totalAyahs;
    
    // ÖNCELİK 1: Kullanıcı scroll ile bir sure başlığına geldiyse (visibleSurah)
    if (audioService.visibleSurah != null) {
      surahToPlay = audioService.visibleSurah!;
      
      // O surenin sayfadaki ilk ayetini bul
      if (widget.currentPageVerses != null && widget.currentPageVerses!.isNotEmpty) {
        try {
          final surahFirstVerse = widget.currentPageVerses!.firstWhere(
            (verse) => verse.chapterId == surahToPlay,
          );
          ayahToPlay = surahFirstVerse.verseNumber;
        } catch (e) {
          // Sure bu sayfada yoksa, ilk ayetten başla
          ayahToPlay = widget.currentPageVerses!.first.verseNumber;
        }
      } else {
        ayahToPlay = 1; // Fallback: Sure başından başla
      }
      
      final chapterToPlay = widget.chapters[surahToPlay];
      totalAyahs = chapterToPlay?.versesCount ?? 286;
      
      print('👁️ Görünen sure: $surahToPlay (${chapterToPlay?.nameTurkish})');
      print('🎬 Seslendirme başlatılıyor - Sure: $surahToPlay, Ayet: $ayahToPlay (Toplam: $totalAyahs)');
    }
    // ÖNCELİK 2: Sayfadaki ilk ayetten başla
    else if (widget.currentPageVerses != null && widget.currentPageVerses!.isNotEmpty) {
      final firstVerse = widget.currentPageVerses!.first;
      surahToPlay = firstVerse.chapterId;
      ayahToPlay = firstVerse.verseNumber;
      
      final chapterToPlay = widget.chapters[surahToPlay];
      totalAyahs = chapterToPlay?.versesCount ?? 286;
      
      print('📄 Sayfa ${widget.currentPage}: İlk ayet = $surahToPlay:$ayahToPlay');
      print('🎬 Seslendirme başlatılıyor - Sure: $surahToPlay (${chapterToPlay?.nameTurkish}), $ayahToPlay. ayetten başlayarak (Toplam: $totalAyahs ayet)');
    } 
    // ÖNCELİK 3: Fallback
    else {
      surahToPlay = widget.chapter?.id ?? 1;
      ayahToPlay = 1;
      final chapterToPlay = widget.chapters[surahToPlay] ?? widget.chapter;
      totalAyahs = chapterToPlay?.versesCount ?? 7;
      
      print('🎬 Seslendirme başlatılıyor (fallback) - Sure: $surahToPlay (${chapterToPlay?.nameTurkish}), Ayet sayısı: $totalAyahs');
    }
    
    // Seslendirmeyi başlat (chapters map'i de gönder)
    await audioService.playAyah(
      surahToPlay,
      ayahToPlay,
      totalAyahs: totalAyahs,
      chapters: widget.chapters, // Sure bilgilerini gönder (otomatik geçiş için)
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
