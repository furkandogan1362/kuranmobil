import 'package:flutter/material.dart';

class SurahHeader extends StatelessWidget {
  const SurahHeader({
    super.key,
    required this.chapterId,
    required this.surahName,
    required this.showBesmele,
    this.isPlaying = false,
  });

  final int chapterId;
  final String surahName;
  final bool showBesmele;
  final bool isPlaying;

  static const String _besmele = 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPlaying
                ? [
                    // Çalarken yeşil gradient (vurgulu)
                    const Color(0xFF4CAF50).withOpacity(0.3),
                    const Color(0xFF66BB6A).withOpacity(0.3),
                  ]
                : isDark
                    ? [
                        const Color(0xFF2E7D32).withOpacity(0.15),
                        const Color(0xFF4CAF50).withOpacity(0.15),
                      ]
                    : [
                        const Color(0xFF1a237e).withOpacity(0.05),
                        const Color(0xFF2E7D32).withOpacity(0.05),
                      ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: isPlaying
              ? Border.all(
                  color: const Color(0xFF4CAF50),
                  width: 2,
                )
              : null,
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isPlaying
                    ? (isDark ? Colors.white : const Color(0xFF1B5E20)) // Vurguluyken: Karanlık mod → Beyaz, Aydınlık mod → Koyu yeşil
                    : (isDark ? const Color(0xFF4CAF50) : const Color(0xFF1a237e)),
              ),
              child: Text(
                '$surahName Sûresi',
                textAlign: TextAlign.center,
              ),
            ),
            if (showBesmele && chapterId != 9) ...[
              const SizedBox(height: 16),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontFamily: 'ShaikhHamdullah',
                  fontSize: 32,
                  height: 2,
                  fontWeight: FontWeight.w600,
                  color: isPlaying
                      ? (isDark ? Colors.white : const Color(0xFF1B5E20)) // Vurguluyken: Karanlık mod → Beyaz, Aydınlık mod → Koyu yeşil
                      : (isDark ? Colors.white.withOpacity(0.95) : const Color(0xFF1a237e)),
                ),
                child: Text(
                  _besmele,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
