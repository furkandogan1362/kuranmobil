import 'package:flutter/material.dart';
import '../../models/chapter.dart';

/// Sesli meal oynatıcısının başlık kısmı
class PlayerHeader extends StatelessWidget {
  final bool isDark;
  final int? currentSurah;
  final int? currentAyah;
  final Map<int, Chapter> chapters;
  final Chapter? chapter;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  const PlayerHeader({
    super.key,
    required this.isDark,
    required this.currentSurah,
    required this.currentAyah,
    required this.chapters,
    required this.chapter,
    required this.onMinimize,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
                    ? (chapters[currentSurah]?.nameArabic ?? 'Yükleniyor...')
                    : (chapter?.nameArabic ?? 'Yükleniyor...'),
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
                    ? '${chapters[currentSurah]?.nameTurkish ?? 'Sure $currentSurah'} - Ayet: $currentAyah'
                    : 'Lütfen sure seçin...',
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
        _buildHeaderButton(
          icon: Icons.keyboard_arrow_down_rounded,
          onTap: onMinimize,
        ),
        
        const SizedBox(width: 6),
        
        // Kapat butonu
        _buildHeaderButton(
          icon: Icons.close_rounded,
          onTap: onClose,
        ),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
            icon,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 16,
          ),
        ),
      ),
    );
  }
}
