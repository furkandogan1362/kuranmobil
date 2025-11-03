import 'package:flutter/material.dart';
import '../../services/audio_service.dart';

/// Sesli meal oynatıcısının oynatma kontrol butonları
class AudioControlButtons extends StatelessWidget {
  final AudioService audioService;
  final bool isDark;
  final int? currentSurah;
  final int? currentAyah;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPlayPressed;

  const AudioControlButtons({
    super.key,
    required this.audioService,
    required this.isDark,
    required this.currentSurah,
    required this.currentAyah,
    required this.isPlaying,
    required this.isLoading,
    required this.onPlayPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        _buildMainPlayButton(),
        
        const SizedBox(width: 16),
        _buildControlButton(
          icon: Icons.skip_next_rounded,
          onPressed: (currentSurah != null && currentAyah != null)
              ? () => audioService.nextAyah()
              : null,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildMainPlayButton() {
    return Container(
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
          onTap: onPlayPressed,
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
            ? (isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05))
            : (isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02)),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isEnabled
              ? (isDark ? Colors.white : Colors.black87)
              : (isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.2)),
          size: 20,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
