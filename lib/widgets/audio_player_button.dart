import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../models/chapter.dart';

/// Sesli meal oynatma butonu
class AudioPlayerButton extends StatelessWidget {
  final Chapter? chapter;
  final int currentPage;
  
  const AudioPlayerButton({
    super.key,
    required this.chapter,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isPlaying = chapter != null && audioService.isSurahPlaying(chapter!.id);
        final isLoading = audioService.isLoading;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPlaying
                  ? [Color(0xFFEF4444), Color(0xFFDC2626)]
                  : [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isPlaying ? Color(0xFFEF4444) : Color(0xFF10B981))
                    .withOpacity(0.4),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading
                  ? null
                  : () async {
                      if (chapter == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sure bilgisi yüklenemedi'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      if (isPlaying) {
                        // Durduruluyor
                        await audioService.stopAudio();
                      } else {
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
                                  onPressed: () {
                                    // TODO: Uygulama ayarlarını aç
                                  },
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        
                        // Seslendirmeyi başlat
                        await audioService.playAyah(
                          chapter!.id,
                          1, // İlk ayetten başla
                          totalAyahs: chapter!.versesCount,
                        );
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.volume_up, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text('${chapter!.nameArabic} seslendiriliyor...'),
                                  ),
                                ],
                              ),
                              backgroundColor: Color(0xFF10B981),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      Icon(
                        isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    SizedBox(width: 8),
                    Text(
                      isPlaying ? 'Durdur' : 'Sesli Meal',
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
      },
    );
  }
}
