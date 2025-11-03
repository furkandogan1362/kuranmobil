import 'package:flutter/material.dart';
import '../../services/audio_service.dart';

/// Oynatma hızı ayarlama paneli
class SpeedPanel extends StatelessWidget {
  final AudioService audioService;
  final bool isDark;
  final double playbackSpeed;

  const SpeedPanel({
    super.key,
    required this.audioService,
    required this.isDark,
    required this.playbackSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hız',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${playbackSpeed}x',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Color(0xFF10B981),
              inactiveTrackColor: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1),
              thumbColor: Color(0xFF10B981),
              overlayColor: Color(0xFF10B981).withOpacity(0.2),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 3,
            ),
            child: Slider(
              value: playbackSpeed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              onChanged: (value) => audioService.setPlaybackSpeed(value),
            ),
          ),
          Wrap(
            spacing: 6,
            alignment: WrapAlignment.center,
            children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                .map((speed) => _buildSpeedChip(speed))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedChip(double speed) {
    final isSelected = audioService.playbackSpeed == speed;
    return GestureDetector(
      onTap: () => audioService.setPlaybackSpeed(speed),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
              : null,
          color: isSelected
              ? null
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '${speed}x',
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }
}
