import 'package:flutter/material.dart';

/// Hız ve Sure Listesi toggle butonları
class ControlToggleButtons extends StatelessWidget {
  final bool isDark;
  final bool isSpeedPanelExpanded;
  final bool isSurahListExpanded;
  final VoidCallback onSpeedToggle;
  final VoidCallback onSurahListToggle;

  const ControlToggleButtons({
    super.key,
    required this.isDark,
    required this.isSpeedPanelExpanded,
    required this.isSurahListExpanded,
    required this.onSpeedToggle,
    required this.onSurahListToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hız butonu
        _buildToggleButton(
          icon: Icons.speed_rounded,
          label: 'Hız',
          isExpanded: isSpeedPanelExpanded,
          onTap: onSpeedToggle,
        ),
        
        const SizedBox(width: 12),
        
        // Sure Listesi butonu
        _buildToggleButton(
          icon: Icons.list_rounded,
          label: 'Sureler',
          isExpanded: isSurahListExpanded,
          onTap: onSurahListToggle,
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isExpanded
                ? (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isDark ? Colors.white60 : Colors.black54,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
