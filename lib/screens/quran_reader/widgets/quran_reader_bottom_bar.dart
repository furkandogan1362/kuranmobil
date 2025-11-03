import 'package:flutter/material.dart';

/// Alt navigasyon çubuğu
class QuranReaderBottomBar extends StatelessWidget {
  final VoidCallback onAudioPlayerTap;
  final VoidCallback onSettingsTap;

  const QuranReaderBottomBar({
    super.key,
    required this.onAudioPlayerTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [Color(0xFF302F30), Color(0xFF302F30)]
              : [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.12),
            blurRadius: 16,
            offset: Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildNavBarItem(
                  context,
                  icon: Icons.volume_up_rounded,
                  label: 'Sesli Meal',
                  onTap: onAudioPlayerTap,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildNavBarItem(
                  context,
                  icon: Icons.settings_rounded,
                  label: 'Ayarlar',
                  onTap: onSettingsTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Color(0xFF2E7D32).withOpacity(0.8),
                    Color(0xFF43A047).withOpacity(0.8),
                  ]
                : [
                    Color(0xFF2E7D32),
                    Color(0xFF43A047),
                  ],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF2E7D32).withOpacity(isDark ? 0.15 : 0.35),
              blurRadius: 10,
              offset: Offset(0, 3),
              spreadRadius: 0,
            ),
            if (!isDark)
              BoxShadow(
                color: Colors.white.withOpacity(0.4),
                blurRadius: 6,
                offset: Offset(0, -1),
                spreadRadius: 0,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
