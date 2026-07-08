import 'package:flutter/material.dart';

/// The dark tape ribbon spanning the two reels: a taut top segment between the
/// spools plus a shallow exposed loop dipping toward the window's lower edge.
class TapeStripPainter extends CustomPainter {
  final double progress;

  const TapeStripPainter({required this.progress});

  static const Color _tapeDark = Color(0xFF22140D);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final leftX = w * 0.29;
    final rightX = w * 0.71;
    final topY = h * 0.30;

    final tape = Paint()
      ..color = _tapeDark
      ..strokeWidth = h * 0.03
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Taut top run across the spools.
    canvas.drawLine(Offset(leftX, topY), Offset(rightX, topY), tape);

    // Exposed loop dipping toward the pinch-roller line below.
    final loop = Path()
      ..moveTo(leftX, topY)
      ..cubicTo(
        leftX + w * 0.06, h * 0.92,
        rightX - w * 0.06, h * 0.92,
        rightX, topY,
      );
    canvas.drawPath(loop, tape);

    // Thin specular highlight along the top run.
    canvas.drawLine(
      Offset(leftX, topY - h * 0.012),
      Offset(rightX, topY - h * 0.012),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..strokeWidth = h * 0.006
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(TapeStripPainter old) => old.progress != progress;
}
