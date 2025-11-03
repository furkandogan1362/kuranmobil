part of 'package:kuranmobil/screens/home_screen.dart';

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
