part of 'package:kuranmobil/screens/home_screen.dart';

// 🎨 Aurora Borealis Painter (Kuzey Işıkları)
class AuroraPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  AuroraPainter({required this.animationValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Aurora dalgaları - 3 katman
    for (int layer = 0; layer < 3; layer++) {
      final path = Path();
      final layerOffset = layer * 0.3;
      final amplitude = 80.0 - (layer * 15);
      final frequency = 0.003 + (layer * 0.001);

      path.moveTo(0, size.height * 0.3);

      for (double x = 0; x <= size.width; x += 5) {
        final wave1 =
            math.sin((x * frequency) + (animationValue * 2 * math.pi) + layerOffset) * amplitude;
        final wave2 = math.cos((x * frequency * 1.5) - (animationValue * 2 * math.pi) + layerOffset) *
            (amplitude * 0.5);
        final y = (size.height * 0.3) + wave1 + wave2;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();

      // Katmanlara göre gradient renkleri
      final colors = isDark
          ? [
              [Color(0xFF6366F1).withOpacity(0.15), Color(0xFF8B5CF6).withOpacity(0.08)],
              [Color(0xFF8B5CF6).withOpacity(0.12), Color(0xFFA855F7).withOpacity(0.06)],
              [Color(0xFFA855F7).withOpacity(0.10), Color(0xFF6366F1).withOpacity(0.04)],
            ]
          : [
              [Color(0xFF6366F1).withOpacity(0.25), Color(0xFF8B5CF6).withOpacity(0.15)],
              [Color(0xFF8B5CF6).withOpacity(0.20), Color(0xFFA855F7).withOpacity(0.12)],
              [Color(0xFFA855F7).withOpacity(0.18), Color(0xFF6366F1).withOpacity(0.10)],
            ];

      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors[layer],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(AuroraPainter oldDelegate) => true;
}
