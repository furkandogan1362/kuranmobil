import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'quran_reader_screen.dart';
import 'arabic_quran_reader_screen.dart';
import 'dart:math' as math;

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

class HomeScreen extends StatefulWidget {
  final Function(String themeMode)? onThemeChanged;
  
  const HomeScreen({super.key, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late AnimationController _animationController;
  late AnimationController _particleController;
  late AnimationController _auroraController;
  late AnimationController _meshController;
  List<Particle> particles = [];
  bool _isPageActive = true;
  
  // Animasyon değerlerini sakla
  double? _savedAnimationValue;
  double? _savedParticleValue;
  double? _savedAuroraValue;
  double? _savedMeshValue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Ana animasyon controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    // Parçacık animasyon controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    
    // Aurora animasyon controller (daha yavaş, daha smooth)
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    
    // Mesh gradient controller (organik hareket)
    _meshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
    
    // Parçacıkları oluştur
    _initParticles();
  }
  
  void _initParticles() {
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      particles.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 3 + 1,
          speedX: (random.nextDouble() - 0.5) * 0.0005,
          speedY: (random.nextDouble() - 0.5) * 0.0005,
          opacity: random.nextDouble() * 0.6 + 0.2,
          color: Color.lerp(
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            random.nextDouble(),
          )!,
        ),
      );
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Uygulama durumuna göre animasyonları kontrol et
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pauseAnimations();
    } else if (state == AppLifecycleState.resumed && _isPageActive) {
      _resumeAnimations();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa ilk yüklendiğinde animasyonları başlat
    if (_isPageActive) {
      _resumeAnimations();
    }
  }
  
  // Sayfa görünürlük metodları
  void didPushNext() {
    // Başka bir sayfaya gidildiğinde
    _isPageActive = false;
    _pauseAnimations();
  }
  
  void didPopNext() {
    // Üstteki sayfa kapatıldığında (bu sayfa tekrar görünür olduğunda)
    _isPageActive = true;
    _resumeAnimations();
  }
  
  void _pauseAnimations() {
    // Animasyon değerlerini kaydet
    if (mounted) {
      _savedAnimationValue = _animationController.value;
      _savedParticleValue = _particleController.value;
      _savedAuroraValue = _auroraController.value;
      _savedMeshValue = _meshController.value;
      
      // Animasyonları duraklat
      if (_animationController.isAnimating) {
        _animationController.stop(canceled: false);
      }
      if (_particleController.isAnimating) {
        _particleController.stop(canceled: false);
      }
      if (_auroraController.isAnimating) {
        _auroraController.stop(canceled: false);
      }
      if (_meshController.isAnimating) {
        _meshController.stop(canceled: false);
      }
    }
  }
  
  void _resumeAnimations() {
    // Kaydedilmiş değerlerden devam et
    if (mounted && _isPageActive) {
      if (!_animationController.isAnimating) {
        if (_savedAnimationValue != null) {
          _animationController.value = _savedAnimationValue!;
        }
        _animationController.repeat();
      }
      if (!_particleController.isAnimating) {
        if (_savedParticleValue != null) {
          _particleController.value = _savedParticleValue!;
        }
        _particleController.repeat();
      }
      if (!_auroraController.isAnimating) {
        if (_savedAuroraValue != null) {
          _auroraController.value = _savedAuroraValue!;
        }
        _auroraController.repeat();
      }
      if (!_meshController.isAnimating) {
        if (_savedMeshValue != null) {
          _meshController.value = _savedMeshValue!;
        }
        _meshController.repeat();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _particleController.dispose();
    _auroraController.dispose();
    _meshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // 🌌 KATMANLARın BASE: Koyu gradient zemin
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        Color(0xFF0A0E27), // Derin koyu mavi
                        Color(0xFF1A1F3A), // Orta ton
                        Color(0xFF0F1629), // Koyu geri dönüş
                      ]
                    : [
                        Color(0xFF0F1B35), // Gece mavisi
                        Color(0xFF1E3A8A), // Royal blue
                        Color(0xFF1E293B), // Slate
                      ],
              ),
            ),
          ),
          
          // 🎨 KATMAN 1: Aurora Borealis (Kuzey Işıkları) - Yavaş dalgalanma
          AnimatedBuilder(
            animation: _auroraController,
            builder: (context, child) {
              return CustomPaint(
                painter: AuroraPainter(
                  animationValue: _auroraController.value,
                  isDark: isDark,
                ),
                child: Container(),
              );
            },
          ),
          
          // 🌊 KATMAN 2: Mesh Gradient (Organik Bloblar) - 3 katman parallax
          AnimatedBuilder(
            animation: _meshController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Blob 1 - En yavaş (en uzak katman)
                  Positioned(
                    top: -200 + math.sin(_meshController.value * 2 * math.pi) * 50,
                    right: -200 + math.cos(_meshController.value * 2 * math.pi) * 60,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFF8B5CF6).withOpacity(isDark ? 0.08 : 0.15),
                            Color(0xFF8B5CF6).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Blob 2 - Orta hız
                  Positioned(
                    bottom: -250 + math.cos(_meshController.value * 2.5 * math.pi) * 70,
                    left: -250 + math.sin(_meshController.value * 2.5 * math.pi) * 80,
                    child: Container(
                      width: 600,
                      height: 600,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFF6366F1).withOpacity(isDark ? 0.1 : 0.18),
                            Color(0xFF6366F1).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Blob 3 - En hızlı (en yakın katman)
                  Positioned(
                    top: 100 + math.sin(_meshController.value * 3 * math.pi) * 40,
                    left: 50 + math.cos(_meshController.value * 3 * math.pi) * 50,
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFFA855F7).withOpacity(isDark ? 0.12 : 0.22),
                            Color(0xFFA855F7).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // ✨ KATMAN 3: Yüzen Parçacıklar (Starfield)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(
                  particles: particles,
                  animationValue: _particleController.value,
                ),
                child: Container(),
              );
            },
          ),
          
          // 🌟 KATMAN 4: Parlayan yıldızlar (statik ama pulse efektli)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: StarsPainter(
                  animationValue: _animationController.value,
                  isDark: isDark,
                ),
                child: Container(),
              );
            },
          ),
          
          // İçerik
          SafeArea(
            child: Column(
              children: [
                // Başlık
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
                  child: Column(
                    children: [
                      // Bismillah ikonu/dekorasyon
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    Color(0xFF6366F1).withOpacity(0.2),
                                    Color(0xFF8B5CF6).withOpacity(0.2),
                                  ]
                                : [
                                    Color(0xFF8B5CF6).withOpacity(0.4),
                                    Color(0xFF6366F1).withOpacity(0.4),
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Color(0xFF6366F1) : Color(0xFF8B5CF6)).withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms)
                        .scale(delay: 200.ms, duration: 600.ms)
                        .then()
                        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
                      
                      SizedBox(height: 24),
                      
                      Text(
                        'Hoş Geldiniz',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ).animate()
                        .fadeIn(duration: 600.ms, delay: 300.ms)
                        .slideY(begin: -0.3, end: 0),
                      
                      SizedBox(height: 8),
                      
                      Text(
                        'İslami Kaynaklarınız',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Color(0xFFCBD5E1) : Color(0xFFE2E8F0),
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate()
                        .fadeIn(duration: 600.ms, delay: 500.ms)
                        .slideY(begin: -0.3, end: 0),
                    ],
                  ),
                ),
              
                // Kartlar
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Kur'an-ı Kerim Oku Kartı (Sadece Arapça)
                          _buildModernFeatureCard(
                            context: context,
                            title: 'Kur\'an-ı Kerim Oku',
                            subtitle: 'Arapça Metin',
                            icon: Icons.import_contacts_rounded,
                            gradientColors: isDark
                                ? [Color(0xFF1E3A8A), Color(0xFF3B82F6)]
                                : [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                            onTap: () async {
                              // Sayfadan ayrılırken animasyonları duraklat
                              didPushNext();
                              
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArabicQuranReaderScreen(
                                    onThemeChanged: widget.onThemeChanged,
                                  ),
                                ),
                              );
                              
                              // Geri dönünce animasyonları devam ettir
                              didPopNext();
                            },
                            delay: 700,
                          ),
                          
                          SizedBox(height: 20),
                          
                          // Kur'an-ı Kerim ve Meali Kartı
                          _buildModernFeatureCard(
                            context: context,
                            title: 'Kur\'an-ı Kerim ve Meali',
                            subtitle: 'Mushaf-ı Şerif',
                            icon: Icons.menu_book_rounded,
                            gradientColors: isDark
                                ? [Color(0xFF166534), Color(0xFF22C55E)]
                                : [Color(0xFF22C55E), Color(0xFF4ADE80)],
                            onTap: () async {
                              // Sayfadan ayrılırken animasyonları duraklat
                              didPushNext();
                              
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuranReaderScreen(
                                    onThemeChanged: widget.onThemeChanged,
                                  ),
                                ),
                              );
                              
                              // Geri dönünce animasyonları devam ettir
                              didPopNext();
                            },
                            delay: 900,
                          ),
                          
                          SizedBox(height: 20),
                          
                          // Hadis-i Şerif Kartı
                          _buildModernFeatureCard(
                            context: context,
                            title: 'Hadis-i Şerif',
                            subtitle: 'Peygamberimizin Sözleri',
                            icon: Icons.auto_stories_rounded,
                            gradientColors: isDark
                                ? [Color(0xFF6B21A8), Color(0xFFA855F7)]
                                : [Color(0xFFA855F7), Color(0xFFC084FC)],
                            onTap: () {
                              print('Hadis-i Şerif tıklandı');
                            },
                            delay: 1100,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFeatureCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required int delay,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(isDark ? 0.3 : 0.4),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // İkon Container
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.15 : 0.2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.2 : 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                
                SizedBox(width: 20),
                
                // Metin
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(isDark ? 0.8 : 0.85),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Ok İşareti
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.1 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(isDark ? 0.9 : 0.95),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: delay.ms)
      .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic)
      .then()
      .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.2));
  }
}

// 🎨 Aurora Borealis Painter (Kuzey Işıkları)
class AuroraPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;
  
  AuroraPainter({required this.animationValue, required this.isDark});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Aurora dalgaları - 3 katman
    for (int layer = 0; layer < 3; layer++) {
      final path = Path();
      final layerOffset = layer * 0.3;
      final amplitude = 80.0 - (layer * 15);
      final frequency = 0.003 + (layer * 0.001);
      
      path.moveTo(0, size.height * 0.3);
      
      for (double x = 0; x <= size.width; x += 5) {
        final wave1 = math.sin((x * frequency) + (animationValue * 2 * math.pi) + layerOffset) * amplitude;
        final wave2 = math.cos((x * frequency * 1.5) - (animationValue * 2 * math.pi) + layerOffset) * (amplitude * 0.5);
        final y = (size.height * 0.3) + wave1 + wave2;
        path.lineTo(x, y);
      }
      
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
      path.close();
      
      // Gradient colors for each layer
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
      final pulseOpacity = particle.opacity * (0.7 + math.sin(animationValue * 4 * math.pi + particle.x * 10) * 0.3);
      
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
