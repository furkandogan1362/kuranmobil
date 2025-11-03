part of 'package:kuranmobil/screens/home_screen.dart';

// Parçacık sınıfı
class Particle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double opacity;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
    required this.color,
  });
}

// ✨ Particle Painter (Yüzen Parçacıklar)
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter({required this.particles, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      // Parçacık pozisyonunu güncelle
      particle.x += particle.speedX;
      particle.y += particle.speedY;

      // Ekran sınırlarını kontrol et ve geri döndür
      if (particle.x < 0 || particle.x > 1) particle.speedX *= -1;
      if (particle.y < 0 || particle.y > 1) particle.speedY *= -1;

      // Pulse efekti için opacity
      final pulseOpacity =
          particle.opacity * (0.7 + math.sin(animationValue * 4 * math.pi + particle.x * 10) * 0.3);

      final paint = Paint()
        ..color = particle.color.withOpacity(pulseOpacity)
        ..style = PaintingStyle.fill;

      // Parçacık glow efekti
      final glowPaint = Paint()
        ..color = particle.color.withOpacity(pulseOpacity * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 2);

      final position = Offset(particle.x * size.width, particle.y * size.height);

      // Glow
      canvas.drawCircle(position, particle.size * 3, glowPaint);
      // Core
      canvas.drawCircle(position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
