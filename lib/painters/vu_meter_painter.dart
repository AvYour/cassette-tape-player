import 'dart:math';
import 'package:flutter/material.dart';

class VuMeterPainter extends CustomPainter {
  final double level;

  const VuMeterPainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.82;
    final radius = min(w, h) * 0.68;

    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: radius * 2, height: radius * 2),
      pi,
      pi,
      false,
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    final markPaint = Paint()
      ..color = const Color(0xFF666666)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 10; i++) {
      final angle = pi + (pi * i / 10);
      final innerR = radius * 0.78;
      final outerR = radius * (i % 5 == 0 ? 0.97 : 0.88);
      canvas.drawLine(
        Offset(cx + cos(angle) * innerR, cy + sin(angle) * innerR),
        Offset(cx + cos(angle) * outerR, cy + sin(angle) * outerR),
        markPaint,
      );
    }

    final needleAngle = pi + (pi * level.clamp(0.0, 1.0));
    canvas.drawLine(
      Offset(cx, cy),
      Offset(
        cx + cos(needleAngle) * radius * 0.76,
        cy + sin(needleAngle) * radius * 0.76,
      ),
      Paint()
        ..color = const Color(0xFFD94532)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(Offset(cx, cy), 3.5, Paint()..color = const Color(0xFF888888));
  }

  @override
  bool shouldRepaint(VuMeterPainter old) => old.level != level;
}
