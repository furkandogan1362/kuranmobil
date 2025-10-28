import 'package:flutter/material.dart';

class SurahHeader extends StatelessWidget {
  const SurahHeader({
    super.key,
    required this.chapterId,
    required this.surahName,
    required this.showBesmele,
  });

  final int chapterId;
  final String surahName;
  final bool showBesmele;

  static const String _besmele = 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّح۪يمِ';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
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
        ),
        child: Column(
          children: [
            Text(
              '$surahName Sûresi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Color(0xFF4CAF50) : Color(0xFF1a237e),
              ),
              textAlign: TextAlign.center,
            ),
            if (showBesmele && chapterId != 9) ...[
              const SizedBox(height: 16),
              Text(
                _besmele,
                style: TextStyle(
                  fontFamily: 'ShaikhHamdullah',
                  fontSize: 32,
                  height: 2,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withOpacity(0.95) : Color(0xFF1a237e),
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
