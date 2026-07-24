import 'package:flutter/material.dart';

/// One small VU meter: a pale glass face, tick arc with a red zone, a glare
/// and a needle pivoting from the bottom edge. Drive [deflection] with
/// `VuMotion`.
class VuMeter extends StatelessWidget {
  final double deflection;
  final double width;
  final double height;

  const VuMeter({
    super.key,
    required this.deflection,
    this.width = 46,
    this.height = 25,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _VuPainter(deflection: deflection),
    );
  }
}

class _VuPainter extends CustomPainter {
  final double deflection;

  const _VuPainter({required this.deflection});

  @override
  void paint(Canvas canvas, Size size) {
    final face =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3));
    canvas.drawRRect(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFE7E4F2)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF9A96AA).withValues(alpha: 0.5),
    );

    final pivot = Offset(size.width / 2, size.height - 2);
    const start = -2.35; // needle sweep, radians (leftmost)
    const sweep = 1.55; // to rightmost

    // Scale ticks along the arc; the last third is the red zone.
    for (var i = 0; i <= 6; i++) {
      final f = i / 6;
      final a = start + sweep * f;
      final outer = pivot + Offset.fromDirection(a, size.height - 6);
      final inner = pivot + Offset.fromDirection(a, size.height - 9.5);
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..strokeWidth = 1
          ..color = f > 0.66
              ? const Color(0xFFE0526B)
              : const Color(0xFF9A96AA),
      );
    }

    // The needle.
    final angle = start + sweep * deflection.clamp(0.0, 1.0);
    canvas.drawLine(
      pivot,
      pivot + Offset.fromDirection(angle, size.height - 5),
      Paint()
        ..strokeWidth = 1.3
        ..color = const Color(0xFFE0526B),
    );
    canvas.drawCircle(pivot, 1.8, Paint()..color = const Color(0xFF14121C));

    // Glass glare.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(2, 2, size.width - 4, size.height * 0.32),
          const Radius.circular(2)),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(_VuPainter old) => old.deflection != deflection;
}
