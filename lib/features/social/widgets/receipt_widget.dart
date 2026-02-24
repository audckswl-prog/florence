import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class ReceiptWidget extends StatelessWidget {
  final Widget child;

  const ReceiptWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      // Use ClipPath for Zigzag edges if we want extreme detail, 
      // but for now, let's use a decorating container with a custom painter or just a simple look.
      // Let's implement a custom painter for Zigzag edges.
      child: CustomPaint(
        painter: ZigZagPainter(color: const Color(0xFFFDFCF0), shadowColor: Colors.black26),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          width: double.infinity,
          child: child,
        ),
      ),
    );
  }
}

class ZigZagPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  ZigZagPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final shadowPaint = Paint()..color = shadowColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    const double spikeSize = 10.0;
    final double width = size.width;
    final double height = size.height;

    Path path = Path();
    path.moveTo(0, 0);

    // Top Zigzag
    for (double x = 0; x < width; x += spikeSize * 2) {
      path.lineTo(x + spikeSize, spikeSize);
      path.lineTo(x + spikeSize * 2, 0);
    }
    
    // Right side
    path.lineTo(width, height);

    // Bottom Zigzag
    for (double x = width; x > 0; x -= spikeSize * 2) {
      path.lineTo(x - spikeSize, height - spikeSize);
      path.lineTo(x - spikeSize * 2, height);
    }

    // Left side
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, shadowPaint); // Draw shadow
    canvas.drawPath(path, paint); // Draw paper
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
