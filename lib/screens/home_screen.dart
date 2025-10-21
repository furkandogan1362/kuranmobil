import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quran_reader_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a237e), // Koyu mavi
              Color(0xFF0d47a1), // Orta mavi
              Color(0xFF01579b), // Açık mavi
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Başlık
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Text(
                      'Hoş Geldiniz',
                      style: GoogleFonts.notoNaskhArabic(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.3, end: 0),
                    SizedBox(height: 8),
                    Text(
                      'İslami Kaynaklarınız',
                      style: GoogleFonts.notoSans(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ).animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: -0.3, end: 0),
                  ],
                ),
              ),
              
              // Kartlar
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Kur'an-ı Kerim Kartı
                        _buildFeatureCard(
                          context: context,
                          title: 'Kur\'an-ı Kerim',
                          subtitle: 'Mushaf-ı Şerif',
                          icon: Icons.book,
                          gradientColors: [
                            Color(0xFF2E7D32),
                            Color(0xFF388E3C),
                            Color(0xFF43A047),
                          ],
                          onTap: () {
                            // Kur'an sayfasına git
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QuranReaderScreen(),
                              ),
                            );
                          },
                          delay: 400,
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Hadis-i Şerif Kartı
                        _buildFeatureCard(
                          context: context,
                          title: 'Hadis-i Şerif',
                          subtitle: 'Peygamberimizin Sözleri',
                          icon: Icons.menu_book,
                          gradientColors: [
                            Color(0xFF6A1B9A),
                            Color(0xFF7B1FA2),
                            Color(0xFF8E24AA),
                          ],
                          onTap: () {
                            // Hadis sayfasına git
                            print('Hadis-i Şerif tıklandı');
                          },
                          delay: 600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required int delay,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[1].withOpacity(0.5),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // İkon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      icon,
                      size: 48,
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
                          style: GoogleFonts.notoNaskhArabic(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Ok işareti
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, delay: delay.ms)
      .slideX(begin: 0.3, end: 0)
      .shimmer(duration: 1500.ms, delay: delay.ms);
  }
}
