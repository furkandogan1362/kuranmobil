// Bu dosyadan ayrılanlar (okunabilirlik için parçalandı):
// - Particle ve ParticlePainter -> lib/screens/home/particles.dart (Parçacık modeli ve çizer)
// - AuroraPainter -> lib/screens/home/aurora_painter.dart (Kuzey ışıkları arkaplan)
// - StarsPainter -> lib/screens/home/stars_painter.dart (Pulse yapan yıldızlar)
// - _buildModernFeatureCard -> lib/screens/home/feature_card.dart (Özellik kartı UI)

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'quran_reader_screen.dart';
import 'arabic_quran_reader_screen.dart';
import 'dart:math' as math;

// Parçalara ayırma: aynı kütüphanenin parçaları
part 'home/feature_card.dart';
part 'home/aurora_painter.dart';
part 'home/particles.dart';
part 'home/stars_painter.dart';

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

}
