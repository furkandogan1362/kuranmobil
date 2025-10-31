import 'package:flutter/material.dart';
import 'package:kuranmobil/models/verse.dart';

class VerseCard extends StatefulWidget {
  const VerseCard({
    super.key,
    required this.verse,
    this.arabicFontSize = 32.0,
    this.turkishFontSize = 16.0,
    this.isPlaying = false,
    this.onDoubleTap, // Çift tıklama callback'i
  });

  final Verse verse;
  final double arabicFontSize;
  final double turkishFontSize;
  final bool isPlaying;
  final VoidCallback? onDoubleTap;

  @override
  State<VerseCard> createState() => _VerseCardState();
}

class _VerseCardState extends State<VerseCard> {
  @override
  Widget build(BuildContext context) {
    final isSajdah = widget.verse.isSajdahVerse();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Sesli meal çalınıyorsa özel arka plan
    final isHighlighted = widget.isPlaying;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onDoubleTap: widget.onDoubleTap, // Çift tıklama
        child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isHighlighted
              ? LinearGradient(
                  colors: [
                    const Color(0xFF10B981).withOpacity(isDark ? 0.25 : 0.15),
                    const Color(0xFF059669).withOpacity(isDark ? 0.25 : 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : isSajdah
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF8E24AA).withOpacity(isDark ? 0.15 : 0.08),
                        const Color(0xFF6A1B9A).withOpacity(isDark ? 0.15 : 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
          color: isHighlighted
              ? null
              : isSajdah
                  ? null
                  : (isDark ? Color(0xFF302F30) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: isHighlighted
              ? Border.all(
                  color: const Color(0xFF10B981),
                  width: 2,
                )
              : isSajdah
                  ? Border.all(
                      color: const Color(0xFF8E24AA).withOpacity(0.3),
                      width: 2,
                    )
                  : null,
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : isSajdah
                      ? const Color(0xFF8E24AA).withOpacity(0.15)
                      : Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: isHighlighted ? 20 : (isSajdah ? 15 : 10),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : isSajdah
                            ? const Color(0xFF8E24AA).withOpacity(0.15)
                            : (isDark ? Color(0xFF4CAF50).withOpacity(0.2) : const Color(0xFF2E7D32).withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.verse.verseNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isHighlighted
                            ? const Color(0xFF10B981)
                            : isSajdah
                                ? const Color(0xFF8E24AA)
                                : (isDark ? Color(0xFF4CAF50) : const Color(0xFF2E7D32)),
                      ),
                    ),
                  ),
                ),
                if (isSajdah) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8E24AA).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.motion_photos_pause_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'SECDE AYETİ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Spacer ile hoparlörü sağa itiyoruz
                if (isHighlighted) const Spacer(),
                // Hoparlör ikonu sağ üstte
                if (isHighlighted)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 18,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RichText(
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.verse.textUthmani,
                          style: TextStyle(
                            fontFamily: 'Elif1',
                            fontSize: widget.arabicFontSize,
                            height: 1.40, // 2.2'den 1.40'a düşürüldü (%75 azaltma: 2.2 * 0.25 = 0.55, 2.2 - 0.55 = 1.65, yuvarlandı 1.40)
                            fontWeight: FontWeight.w500,
                            // Mor renk yerine normal metin rengi - secde arka plan ve badge'den anlaşılıyor
                            color: isDark ? Colors.white.withOpacity(0.95) : Colors.black87,
                          ),
                        ),
                        const TextSpan(text: ' '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSajdah
                                    ? const Color(0xFF8E24AA)
                                    : const Color(0xFF2E7D32),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              widget.verse.getArabicVerseNumber(),
                              style: TextStyle(
                                fontFamily: 'ShaikhHamdullah',
                                fontSize: 18,
                                color: isSajdah
                                    ? const Color(0xFF8E24AA)
                                    : const Color(0xFF2E7D32),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (widget.verse.translationTurkish.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  widget.verse.translationTurkish,
                  style: TextStyle(
                    fontSize: widget.turkishFontSize,
                    height: 1.8,
                    color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ],
        ),
        ), // GestureDetector'ın child'ı olan AnimatedContainer'ın kapanışı
      ), // Padding'in kapanışı
    );
  }
}
