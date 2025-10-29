import 'package:flutter/material.dart';

class VerseSeparator extends StatelessWidget {
  const VerseSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              child: CustomPaint(
                painter: _VerseSeparatorPainter(
                  isDark: isDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerseSeparatorPainter extends CustomPainter {
  final bool isDark;
  
  _VerseSeparatorPainter({required this.isDark});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDark 
          ? Color(0xFFB8976A).withOpacity(0.7) 
          : Color(0xFFB8976A);
    
    final centerY = size.height / 2;
    final centerX = size.width / 2;
    
    // Merkez daire (büyük)
    canvas.drawCircle(
      Offset(centerX, centerY),
      8,
      paint,
    );
    
    // Sol ve sağ daireler (orta)
    final mediumOffset = 24.0;
    canvas.drawCircle(
      Offset(centerX - mediumOffset, centerY),
      6,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX + mediumOffset, centerY),
      6,
      paint,
    );
    
    // Daha uzak daireler (küçük)
    final smallOffset = 44.0;
    canvas.drawCircle(
      Offset(centerX - smallOffset, centerY),
      4,
      paint,
    );
    canvas.drawCircle(
      Offset(centerX + smallOffset, centerY),
      4,
      paint,
    );
    
    // Çizgiler (ortadan kenarlara)
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = isDark 
          ? Color(0xFFB8976A).withOpacity(0.5) 
          : Color(0xFFB8976A).withOpacity(0.6);
    
    // Sol çizgi
    canvas.drawLine(
      Offset(4, centerY),
      Offset(centerX - smallOffset - 8, centerY),
      linePaint,
    );
    
    // Sağ çizgi
    canvas.drawLine(
      Offset(centerX + smallOffset + 8, centerY),
      Offset(size.width - 4, centerY),
      linePaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
