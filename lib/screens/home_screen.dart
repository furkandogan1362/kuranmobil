import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'quran_reader_screen.dart';
import 'arabic_quran_reader_screen.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  final Function(String themeMode)? onThemeChanged;
  
  const HomeScreen({super.key, this.onThemeChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Animasyonlu Gradient Arka Plan
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(
                      math.cos(_animationController.value * 2 * math.pi) * 0.5,
                      math.sin(_animationController.value * 2 * math.pi) * 0.5,
                    ),
                    end: Alignment(
                      -math.cos(_animationController.value * 2 * math.pi) * 0.5,
                      -math.sin(_animationController.value * 2 * math.pi) * 0.5,
                    ),
                    colors: isDark
                        ? [
                            Color(0xFF0F172A), // Slate 900
                            Color(0xFF1E293B), // Slate 800
                            Color(0xFF334155), // Slate 700
                            Color(0xFF1E293B), // Slate 800
                          ]
                        : [
                            Color(0xFF0F172A), // Koyu slate
                            Color(0xFF1E40AF), // Blue 700
                            Color(0xFF7C3AED), // Violet 600
                            Color(0xFF1E40AF), // Blue 700
                          ],
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              );
            },
          ),
          
          // Blur Efekti için Dekoratif Şekiller
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    math.cos(_animationController.value * 2 * math.pi) * 30,
                    math.sin(_animationController.value * 2 * math.pi) * 30,
                  ),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [
                                Color(0xFF6366F1).withOpacity(0.15),
                                Color(0xFF6366F1).withOpacity(0.0),
                              ]
                            : [
                                Color(0xFF8B5CF6).withOpacity(0.3),
                                Color(0xFF8B5CF6).withOpacity(0.0),
                              ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            bottom: -150,
            left: -150,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    -math.cos(_animationController.value * 2 * math.pi) * 40,
                    -math.sin(_animationController.value * 2 * math.pi) * 40,
                  ),
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isDark
                            ? [
                                Color(0xFF3B82F6).withOpacity(0.12),
                                Color(0xFF3B82F6).withOpacity(0.0),
                              ]
                            : [
                                Color(0xFF3B82F6).withOpacity(0.25),
                                Color(0xFF3B82F6).withOpacity(0.0),
                              ],
                      ),
                    ),
                  ),
                );
              },
            ),
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArabicQuranReaderScreen(
                                    onThemeChanged: widget.onThemeChanged,
                                  ),
                                ),
                              );
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuranReaderScreen(
                                    onThemeChanged: widget.onThemeChanged,
                                  ),
                                ),
                              );
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
