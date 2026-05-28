import 'package:flutter/material.dart';

class TapeStripPainter extends CustomPainter {
  final double progress;

  const TapeStripPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final leftX = w * 0.20;
    final rightX = w * 0.80;
    final centerY = h * 0.50;

    final paint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(leftX, centerY)
      ..cubicTo(
        leftX + w * 0.10, centerY + h * 0.18,
        rightX - w * 0.10, centerY + h * 0.18,
        rightX, centerY,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(TapeStripPainter old) => old.progress != progress;
}
