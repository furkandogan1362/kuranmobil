part of 'package:kuranmobil/screens/home_screen.dart';

// 🌟 Stars Painter (Statik ama pulse yapan yıldızlar)
class StarsPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  StarsPainter({required this.animationValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final random = math.Random(42); // Sabit seed - her zaman aynı yıldızlar
    final paint = Paint()..style = PaintingStyle.fill;

    // 30 yıldız çiz
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * canvasSize.width;
      final y = random.nextDouble() * canvasSize.height;
      final baseSize = random.nextDouble() * 1.5 + 0.5;
      final phaseOffset = random.nextDouble() * math.pi * 2;

      // Pulse efekti
      final pulse = 0.6 + math.sin(animationValue * 3 * math.pi + phaseOffset) * 0.4;
      final starSize = baseSize * pulse;
      final opacity = (isDark ? 0.7 : 0.5) * pulse;

      paint.color = Colors.white.withOpacity(opacity);

      // Yıldız glow
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, starSize * 3);

      final position = Offset(x, y);
      canvas.drawCircle(position, starSize * 4, glowPaint);
      canvas.drawCircle(position, starSize, paint);

      // Cross shape (yıldız haç şekli)
      if (pulse > 0.8) {
        paint.strokeWidth = 0.5;
        paint.style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(x - starSize * 2, y),
          Offset(x + starSize * 2, y),
          paint,
        );
        canvas.drawLine(
          Offset(x, y - starSize * 2),
          Offset(x, y + starSize * 2),
          paint,
        );
        paint.style = PaintingStyle.fill;
      }
    }
  }

  @override
  bool shouldRepaint(StarsPainter oldDelegate) => true;
}
