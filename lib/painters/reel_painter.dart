import 'dart:math';
import 'package:flutter/material.dart';

class ReelPainter extends CustomPainter {
  final double rotationAngle;
  final double radius;
  final bool isLeft;

  const ReelPainter({
    required this.rotationAngle,
    required this.radius,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = radius;

    canvas.drawCircle(center, r, Paint()..color = const Color(0xFF3A3A3A));

    final spokePaint = Paint()
      ..color = const Color(0xFF888888)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final angle = rotationAngle + (i * 2 * pi / 3);
      canvas.drawLine(
        center + Offset(cos(angle) * r * 0.30, sin(angle) * r * 0.30),
        center + Offset(cos(angle) * r * 0.86, sin(angle) * r * 0.86),
        spokePaint,
      );
    }

    canvas.drawCircle(center, r * 0.26, Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawCircle(center, r * 0.10, Paint()..color = const Color(0xFF888888));

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white.withOpacity(0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(ReelPainter old) =>
      old.rotationAngle != rotationAngle || old.radius != radius;
}
