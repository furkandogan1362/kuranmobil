import 'package:flutter/material.dart';
import '../../models/chapter.dart';

/// Küçültülmüş sesli meal oynatıcı görünümü
class MinimizedPlayer extends StatelessWidget {
  final bool isDark;
  final int? currentSurah;
  final int? currentAyah;
  final Map<int, Chapter> chapters;
  final VoidCallback onTap;

  const MinimizedPlayer({
    super.key,
    required this.isDark,
    required this.currentSurah,
    required this.currentAyah,
    required this.chapters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                    ? '${chapters[currentSurah]?.nameTurkish ?? 'Sure $currentSurah'} - Ayet: $currentAyah'
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
              onPressed: onTap,
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
}
