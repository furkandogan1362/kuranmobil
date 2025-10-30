import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final Function(String themeMode)? onThemeChanged;
  
  const SplashScreen({super.key, this.onThemeChanged});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _logoController;
  
  @override
  void initState() {
    super.initState();
    
    // Gradient animasyon controller - 8 saniyelik smooth döngü
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    
    // Logo animasyon controller - 1.5 saniye elastik animasyon
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Logo animasyonunu başlat
    _logoController.forward();
    
    // 3 saniye sonra ana sayfaya geçiş
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
              HomeScreen(onThemeChanged: widget.onThemeChanged),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }
  
  @override
  void dispose() {
    _gradientController.dispose();
    _logoController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animasyonlu Gradient Arka Plan (Logonun yeşil tonlarına uygun)
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.cos(_gradientController.value * 2 * math.pi) * 0.5,
                      math.sin(_gradientController.value * 2 * math.pi) * 0.5,
                    ),
                    end: Alignment(
                      -math.cos(_gradientController.value * 2 * math.pi) * 0.5,
                      -math.sin(_gradientController.value * 2 * math.pi) * 0.5,
                    ),
                    colors: isDark
                        ? [
                            Color(0xFF0A3D2C), // Koyu yeşil (logo kubbesi)
                            Color(0xFF0D5940), // Orta ton yeşil
                            Color(0xFF0A4D35), // Yeşil varyant
                            Color(0xFF0A3D2C), // Tekrar koyu yeşil
                          ]
                        : [
                            Color(0xFF0A3D2C), // Koyu yeşil
                            Color(0xFF166534), // Logo yeşili
                            Color(0xFF15803D), // Parlak yeşil
                            Color(0xFF166534), // Logo yeşili
                          ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              );
            },
          ),
          
          // Dekoratif Hareketli Şekiller (Kubbe ve hilal teması)
          Positioned(
            top: -120,
            right: -120,
            child: AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    math.cos(_gradientController.value * 2 * math.pi) * 25,
                    math.sin(_gradientController.value * 2 * math.pi) * 25,
                  ),
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF22C55E).withOpacity(isDark ? 0.12 : 0.2),
                          Color(0xFF22C55E).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            bottom: -160,
            left: -160,
            child: AnimatedBuilder(
              animation: _gradientController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    -math.cos(_gradientController.value * 2 * math.pi) * 35,
                    -math.sin(_gradientController.value * 2 * math.pi) * 35,
                  ),
                  child: Container(
                    width: 450,
                    height: 450,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF15803D).withOpacity(isDark ? 0.1 : 0.18),
                          Color(0xFF15803D).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Logo Container - Yüksek Kalite, Responsive
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                final scaleValue = Curves.elasticOut.transform(_logoController.value);
                final opacityValue = Curves.easeIn.transform(_logoController.value);
                
                return Transform.scale(
                  scale: 0.3 + (scaleValue * 0.7), // 0.3'ten 1.0'a elastik büyüme
                  child: Opacity(
                    opacity: opacityValue,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.65, // Ekranın %65'i
                      height: MediaQuery.of(context).size.width * 0.65,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.08),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF22C55E).withOpacity(0.3),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                        padding: EdgeInsets.all(30),
                        child: Image.asset(
                          'assets/images/islam_rehberi_logo.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high, // Yüksek kalite render
                          isAntiAlias: true, // Kenar yumuşatma aktif
                        ),
                      ),
                    ),
                  ),
                );
              },
            ).animate(
              onComplete: (controller) => controller.repeat(reverse: true),
            ).shimmer(
              duration: 2500.ms,
              delay: 1500.ms,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          
          // Alt kısımda "İslam Rehberi" metni
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // "İslam Rehberi" metni (1200ms'de görünür)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withOpacity(0.25),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF22C55E).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    'İslam Rehberi',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                      shadows: [
                        // Yeşil glow efekti (logoya uyumlu)
                        Shadow(
                          color: Color(0xFF22C55E).withOpacity(0.8),
                          offset: Offset(0, 0),
                          blurRadius: 20,
                        ),
                        Shadow(
                          color: Color(0xFF22C55E).withOpacity(0.6),
                          offset: Offset(0, 0),
                          blurRadius: 12,
                        ),
                        // Depth gölgesi (3 katmanlı)
                        Shadow(
                          color: Colors.black.withOpacity(0.9),
                          offset: Offset(0, 3),
                          blurRadius: 6,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.7),
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ).animate()
                  .fadeIn(duration: 800.ms, delay: 1200.ms)
                  .slideY(begin: 0.3, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
