import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The felt lining of the drawer, seen from above: fibrous nap, an overhead
/// light pooling near the top, and corners falling away into shadow — painted
/// with the same care as the cassette shells. Deterministic per [seed].
class FeltPainter extends CustomPainter {
  final int seed;

  const FeltPainter({this.seed = 21});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base felt tone.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1C12), Color(0xFF382515)],
        ).createShader(rect),
    );

    // Fibrous nap: hundreds of tiny strokes at random angles. Painted once
    // (static layer), so the count is fine.
    final rnd = math.Random(seed);
    final fiber = Paint()..strokeCap = StrokeCap.round;
    final count = (size.width * size.height / 900).clamp(120, 700).toInt();
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final len = 1.5 + rnd.nextDouble() * 3.5;
      final angle = rnd.nextDouble() * math.pi;
      final bright = rnd.nextDouble() < 0.4;
      fiber
        ..strokeWidth = 0.7 + rnd.nextDouble() * 0.5
        ..color = (bright ? const Color(0xFF5A4028) : Colors.black)
            .withValues(alpha: 0.05 + rnd.nextDouble() * 0.06);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(angle) * len, y + math.sin(angle) * len),
        fiber,
      );
    }

    // Overhead light pooling toward the top of the drawer.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.9),
          radius: 1.1,
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // Corners sink into shadow.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.25,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.22),
          ],
          stops: const [0.6, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(FeltPainter old) => old.seed != seed;
}
